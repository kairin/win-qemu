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

STATE_DIR="${PROJECT_ROOT}/.installation-state"
LOG_DIR="${LOG_DIR:-/var/log/win-qemu}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

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

# Initialize logging
# Usage: init_logging "Script Name"
init_logging() {
    local script_name="$1"

    # Determine log directory based on permissions with robust fallback
    if [[ -w "/var/log" ]]; then
        # Try to create system log directory
        if mkdir -p "$LOG_DIR" 2>/dev/null; then
            LOG_FILE="${LOG_DIR}/${script_name%.*}-${TIMESTAMP}.log"
        else
            # Fallback if mkdir fails (e.g., parent directory permissions)
            mkdir -p "$STATE_DIR"
            LOG_FILE="${STATE_DIR}/${script_name%.*}-${TIMESTAMP}.log"
        fi
    else
        # Not running as root, use local directory
        mkdir -p "$STATE_DIR"
        LOG_FILE="${STATE_DIR}/${script_name%.*}-${TIMESTAMP}.log"
    fi

    # Create log file with error handling
    if ! touch "$LOG_FILE" 2>/dev/null; then
        # Ultimate fallback: /tmp
        LOG_FILE="/tmp/${script_name%.*}-${TIMESTAMP}.log"
        touch "$LOG_FILE"
    fi

    # Header
    {
        echo "# QEMU/KVM Script Log: $script_name"
        echo "# Started: $(date +'%Y-%m-%d %H:%M:%S %Z')"
        echo "# Hostname: $(hostname)"
        echo "# User: ${SUDO_USER:-$USER}"
        echo "# Script: $0"
        echo "# Log File: $LOG_FILE"
        echo ""
    } >> "$LOG_FILE"
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

# Run command and log output
# Usage: run_logged "Description" command args...
run_logged() {
    local description="$1"
    shift
    local cmd="$*"
    
    log_step "$description"
    log CMD "$cmd"
    
    if output=$("$@" 2>&1); then
        if [[ -n "${LOG_FILE:-}" ]]; then
            echo "$output" >> "$LOG_FILE"
        fi
        return 0
    else
        local exit_code=$?
        if [[ -n "${LOG_FILE:-}" ]]; then
            echo "$output" >> "$LOG_FILE"
        fi
        log_error "Command failed with exit code $exit_code"
        return $exit_code
    fi
}

# ==============================================================================
# COMMON CHECKS
# ==============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        log_error "Usage: sudo $0 $@"
        exit 1
    fi
}

check_libvirtd() {
    log_step "Checking libvirtd service..."
    if ! systemctl is-active --quiet libvirtd; then
        log_error "libvirtd service is not running"
        log_error "Start with: sudo systemctl start libvirtd"
        return 1
    fi
    log_success "libvirtd service is active"
}

check_vm_exists() {
    local vm_name="$1"
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
    
    read -p "$message $prompt_text: " response
    response="${response:-$default}"
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}
