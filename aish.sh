#!/usr/bin/env zsh

# aish - AI Shell Assistant
# A production-quality CLI tool that converts natural language to shell commands
# Usage: aish [command] or just 'aish' for interactive mode

set -euo pipefail

# Configuration
AISH_DIR="$HOME/.aish"
AISH_HISTORY="$AISH_DIR/history.log"
AISH_AGENT_DIR="$(dirname "$(realpath "$0")")/aish_agent"
PYTHON_CMD="${AISH_PYTHON:-python3}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis for better UX
ROBOT="🤖"
THINKING="🧠"
COMMAND="💬"
SUCCESS="🟢"
ERROR="🔴"
WARNING="⚠️"

# Initialize aish directory and history
init_aish() {
    if [[ ! -d "$AISH_DIR" ]]; then
        mkdir -p "$AISH_DIR"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - aish initialized" >> "$AISH_HISTORY"
    fi
}

# Display help
show_help() {
    cat << EOF
${ROBOT} aish - AI Shell Assistant

USAGE:
    aish [natural language command]    # Execute a single command
    aish                              # Interactive mode
    aish --help                       # Show this help
    aish --version                    # Show version
    aish --history                    # Show command history

EXAMPLES:
    aish "install nginx and start the service"
    aish "show me all running processes"
    aish "create a new directory called projects"

ENVIRONMENT VARIABLES:
    AISH_BACKEND        # openai or ollama (default: openai)
    AISH_AGENT_MODE     # langgraph or basic (default: langgraph)
    OPENAI_API_KEY      # Required for OpenAI backend
    OLLAMA_MODEL        # Model name for Ollama (default: llama2)
    AISH_PYTHON         # Python command to use (default: python3)

For more information, visit: https://github.com/your-repo/aish
EOF
}

# Show version
show_version() {
    echo "${ROBOT} aish v1.0.0"
}

# Show history
show_history() {
    if [[ -f "$AISH_HISTORY" ]]; then
        echo "${ROBOT} Command History:"
        tail -20 "$AISH_HISTORY"
    else
        echo "${WARNING} No history found. Run some commands first!"
    fi
}

# Check if Python agent is available
check_agent() {
    if [[ ! -d "$AISH_AGENT_DIR" ]]; then
        echo "${ERROR} aish agent not found at: $AISH_AGENT_DIR"
        echo "Please run the installation script first."
        return 1
    fi
    
    if ! command -v "$PYTHON_CMD" &> /dev/null; then
        echo "${ERROR} Python not found. Please install Python 3.8+ or set AISH_PYTHON"
        return 1
    fi
}

# Execute the Python agent
run_agent() {
    local user_input="$1"
    
    # Log the user input
    echo "$(date '+%Y-%m-%d %H:%M:%S') - User: $user_input" >> "$AISH_HISTORY"
    
    # Run the Python agent
    cd "$AISH_AGENT_DIR"
    "$PYTHON_CMD" -m aish_agent.agent_langgraph "$user_input"
}

# Interactive mode
interactive_mode() {
    echo "${ROBOT} Welcome to aish - AI Shell Assistant"
    echo "Type your natural language commands, 'help' for help, or 'exit' to quit."
    echo ""
    
    while true; do
        # Display prompt
        echo -n "${ROBOT} aish > "
        read -r user_input
        
        # Handle special commands
        case "$user_input" in
            "exit"|"quit"|"q")
                echo "${SUCCESS} Goodbye!"
                break
                ;;
            "help"|"h")
                show_help
                continue
                ;;
            "history")
                show_history
                continue
                ;;
            "clear")
                clear
                continue
                ;;
            "")
                continue
                ;;
        esac
        
        # Execute the command
        echo "${THINKING} Processing your request..."
        run_agent "$user_input"
        echo ""
    done
}

# Main function
main() {
    # Initialize
    init_aish
    
    # Check if agent is available
    if ! check_agent; then
        exit 1
    fi
    
    # Handle command line arguments
    case "${1:-}" in
        "--help"|"-h")
            show_help
            ;;
        "--version"|"-v")
            show_version
            ;;
        "--history")
            show_history
            ;;
        "")
            # Interactive mode
            interactive_mode
            ;;
        *)
            # Single command mode
            echo "${THINKING} Processing your request..."
            run_agent "$*"
            ;;
    esac
}

# Run main function with all arguments
main "$@" 