#!/bin/bash
#
# interactive-results.sh - Interactive Result Handling Library
#
# Purpose: Provide graceful result handling with interactive menus after checks
#          instead of hard exits. Maintains backward compatibility with CI/CD
#          automation by detecting interactive vs non-interactive mode.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/interactive-results.sh"
#
# Features:
#   - Mode detection (interactive terminal vs CI/CD pipeline)
#   - Result categorization (PASS, WARNING, ERROR, CRITICAL)
#   - Interactive menu after checks complete
#   - Retry, continue, and back functionality
#   - Non-breaking backward compatibility
#
# Created: 2025-11-27
# Version: 1.0
#

# ==============================================================================
# RESULT CATEGORIES
# ==============================================================================

# Result severity levels (in order of severity)
readonly RESULT_PASS="pass"
readonly RESULT_WARNING="warning"
readonly RESULT_ERROR="error"
readonly RESULT_CRITICAL="critical"

# Exit codes (for CI/CD compatibility)
readonly EXIT_SUCCESS=0
readonly EXIT_WARNING=0      # Warnings don't fail CI/CD
readonly EXIT_ERROR=1
readonly EXIT_CRITICAL=2

# ==============================================================================
# MODE DETECTION
# ==============================================================================

# Check if running in interactive mode (terminal attached)
# Returns: 0 if interactive, 1 if non-interactive (CI/CD, piped, etc.)
is_interactive_mode() {
    # Check if stdin and stdout are terminals
    [[ -t 0 && -t 1 ]]
}

# Check if gum is available for TUI
has_gum() {
    command -v gum &> /dev/null
}

# Get the current mode as a string
get_execution_mode() {
    if is_interactive_mode; then
        echo "interactive"
    else
        echo "automation"
    fi
}

# ==============================================================================
# RESULT CLASSIFICATION
# ==============================================================================

# Determine overall status from check counts
# Args: $1=passed $2=warnings $3=errors $4=critical
# Returns: One of RESULT_* constants
classify_results() {
    local passed="${1:-0}"
    local warnings="${2:-0}"
    local errors="${3:-0}"
    local critical="${4:-0}"

    if [[ "$critical" -gt 0 ]]; then
        echo "$RESULT_CRITICAL"
    elif [[ "$errors" -gt 0 ]]; then
        echo "$RESULT_ERROR"
    elif [[ "$warnings" -gt 0 ]]; then
        echo "$RESULT_WARNING"
    else
        echo "$RESULT_PASS"
    fi
}

# Get exit code for a result status
# Args: $1=status (pass/warning/error/critical)
get_exit_code() {
    local status="$1"

    case "$status" in
        "$RESULT_PASS")     echo "$EXIT_SUCCESS" ;;
        "$RESULT_WARNING")  echo "$EXIT_WARNING" ;;
        "$RESULT_ERROR")    echo "$EXIT_ERROR" ;;
        "$RESULT_CRITICAL") echo "$EXIT_CRITICAL" ;;
        *)                  echo "$EXIT_ERROR" ;;
    esac
}

# Get emoji for status
get_status_emoji() {
    local status="$1"

    case "$status" in
        "$RESULT_PASS")     echo "✅" ;;
        "$RESULT_WARNING")  echo "⚠️" ;;
        "$RESULT_ERROR")    echo "❌" ;;
        "$RESULT_CRITICAL") echo "🚨" ;;
        *)                  echo "❓" ;;
    esac
}

# Get color code for status (gum foreground)
get_status_color() {
    local status="$1"

    case "$status" in
        "$RESULT_PASS")     echo "46" ;;   # Green
        "$RESULT_WARNING")  echo "226" ;;  # Yellow
        "$RESULT_ERROR")    echo "196" ;;  # Red
        "$RESULT_CRITICAL") echo "196" ;;  # Red (bold handled separately)
        *)                  echo "240" ;;  # Gray
    esac
}

# Get human-readable status label
get_status_label() {
    local status="$1"

    case "$status" in
        "$RESULT_PASS")     echo "ALL CHECKS PASSED" ;;
        "$RESULT_WARNING")  echo "PASSED WITH WARNINGS" ;;
        "$RESULT_ERROR")    echo "ERRORS DETECTED" ;;
        "$RESULT_CRITICAL") echo "CRITICAL ISSUES" ;;
        *)                  echo "UNKNOWN STATUS" ;;
    esac
}

