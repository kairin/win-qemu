#!/bin/bash
#
# common.sh - Shared library for QEMU/KVM scripts
#
# Purpose: Centralize logging, colors, and common checks to reduce duplication.
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#        OR if in scripts dir: source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
#

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Determine project root (assuming script is in scripts/ or scripts/subdir)
# We traverse up until we find the 'scripts' directory or hit root
current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$current_dir/../../scripts" ]]; then
    PROJECT_ROOT="$(cd "$current_dir/../.." && pwd)"
elif [[ -d "$current_dir/../scripts" ]]; then
    PROJECT_ROOT="$(cd "$current_dir/.." && pwd)"
else
    PROJECT_ROOT="$(cd "$current_dir" && pwd)" # Fallback
fi

# Centralized logging directory (all logs go here)
LOG_DIR="${PROJECT_ROOT}/logs"
STATE_DIR="${LOG_DIR}/installation-state"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Ensure directories exist
mkdir -p "$LOG_DIR" "$STATE_DIR" 2>/dev/null || true

# ==============================================================================
# COLORS
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ==============================================================================
# LOGGING
# ==============================================================================

# Initialize logging with verbose tracing
# Usage: init_logging "Script Name"
init_logging() {
    local script_name="$1"

    # Ensure log directory exists
    mkdir -p "$LOG_DIR" "$STATE_DIR" 2>/dev/null || true

    # Set log file path (always use centralized location)
    LOG_FILE="${LOG_DIR}/${script_name%.*}-${TIMESTAMP}.log"

    # Create log file with error handling
    if ! touch "$LOG_FILE" 2>/dev/null; then
        # Fallback to /tmp only if project directory is not writable
        LOG_FILE="/tmp/${script_name%.*}-${TIMESTAMP}.log"
        touch "$LOG_FILE"
        echo "WARNING: Using fallback log location: $LOG_FILE" >&2
    fi

    # Header with environment information
    {
        echo "# ========================================================================"
        echo "# QEMU/KVM Script Log: $script_name"
        echo "# ========================================================================"
        echo "# Started: $(date +'%Y-%m-%d %H:%M:%S %Z')"
        echo "# Hostname: $(hostname)"
        echo "# User: ${SUDO_USER:-$USER} (UID: $(id -u "${SUDO_USER:-$USER}"))"
        echo "# Script: $0"
        echo "# Log File: $LOG_FILE"
        echo "# PID: $$"
        echo "#"
        echo "# Environment Variables:"
        echo "#   HOME: ${HOME:-<not set>}"
        echo "#   USER: ${USER:-<not set>}"
        echo "#   SUDO_USER: ${SUDO_USER:-<not set>}"
        echo "#   PWD: ${PWD:-<not set>}"
        echo "#   PATH: ${PATH:-<not set>}"
        echo "#   PROJECT_ROOT: ${PROJECT_ROOT:-<not set>}"
        echo "#   LOG_DIR: ${LOG_DIR:-<not set>}"
        echo "#   STATE_DIR: ${STATE_DIR:-<not set>}"
        echo "# ========================================================================"
        echo ""
    } >> "$LOG_FILE"

    # Enable verbose tracing with timestamps
    # PS4 shows: timestamp + filename:line + function
    export PS4='+ $(date "+%Y-%m-%d %H:%M:%S") ${BASH_SOURCE##*/}:${LINENO} ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

    # Redirect trace output to log file AND stderr
    exec 2> >(tee -a "$LOG_FILE" >&2)

    # Enable command tracing
    set -x

    log_info "Verbose tracing enabled (set -x active)"
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # Log to file
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi

    # Log to console with colors
    case "$level" in
        INFO)    echo -e "${BLUE}[INFO]${NC} ${message}" ;;
        SUCCESS) echo -e "${GREEN}[✓]${NC} ${message}" ;;
        WARN)    echo -e "${YELLOW}[!]${NC} ${message}" ;;
        ERROR)   echo -e "${RED}[✗]${NC} ${message}" >&2 ;;
        STEP)    echo -e "${CYAN}[STEP]${NC} ${message}" ;;
        CMD)     echo -e "${BOLD}[CMD]${NC} ${message}" ;;
        *)       echo "[${level}] ${message}" ;;
    esac
}

log_info() { log INFO "$@"; }
log_success() { log SUCCESS "$@"; }
log_warning() { log WARN "$@"; }
log_error() { log ERROR "$@"; }
log_step() { log STEP "$@"; }
log_cmd() { log CMD "$@"; }

# Run command and log output with timing
# Usage: run_logged "Description" command args...
run_logged() {
    local description="$1"
    shift
    local cmd="$*"

    log_step "$description"
    log CMD "$cmd"

    # Record start time
    local start_time=$(date +%s.%N)

    if output=$("$@" 2>&1); then
        local exit_code=0
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")

        if [[ -n "${LOG_FILE:-}" ]]; then
            {
                echo "# Command output:"
                echo "$output"
                echo "# Exit code: $exit_code"
                echo "# Duration: ${duration}s"
                echo ""
            } >> "$LOG_FILE"
        fi

        log_success "$description completed in ${duration}s"
        return 0
    else
        local exit_code=$?
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")

        if [[ -n "${LOG_FILE:-}" ]]; then
            {
                echo "# Command output:"
                echo "$output"
                echo "# Exit code: $exit_code (FAILED)"
                echo "# Duration: ${duration}s"
                echo ""
            } >> "$LOG_FILE"
        fi

        log_error "Command failed with exit code $exit_code (duration: ${duration}s)"
        return $exit_code
    fi
}

# ==============================================================================
# COMMON CHECKS
# ==============================================================================

check_root() {
    # In dry-run mode, skip sudo requirement to allow preview without privileges
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping root check (would require sudo in actual run)"
        return 0
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        log_error "Usage: sudo $0 $*"
        exit 1
    fi
}

check_libvirtd() {
    log_step "Checking libvirtd service..."

    # In dry-run mode, skip service check to allow preview without libvirt installed
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping libvirtd check (service would be required in actual run)"
        return 0
    fi

    if ! systemctl is-active --quiet libvirtd; then
        log_error "libvirtd service is not running"
        log_error "Start with: sudo systemctl start libvirtd"
        return 1
    fi
    log_success "libvirtd service is active"
}

check_vm_exists() {
    local vm_name="$1"

    # In dry-run mode, skip VM check since virsh may not be installed
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warning "[DRY RUN] Skipping VM existence check for '$vm_name' (virsh would be required)"
        return 0  # Assume VM exists for dry-run preview
    fi

    if virsh dominfo "$vm_name" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# UTILS
# ==============================================================================

prompt_confirm() {
    local message="$1"
    local default="${2:-n}" # y or n

    local prompt_text
    if [[ "$default" == "y" ]]; then
        prompt_text="(Y/n)"
    else
        prompt_text="(y/N)"
    fi

    read -r -p "$message $prompt_text: " response
    response="${response:-$default}"

    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}
