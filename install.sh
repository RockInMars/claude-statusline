#!/bin/bash
# =============================================================================
# Claude Code Statusline Installer
# =============================================================================
# Usage: bash install.sh [--uninstall]
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Paths
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$CLAUDE_DIR/statusline.sh"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------
log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

check_dependencies() {
    local missing=()

    if ! command -v jq &>/dev/null; then
        missing+=("jq")
    fi

    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        echo ""
        echo "Install them with:"
        echo "  macOS:   brew install ${missing[*]}"
        echo "  Ubuntu:  sudo apt install ${missing[*]}"
        echo "  Windows: choco install ${missing[*]}"
        exit 1
    fi
}

backup_settings() {
    if [[ -f "$SETTINGS_FILE" ]]; then
        local backup="${SETTINGS_FILE}.backup.$(date +%Y%m%d%H%M%S)"
        cp "$SETTINGS_FILE" "$backup"
        log_info "Backup created: $backup"
    fi
}

# ------------------------------------------------------------------------------
# Install
# ------------------------------------------------------------------------------
install() {
    log_info "Installing Claude Code Statusline..."
    echo ""

    # Check dependencies
    check_dependencies

    # Create Claude config directory
    mkdir -p "$CLAUDE_DIR"
    log_success "Config directory: $CLAUDE_DIR"

    # Copy statusline script
    cp "$SCRIPT_DIR/statusline.sh" "$TARGET_SCRIPT"
    chmod +x "$TARGET_SCRIPT"
    log_success "Script installed: $TARGET_SCRIPT"

    # Backup and update settings.json
    backup_settings

    # Update statusLine configuration
    if [[ -f "$SETTINGS_FILE" ]]; then
        # Check if statusLine already exists
        if grep -q '"statusLine"' "$SETTINGS_FILE"; then
            # Update existing statusLine
            if command -v jq &>/dev/null; then
                local tmp_file="${SETTINGS_FILE}.tmp"
                jq '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' "$SETTINGS_FILE" > "$tmp_file"
                mv "$tmp_file" "$SETTINGS_FILE"
                log_success "Updated statusLine in settings.json"
            else
                log_warn "jq not found, please manually update settings.json"
            fi
        else
            # Add statusLine to settings.json
            if command -v jq &>/dev/null; then
                local tmp_file="${SETTINGS_FILE}.tmp"
                jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh"}}' "$SETTINGS_FILE" > "$tmp_file"
                mv "$tmp_file" "$SETTINGS_FILE"
                log_success "Added statusLine to settings.json"
            else
                log_warn "jq not found, please manually add statusLine to settings.json"
            fi
        fi
    else
        # Create new settings.json
        cat > "$SETTINGS_FILE" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
EOF
        log_success "Created settings.json"
    fi

    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Please restart Claude Code to apply changes."
    echo ""
    echo "Supported providers:"
    echo "  - Anthropic (default)"
    echo "  - 智谱 GLM, 阿里云百炼, 腾讯混元, MiniMax"
    echo "  - SiliconFlow, Moonshot, 百川智能, 讯飞星火"
    echo "  - OpenAI, Google AI, Cursor, Claude"
    echo "  - DeepSeek, AWS Bedrock, Azure OpenAI"
    echo "  - OpenRouter, Groq, Mistral, Cerebras"
}

# ------------------------------------------------------------------------------
# Uninstall
# ------------------------------------------------------------------------------
uninstall() {
    log_info "Uninstalling Claude Code Statusline..."
    echo ""

    # Remove statusline script
    if [[ -f "$TARGET_SCRIPT" ]]; then
        rm "$TARGET_SCRIPT"
        log_success "Removed: $TARGET_SCRIPT"
    else
        log_warn "Script not found: $TARGET_SCRIPT"
    fi

    # Remove statusLine from settings.json
    if [[ -f "$SETTINGS_FILE" ]] && command -v jq &>/dev/null; then
        backup_settings
        local tmp_file="${SETTINGS_FILE}.tmp"
        jq 'del(.statusLine)' "$SETTINGS_FILE" > "$tmp_file"
        mv "$tmp_file" "$SETTINGS_FILE"
        log_success "Removed statusLine from settings.json"
    fi

    echo ""
    log_success "Uninstallation complete!"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
case "${1:-}" in
    --uninstall|-u)
        uninstall
        ;;
    --help|-h)
        echo "Usage: bash install.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --uninstall, -u  Remove statusline"
        echo "  --help, -h       Show this help"
        ;;
    *)
        install
        ;;
esac
