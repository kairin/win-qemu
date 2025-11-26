#!/bin/bash
#
# analyze-installation-logs.sh - Installation Log Analysis Tool
#
# Purpose: Parse and analyze installation logs for errors, warnings, and failures
# Usage: ./scripts/analyze-installation-logs.sh [log-file]
#
# If no log file specified, analyzes the most recent installation log
#
# Output:
#   - Summary report with errors, warnings, successes
#   - Failure point identification with context
#   - Recommendations for remediation
#
# Author: AI-assisted (Claude Code)
# Created: 2025-11-21
# Version: 1.0
#

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"

# ==============================================================================
# COLORS
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ==============================================================================
# FUNCTIONS
# ==============================================================================

find_latest_log() {
    if [[ ! -d "$LOG_DIR" ]]; then
        echo "ERROR: Log directory not found: $LOG_DIR" >&2
        exit 1
    fi

    # Find most recent installation log
    local latest_log=$(find "$LOG_DIR" -name "install-*.log" -o -name "master-installation-*.log" | sort -r | head -n1)

    if [[ -z "$latest_log" ]]; then
        echo "ERROR: No installation logs found in $LOG_DIR" >&2
        exit 1
    fi

    echo "$latest_log"
}

analyze_log() {
    local log_file="$1"

    if [[ ! -f "$log_file" ]]; then
        echo -e "${RED}ERROR: Log file not found: $log_file${NC}" >&2
        exit 1
    fi

    echo "======================================================================"
    echo -e "${BOLD}${CYAN}Installation Log Analysis${NC}"
    echo "======================================================================"
    echo ""
    echo "Log file: $log_file"
    echo "Log size: $(du -h "$log_file" | cut -f1)"
    echo "Lines: $(wc -l < "$log_file")"
    echo ""

    # Extract summary statistics
    local total_lines=$(wc -l < "$log_file")
    local error_count=$(grep -c "\[ERROR\]\|\[✗\]" "$log_file" 2>/dev/null || echo "0")
    local warning_count=$(grep -c "\[WARN\]\|\[!\]" "$log_file" 2>/dev/null || echo "0")
    local success_count=$(grep -c "\[SUCCESS\]\|\[✓\]" "$log_file" 2>/dev/null || echo "0")
    local step_count=$(grep -c "\[STEP\]" "$log_file" 2>/dev/null || echo "0")

    echo "======================================================================"
    echo -e "${BOLD}Summary Statistics${NC}"
    echo "======================================================================"
    echo ""
    printf "%-20s: %s\n" "Total lines" "$total_lines"
    printf "%-20s: ${GREEN}%s${NC}\n" "Successes" "$success_count"
    printf "%-20s: ${YELLOW}%s${NC}\n" "Warnings" "$warning_count"
    printf "%-20s: ${RED}%s${NC}\n" "Errors" "$error_count"
    printf "%-20s: %s\n" "Steps executed" "$step_count"
    echo ""

    # Overall status
    if [[ $error_count -gt 0 ]]; then
        echo -e "Overall Status: ${RED}✗ FAILED${NC} ($error_count errors)"
    elif [[ $warning_count -gt 0 ]]; then
        echo -e "Overall Status: ${YELLOW}⚠ COMPLETED WITH WARNINGS${NC} ($warning_count warnings)"
    else
        echo -e "Overall Status: ${GREEN}✓ SUCCESS${NC}"
    fi
    echo ""

    # Show errors if any
    if [[ $error_count -gt 0 ]]; then
        echo "======================================================================"
        echo -e "${BOLD}${RED}Errors Found${NC}"
        echo "======================================================================"
        echo ""
        grep -n "\[ERROR\]\|\[✗\]" "$log_file" | head -20
        echo ""
        if [[ $error_count -gt 20 ]]; then
            echo "... and $((error_count - 20)) more errors (showing first 20)"
            echo ""
        fi
    fi

    # Show warnings if any
    if [[ $warning_count -gt 0 ]]; then
        echo "======================================================================"
        echo -e "${BOLD}${YELLOW}Warnings Found${NC}"
        echo "======================================================================"
        echo ""
        grep -n "\[WARN\]\|\[!\]" "$log_file" | head -10
        echo ""
        if [[ $warning_count -gt 10 ]]; then
            echo "... and $((warning_count - 10)) more warnings (showing first 10)"
            echo ""
        fi
    fi

    # Extract failed commands
    echo "======================================================================"
    echo -e "${BOLD}Failed Commands${NC}"
    echo "======================================================================"
    echo ""

    local failed_cmds=$(grep -A5 "Exit code:.*FAILED" "$log_file" 2>/dev/null || true)
    if [[ -n "$failed_cmds" ]]; then
        echo "$failed_cmds"
        echo ""
    else
        echo "No failed commands detected"
        echo ""
    fi

    # Show execution timeline (first 10 steps)
    echo "======================================================================"
    echo -e "${BOLD}Execution Timeline${NC}"
    echo "======================================================================"
    echo ""
    grep "\[STEP\]" "$log_file" | head -10
    echo ""

    # Recommendations
    echo "======================================================================"
    echo -e "${BOLD}Recommendations${NC}"
    echo "======================================================================"
    echo ""

    if [[ $error_count -gt 0 ]]; then
        echo -e "${YELLOW}→${NC} Review errors above and address root causes"
        echo -e "${YELLOW}→${NC} Check prerequisites: sudo scripts/verify-all.sh"
        echo -e "${YELLOW}→${NC} Retry installation after fixing issues"
        echo ""

        # Specific recommendations based on error patterns
        if grep -q "apt update.*failed\|package cache.*failed" "$log_file" 2>/dev/null; then
            echo -e "${RED}Issue:${NC} Package cache update failed"
            echo -e "${GREEN}Solution:${NC} Check internet connection and apt sources"
            echo "  sudo apt update"
            echo "  sudo apt install -f"
            echo ""
        fi

        if grep -q "Permission denied\|not permitted" "$log_file" 2>/dev/null; then
            echo -e "${RED}Issue:${NC} Permission errors detected"
            echo -e "${GREEN}Solution:${NC} Ensure running with sudo"
            echo "  sudo ./scripts/install-master.sh"
            echo ""
        fi

        if grep -q "libvirtd.*failed\|virsh.*not found" "$log_file" 2>/dev/null; then
            echo -e "${RED}Issue:${NC} libvirt/QEMU issues detected"
            echo -e "${GREEN}Solution:${NC} Reinstall QEMU/KVM packages"
            echo "  sudo apt install --reinstall qemu-kvm libvirt-daemon-system"
            echo "  sudo systemctl restart libvirtd"
            echo ""
        fi
    else
        echo -e "${GREEN}✓${NC} No errors detected - installation appears successful"
        echo -e "${GREEN}→${NC} Next step: Reboot system"
        echo "  sudo reboot"
        echo ""
        echo -e "${GREEN}→${NC} After reboot, verify installation"
        echo "  ./scripts/03-verify-installation.sh"
        echo ""
    fi

    echo "======================================================================"
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    local log_file="${1:-}"

    if [[ -z "$log_file" ]]; then
        echo "No log file specified, finding latest installation log..."
        log_file=$(find_latest_log)
        echo "Analyzing: $log_file"
        echo ""
    fi

    analyze_log "$log_file"
}

main "$@"