# ==============================================================================
# INTERACTIVE MENU FUNCTIONS
# ==============================================================================

# Show interactive result menu after checks complete
# Args: $1=status $2=passed_count $3=warning_count $4=error_count $5=critical_count
# Optional: $6=parent_menu_name (default: "Main Menu")
# Returns: 0=continue, 1=retry, 2=back_to_menu, 3=exit
show_result_menu() {
    local status="$1"
    local passed="${2:-0}"
    local warnings="${3:-0}"
    local errors="${4:-0}"
    local critical="${5:-0}"
    local parent_menu="${6:-Main Menu}"

    # In non-interactive mode, just return appropriate code
    if ! is_interactive_mode; then
        local exit_code
        exit_code=$(get_exit_code "$status")
        return "$exit_code"
    fi

    # Build menu options based on status
    local options=()

    # All statuses can view details
    options+=("📋 View Detailed Report")

    # Only non-critical can continue
    if [[ "$status" != "$RESULT_CRITICAL" ]]; then
        options+=("▶️  Continue Anyway")
    fi

    # Show fix instructions if there are issues
    if [[ "$status" != "$RESULT_PASS" ]]; then
        options+=("🔧 Show Fix Instructions")
    fi

    # Always allow retry and navigation
    options+=("🔄 Retry Checks")
    options+=("← Back to ${parent_menu}")
    options+=("🚪 Exit")

    echo ""

    local emoji
    emoji=$(get_status_emoji "$status")
    local color
    color=$(get_status_color "$status")
    local label
    label=$(get_status_label "$status")

    if has_gum; then
        gum style \
            --border rounded \
            --border-foreground "$color" \
            --padding "1 2" \
            --margin "1 0" \
            "$emoji $label" \
            "" \
            "Passed: $passed | Warnings: $warnings | Errors: $errors | Critical: $critical"

        echo ""
        gum style --foreground "$color" "What would you like to do?"
        echo ""

        local choice
        choice=$(printf '%s\n' "${options[@]}" | gum choose)
    else
        # Fallback without gum
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "$emoji $label"
        echo "Passed: $passed | Warnings: $warnings | Errors: $errors | Critical: $critical"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Options:"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        echo ""
        read -r -p "Enter choice (1-${#options[@]}): " choice_num
        choice="${options[$((choice_num-1))]}"
    fi

    # Process choice
    case "$choice" in
        "📋 View Detailed Report")
            return 10  # Special code: show report, then re-show menu
            ;;
        "▶️  Continue Anyway")
            return 0   # Continue with execution
            ;;
        "🔧 Show Fix Instructions")
            return 11  # Special code: show fixes, then re-show menu
            ;;
        "🔄 Retry Checks")
            return 1   # Retry
            ;;
        "← Back to"*|"← Back"*)
            return 2   # Back to parent menu
            ;;
        "🚪 Exit"|"")
            return 3   # Exit cleanly
            ;;
        *)
            return 3   # Default to exit on unknown
            ;;
    esac
}

# Show a simple continue/retry/back menu (for simpler use cases)
# Args: $1=message $2=parent_menu_name
# Returns: 0=continue, 1=retry, 2=back
show_simple_result_menu() {
    local message="$1"
    local parent_menu="${2:-Main Menu}"

    if ! is_interactive_mode; then
        return 0
    fi

    echo ""

    if has_gum; then
        gum style --foreground 212 "$message"
        echo ""

        local choice
        choice=$(gum choose \
            "▶️  Continue" \
            "🔄 Retry" \
            "← Back to ${parent_menu}" \
            "🚪 Exit")
    else
        echo "$message"
        echo ""
        echo "1) Continue"
        echo "2) Retry"
        echo "3) Back to ${parent_menu}"
        echo "4) Exit"
        read -r -p "Choice: " choice_num
        case "$choice_num" in
            1) choice="▶️  Continue" ;;
            2) choice="🔄 Retry" ;;
            3) choice="← Back" ;;
            *) choice="🚪 Exit" ;;
        esac
    fi

    case "$choice" in
        "▶️  Continue") return 0 ;;
        "🔄 Retry") return 1 ;;
        "← Back"*) return 2 ;;
        *) return 3 ;;
    esac
}

# ==============================================================================
# RESULT HANDLER (Main entry point for scripts)
# ==============================================================================

