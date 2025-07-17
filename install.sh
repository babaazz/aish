#!/bin/bash

# aish Installation Script
# Installs the AI Shell Assistant and sets up shell integration

set -euo pipefail

# Configuration
INSTALL_DIR="$HOME/.aish"
AISH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_CMD="${AISH_PYTHON:-python3}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emojis
ROBOT="🤖"
SUCCESS="✅"
ERROR="❌"
WARNING="⚠️"
INFO="ℹ️"

# Print colored output
print_status() {
    echo -e "${GREEN}${SUCCESS}${NC} $1"
}

print_error() {
    echo -e "${RED}${ERROR}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}${WARNING}${NC} $1"
}

print_info() {
    echo -e "${BLUE}${INFO}${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check Python
    if ! command_exists "$PYTHON_CMD"; then
        print_error "Python 3.8+ is required but not found"
        print_info "Please install Python 3.8+ and try again"
        exit 1
    fi
    
    # Check Python version
    python_version=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
    python_major=$(echo "$python_version" | cut -d. -f1)
    python_minor=$(echo "$python_version" | cut -d. -f2)
    
    if [ "$python_major" -lt 3 ] || ([ "$python_major" -eq 3 ] && [ "$python_minor" -lt 8 ]); then
        print_error "Python 3.8+ is required, but found $python_version"
        exit 1
    fi
    
    print_status "Python $python_version found"
    
    # Check pip
    if ! command_exists pip3 && ! command_exists pip; then
        print_error "pip is required but not found"
        exit 1
    fi
    
    # Check git (optional, for development)
    if command_exists git; then
        print_status "Git found (optional)"
    else
        print_warning "Git not found (optional, needed for development)"
    fi
}

# Install Python dependencies
install_dependencies() {
    print_info "Installing Python dependencies..."
    
    # Use pip3 if available, otherwise pip
    PIP_CMD="pip3"
    if ! command_exists pip3; then
        PIP_CMD="pip"
    fi
    
    # Install dependencies
    if [ -f "$AISH_DIR/requirements.txt" ]; then
        "$PIP_CMD" install --user -r "$AISH_DIR/requirements.txt"
        print_status "Dependencies installed successfully"
    else
        print_error "requirements.txt not found"
        exit 1
    fi
}

# Create installation directory
create_install_dir() {
    print_info "Creating installation directory..."
    
    # Create .aish directory
    mkdir -p "$INSTALL_DIR"
    
    # Create symbolic link to aish.sh
    ln -sf "$AISH_DIR/aish.sh" "$INSTALL_DIR/aish"
    chmod +x "$INSTALL_DIR/aish"
    
    print_status "Installation directory created at $INSTALL_DIR"
}

# Setup shell integration
setup_shell_integration() {
    print_info "Setting up shell integration..."
    
    # Detect shell
    SHELL_NAME=$(basename "$SHELL")
    
    case "$SHELL_NAME" in
        zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        bash)
            SHELL_RC="$HOME/.bashrc"
            ;;
        fish)
            SHELL_RC="$HOME/.config/fish/config.fish"
            ;;
        *)
            print_warning "Unsupported shell: $SHELL_NAME"
            print_info "You'll need to manually add $INSTALL_DIR to your PATH"
            return
            ;;
    esac
    
    # Check if PATH already contains install dir
    if echo "$PATH" | grep -q "$INSTALL_DIR"; then
        print_status "PATH already contains $INSTALL_DIR"
        return
    fi
    
    # Add to shell RC file
    if [ -f "$SHELL_RC" ]; then
        # Check if already added
        if grep -q "# aish PATH" "$SHELL_RC"; then
            print_status "Shell integration already configured"
            return
        fi
        
        # Add PATH export
        cat >> "$SHELL_RC" << EOF

# aish PATH
export PATH="\$HOME/.aish:\$PATH"
EOF
        
        print_status "Added $INSTALL_DIR to PATH in $SHELL_RC"
        print_info "Please restart your shell or run: source $SHELL_RC"
    else
        print_warning "$SHELL_RC not found"
        print_info "Please manually add $INSTALL_DIR to your PATH"
    fi
}

