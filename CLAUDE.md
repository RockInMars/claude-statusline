# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code Statusline is a Bash script that enhances Claude Code's status bar with multi-provider detection, Git status, context usage, and cost display.

## Development Commands

### Testing the Statusline Script

```bash
# Test with sample input
echo '{"model":{"display_name":"claude-sonnet-4-0","id":"claude-sonnet-4-0"},"cwd":"/path/to/project","workspace":{"project_dir":"/path/to/project"},"context_window":{"used_percentage":45}}' | bash statusline.sh

# Test with empty input (initialization state)
echo '' | bash statusline.sh

# Debug mode: inspect actual JSON input from Claude Code
# Run: STATUSLINE_DEBUG=1 claude
# Then: cat /tmp/statusline_debug.json | jq '.'
```

### Installation/Uninstallation

```bash
# Install
bash install.sh

# Uninstall
bash install.sh --uninstall
```

## Architecture

### Data Flow

```
Claude Code (stdin JSON) → statusline.sh → formatted 2-line output
```

Claude Code passes a JSON object via stdin containing:
- `model.display_name` / `model.id` - Current model info
- `cwd` / `workspace.project_dir` - Project directory
- `context_window.used_percentage` - Context usage
- `context_window.context_window_size` - Max context window tokens
- `context_window.remaining_percentage` - Context remaining (alternative to used_percentage)
- `rate_limits.five_hour/seven_day.used_percentage` - Rate limits (Anthropic API only)
- `context_window.total_input_tokens/total_output_tokens` - Token counts (third-party APIs)
- `cost.total_cost_usd` - Cumulative cost
- `output_style.name` - Current output style
- `session_name` - Session identifier

### Key Functions in statusline.sh

| Function | Purpose |
|----------|---------|
| `jq_get()` | Safely extract string values from JSON with defaults |
| `jq_get_num()` | Extract numeric values with validation |
| `get_provider_info()` | Detect API provider from `ANTHROPIC_BASE_URL` in settings.json |
| `get_git_status()` | Extract branch, staged/modified/untracked counts |
| `format_pct()` | Format percentages with color coding (green <70%, yellow 70-89%, red ≥90%) |

### Provider Detection Logic

The script detects providers by pattern matching against `ANTHROPIC_BASE_URL`:
- Priority: `$project/.claude/settings.local.json` → `~/.claude/settings.json`
- Matches URL patterns to identify providers (GLM, DeepSeek, OpenAI, etc.)
- Falls back to extracting domain name for unknown providers

### Color System

Uses `tput` for terminal color compatibility with fallback to raw ANSI sequences when `tput` is unavailable.

## Dependencies

- `jq` - JSON processing (required)
- `git` - Version control info (required)
- `tput` - Terminal colors (optional, has fallback)

## Project Structure

```
.
├── statusline.sh              # Main statusline script
├── install.sh                 # Installation/uninstallation
├── CLAUDE.md                  # This file
├── README.md                  # User documentation
├── .gitignore                 # Git ignore rules
├── .claudeignore              # Claude Code ignore rules
└── .claude/
    ├── settings.json          # Project Claude Code config (hooks, permissions)
    ├── settings.local.json    # Local project config (gitignored, e.g., API provider)
    └── agents/
        └── shell-linter.md    # Shell script review subagent
```