# Handle check results with appropriate behavior for mode
# This is the main function scripts should call after running checks
#
# Args:
#   $1 = passed count
#   $2 = warning count
#   $3 = error count (failures)
#   $4 = critical count (blockers)
#   $5 = parent menu name (optional, default "Main Menu")
#   $6 = report file path (optional)
#   $7 = fixes display function name (optional)
#
# Returns:
#   0 = proceed/continue
#   1 = retry requested
#   2 = back to menu requested
#   3 = exit requested
#
# In non-interactive mode: exits with appropriate code
handle_check_results() {
    local passed="${1:-0}"
    local warnings="${2:-0}"
    local errors="${3:-0}"
    local critical="${4:-0}"
    local parent_menu="${5:-Main Menu}"
    local report_file="${6:-}"
    local fixes_function="${7:-}"

    # Classify overall status
    local status
    status=$(classify_results "$passed" "$warnings" "$errors" "$critical")

    # Non-interactive mode: just exit with code
    if ! is_interactive_mode; then
        local exit_code
        exit_code=$(get_exit_code "$status")
        exit "$exit_code"
    fi

    # Interactive mode: show menu and handle choices
    while true; do
        local result
        show_result_menu "$status" "$passed" "$warnings" "$errors" "$critical" "$parent_menu"
        result=$?

        case "$result" in
            0)  # Continue
                return 0
                ;;
            1)  # Retry
                return 1
                ;;
            2)  # Back to menu
                return 2
                ;;
            3)  # Exit
                echo ""
                if has_gum; then
                    gum style --foreground 212 "Goodbye! 👋"
                else
                    echo "Goodbye!"
                fi
                exit 0
                ;;
            10) # View report
                if [[ -n "$report_file" && -f "$report_file" ]]; then
                    if has_gum; then
                        gum pager < "$report_file"
                    else
                        less "$report_file"
                    fi
                else
                    echo "No detailed report available."
                    if has_gum; then
                        read -n 1 -s -r -p "Press any key to continue..."
                    fi
                fi
                ;;
            11) # Show fixes
                if [[ -n "$fixes_function" ]] && declare -f "$fixes_function" > /dev/null; then
                    "$fixes_function"
                else
                    echo "Fix instructions not available for this check."
                fi
                if has_gum; then
                    echo ""
                    read -n 1 -s -r -p "Press any key to continue..."
                fi
                ;;
        esac
    done
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# Wait for user input before returning (interactive only)
# Args: $1=message (optional)
wait_for_input() {
    local message="${1:-Press any key to continue...}"

    if is_interactive_mode; then
        echo ""
        if has_gum; then
            gum style --foreground 240 "$message"
        else
            echo "$message"
        fi
        read -n 1 -s -r
    fi
}

# Show a styled message (uses gum if available)
# Args: $1=message $2=color (optional, default 212)
show_styled_message() {
    local message="$1"
    local color="${2:-212}"

    if has_gum; then
        gum style --foreground "$color" "$message"
    else
        echo "$message"
    fi
}

# Confirm action with user (interactive only)
# Args: $1=prompt
# Returns: 0=yes, 1=no (or non-interactive)
confirm_action() {
    local prompt="$1"

    if ! is_interactive_mode; then
        return 1  # Default to no in non-interactive
    fi

    if has_gum; then
        gum confirm "$prompt"
    else
        read -r -p "$prompt (y/N): " response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

# ==============================================================================
# SCRIPT WRAPPER
# ==============================================================================

# Wrap a check script to add interactive result handling
# Usage: run_check_with_handler check_function parent_menu
#
# The check_function should set these variables:
#   CHECK_PASSED, CHECK_WARNINGS, CHECK_ERRORS, CHECK_CRITICAL
run_check_with_handler() {
    local check_function="$1"
    local parent_menu="${2:-Main Menu}"
    local report_file="${3:-}"
    local fixes_function="${4:-}"

    # Initialize counters
    CHECK_PASSED=0
    CHECK_WARNINGS=0
    CHECK_ERRORS=0
    CHECK_CRITICAL=0

    # Run the check function
    "$check_function"

    # Handle results
    handle_check_results \
        "$CHECK_PASSED" \
        "$CHECK_WARNINGS" \
        "$CHECK_ERRORS" \
        "$CHECK_CRITICAL" \
        "$parent_menu" \
        "$report_file" \
        "$fixes_function"
}