# Create example configuration
create_example_config() {
    print_info "Creating example configuration..."
    
    # Create .env.example
    cat > "$AISH_DIR/.env.example" << 'EOF'
# aish Configuration Example
# Copy this to .env and configure your settings

# Backend Configuration
AISH_BACKEND=openai  # openai or ollama
AISH_AGENT_MODE=langgraph  # langgraph or basic

# OpenAI Configuration (required for openai backend)
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4  # gpt-4, gpt-3.5-turbo, etc.
# OPENAI_BASE_URL=https://api.openai.com/v1  # Optional custom base URL

# Ollama Configuration (required for ollama backend)
OLLAMA_MODEL=llama2  # llama2, codellama, etc.
OLLAMA_BASE_URL=http://localhost:11434  # Ollama server URL

# Agent Configuration
AISH_MAX_RETRIES=3
AISH_TIMEOUT=30
AISH_DEBUG=false

# Python Configuration
AISH_PYTHON=python3
EOF
    
    print_status "Example configuration created at $AISH_DIR/.env.example"
}

# Test installation
test_installation() {
    print_info "Testing installation..."
    
    # Test if aish command works
    if [ -x "$INSTALL_DIR/aish" ]; then
        # Test basic functionality
        if "$INSTALL_DIR/aish" --version >/dev/null 2>&1; then
            print_status "Installation test passed"
        else
            print_warning "Installation test failed - check dependencies"
        fi
    else
        print_error "aish command not found or not executable"
        exit 1
    fi
}

# Display setup instructions
display_setup_instructions() {
    echo ""
    echo -e "${ROBOT} ${GREEN}aish Installation Complete!${NC}"
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. Configure your AI backend:"
    echo "   cp $AISH_DIR/.env.example $AISH_DIR/.env"
    echo "   # Edit .env with your API keys and preferences"
    echo ""
    echo "2. For OpenAI backend:"
    echo "   export OPENAI_API_KEY='your-api-key-here'"
    echo ""
    echo "3. For Ollama backend:"
    echo "   # Install Ollama from https://ollama.ai"
    echo "   # Pull a model: ollama pull llama2"
    echo "   export AISH_BACKEND=ollama"
    echo ""
    echo "4. Restart your shell or run:"
    echo "   source $SHELL_RC"
    echo ""
    echo "5. Test the installation:"
    echo "   aish --help"
    echo "   aish 'show current directory'"
    echo ""
    echo "📚 Documentation:"
    echo "   - Configuration: $AISH_DIR/.env.example"
    echo "   - History: ~/.aish/history.log"
    echo "   - Help: aish --help"
    echo ""
    echo "🎉 Happy AI-assisted shell commanding!"
}

# Main installation function
main() {
    echo -e "${ROBOT} ${BLUE}aish Installation Script${NC}"
    echo "Installing AI Shell Assistant..."
    echo ""
    
    # Check if running from correct directory
    if [ ! -f "$AISH_DIR/aish.sh" ]; then
        print_error "Installation script must be run from the aish directory"
        exit 1
    fi
    
    # Run installation steps
    check_requirements
    install_dependencies
    create_install_dir
    setup_shell_integration
    create_example_config
    test_installation
    display_setup_instructions
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "aish Installation Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --uninstall    Uninstall aish"
        echo ""
        echo "Environment Variables:"
        echo "  AISH_PYTHON    Python command to use (default: python3)"
        exit 0
        ;;
    --uninstall)
        print_info "Uninstalling aish..."
        
        # Remove installation directory
        if [ -d "$INSTALL_DIR" ]; then
            rm -rf "$INSTALL_DIR"
            print_status "Removed $INSTALL_DIR"
        fi
        
        # Remove shell integration
        for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.config/fish/config.fish"; do
            if [ -f "$rc" ] && grep -q "# aish PATH" "$rc"; then
                # Remove the aish PATH section
                sed -i '/# aish PATH/,/^$/d' "$rc"
                print_status "Removed shell integration from $rc"
            fi
        done
        
        print_status "aish uninstalled successfully"
        exit 0
        ;;
    "")
        # Default installation
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac 