#!/bin/bash
# Claude Code Enhanced Statusline
# Features: Model, Provider, Git, Context Usage, Rate Limits
# Location: ~/.claude/statusline.sh

set -euo pipefail

# ------------------------------------------------------------------------------
# Color definitions using tput for better compatibility
# ------------------------------------------------------------------------------
if command -v tput &>/dev/null && tput setaf 1 &>/dev/null; then
    # Terminal supports colors via tput
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    DIM=$(tput dim 2>/dev/null || tput setaf 8)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    # Fallback: use raw escape sequences
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    DIM='\033[2m'
    BOLD='\033[1m'
    RESET='\033[0m'
fi

# Separator
SEP=" ${DIM}│${RESET}"

# ------------------------------------------------------------------------------
# Read stdin JSON
# ------------------------------------------------------------------------------
input=$(cat)

if [[ -z "$input" ]]; then
    echo "[Statusline] Initializing..."
    exit 0
fi

# ------------------------------------------------------------------------------
# Helper function: safely extract JSON value with jq
# ------------------------------------------------------------------------------
jq_get() {
    local path="$1"
    local default="${2:-}"
    echo "$input" | jq -r "${path} // \"${default}\"" 2>/dev/null || echo "$default"
}

jq_get_num() {
    local path="$1"
    local default="${2:-}"
    local val
    val=$(echo "$input" | jq -r "${path} // empty" 2>/dev/null)
    if [[ -n "$val" && "$val" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$val"
    else
        echo "$default"
    fi
}

# ------------------------------------------------------------------------------
# Extract basic info from stdin
# ------------------------------------------------------------------------------
model_display=$(jq_get '.model.display_name' 'Unknown')
model_id=$(jq_get '.model.id' '')
project_dir=$(jq_get '.cwd' '')
workspace_dir=$(jq_get '.workspace.project_dir' "$project_dir")

# Context window info
context_used_pct=$(jq_get_num '.context_window.used_percentage')
context_remaining_pct=$(jq_get_num '.context_window.remaining_percentage')
context_max_tokens=$(jq_get_num '.context_window.max_tokens')

# Rate limits (only available for Anthropic API)
five_hour_pct=$(jq_get_num '.rate_limits.five_hour.used_percentage')
seven_day_pct=$(jq_get_num '.rate_limits.seven_day.used_percentage')

# Token usage info (available for all APIs)
total_input_tokens=$(jq_get_num '.context_window.total_input_tokens')
total_output_tokens=$(jq_get_num '.context_window.total_output_tokens')

# Cost info
total_cost=$(jq_get_num '.cost.total_cost_usd')

# Output style
output_style=$(jq_get '.output_style.name' '')

# Session info
session_name=$(jq_get '.session_name' '')

# ------------------------------------------------------------------------------
# Get project name
# ------------------------------------------------------------------------------
project_name=""
if [[ -n "$workspace_dir" && "$workspace_dir" != "." ]]; then
    project_name=$(basename "$workspace_dir")
fi

# ------------------------------------------------------------------------------
# Detect Provider from settings.json
# ------------------------------------------------------------------------------
get_provider_info() {
    local settings_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
    local provider="Anthropic"
    local provider_short="Anthropic"
    local base_url=""

    if [[ -f "$settings_file" ]]; then
        base_url=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$settings_file" 2>/dev/null)

        # Detect provider from base URL
        if [[ -n "$base_url" ]]; then
            case "$base_url" in
                # ========== 中国云服务商 ==========
                *open.bigmodel.cn*|*bigmodel.cn*)
                    provider="智谱 GLM"
                    provider_short="GLM"
                    ;;
                *dashscope.aliyuncs.com*|*aliyuncs.com*)
                    provider="阿里云百炼"
                    provider_short="阿里云"
                    ;;
                *api.hunyuan.cloud.tencent.com*|*hunyuan.tencent.com*|*tencent.com*)
                    provider="腾讯混元"
                    provider_short="腾讯"
                    ;;
                *api.minimax.chat*|*minimax.chat*)
                    provider="MiniMax"
                    provider_short="MiniMax"
                    ;;
                *api.siliconflow.cn*|*siliconflow.cn*)
                    provider="硅基流动"
                    provider_short="SiliconFlow"
                    ;;
                *api.moonshot.cn*|*moonshot.cn*)
                    provider="Moonshot"
                    provider_short="Moonshot"
                    ;;
                *api.baichuan-ai.com*|*baichuan-ai.com*)
                    provider="百川智能"
                    provider_short="百川"
                    ;;
                *api.zhipuai.cn*|*zhipuai.cn*)
                    provider="智谱 AI"
                    provider_short="智谱"
                    ;;
                *aigc.sensorsdata.cn*|*sensorsdata.cn*)
                    provider="神策数据"
                    provider_short="神策"
                    ;;
                *api.xfyun.cn*|*xfyun.cn*)
                    provider="讯飞星火"
                    provider_short="讯飞"
                    ;;

                # ========== 国际云服务商 ==========
                *api.deepseek.com*)
                    provider="DeepSeek"
                    provider_short="DeepSeek"
                    ;;
                *openai.com*|*api.openai.com*)
                    provider="OpenAI"
                    provider_short="OpenAI"
                    ;;
                *bedrock*|*amazonaws.com*)
                    provider="AWS Bedrock"
                    provider_short="Bedrock"
                    ;;
                *azure.com*)
                    provider="Azure OpenAI"
                    provider_short="Azure"
                    ;;
                *anthropic.com*)
                    provider="Anthropic"
                    provider_short="Anthropic"
                    ;;
                *generativelanguage.googleapis.com*|*aiplatform.googleapis.com*)
                    provider="Google AI"
                    provider_short="Google"
                    ;;
                *cursor.sh*|*cursor.com*)
                    provider="Cursor"
                    provider_short="Cursor"
                    ;;
                *claude.ai*)
                    provider="Claude"
                    provider_short="Claude"
                    ;;
                *openrouter.ai*)
                    provider="OpenRouter"
                    provider_short="OR"
                    ;;
                *groq.com*|*api.groq.com*)
                    provider="Groq"
                    provider_short="Groq"
                    ;;
                *mistral.ai*|*api.mistral.ai*)
                    provider="Mistral"
                    provider_short="Mistral"
                    ;;
                *cerebras.ai*|*api.cerebras.ai*)
                    provider="Cerebras"
                    provider_short="Cerebras"
                    ;;
                *localhost*|*127.0.0.1*)
                    provider="Local"
                    provider_short="Local"
                    ;;
                *)
                    # Extract domain as provider hint
                    provider_short=$(echo "$base_url" | sed -E 's|https?://([^/]+).*|\1|' | cut -d'.' -f1 | head -c8)
                    provider="Custom"
                    ;;
            esac
        fi
    fi

    # Check model ID for Bedrock
    if [[ -n "$model_id" ]]; then
        case "$model_id" in
            *anthropic.claude-*)
                provider="AWS Bedrock"
                provider_short="Bedrock"
                ;;
        esac
    fi

    echo "$provider|$provider_short"
}

# ------------------------------------------------------------------------------
# Get Git status
# ------------------------------------------------------------------------------
get_git_status() {
    local dir="$1"

    if [[ -z "$dir" || ! -d "$dir" ]]; then
        echo ""
        return
    fi

    # Check if inside a git repo
    if ! git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null; then
        echo ""
        return
    fi

    local branch
    branch=$(git -C "$dir" branch --show-current 2>/dev/null || echo "detached")

    # Get status counts
    local staged modified untracked

    staged=$(git -C "$dir" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git -C "$dir" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # Build status string
    local status_parts=()
    status_parts+=("${CYAN}${branch}${RESET}")

    if [[ "$staged" -gt 0 ]]; then
        status_parts+=("${GREEN}+${staged}${RESET}")
    fi
    if [[ "$modified" -gt 0 ]]; then
        status_parts+=("${YELLOW}~${modified}${RESET}")
    fi
    if [[ "$untracked" -gt 0 ]]; then
        status_parts+=("${DIM}?${untracked}${RESET}")
    fi

    local IFS=' '
    echo "${status_parts[*]}"
}

# ------------------------------------------------------------------------------
# Format percentage with color
# ------------------------------------------------------------------------------
format_pct() {
    local pct="$1"
    local label="${2:-}"

    if [[ -z "$pct" ]]; then
        echo ""
        return
    fi

    # Round to integer
    local int_pct
    int_pct=$(printf "%.0f" "$pct" 2>/dev/null)

    if [[ -z "$int_pct" || "$int_pct" == "0" ]]; then
        echo ""
        return
    fi

    local color=""
    if [[ "$int_pct" -ge 90 ]]; then
        color="$RED"
    elif [[ "$int_pct" -ge 70 ]]; then
        color="$YELLOW"
    else
        color="$GREEN"
    fi

    if [[ -n "$label" ]]; then
        echo "${label}${color}${int_pct}%${RESET}"
    else
        echo "${color}${int_pct}%${RESET}"
    fi
}

# ------------------------------------------------------------------------------
# Build status lines
# ------------------------------------------------------------------------------
provider_info=$(get_provider_info)
provider_name=$(echo "$provider_info" | cut -d'|' -f1)
provider_short=$(echo "$provider_info" | cut -d'|' -f2)

# Line 1: Model & Provider
line1_parts=()

# Model badge with provider
if [[ "$provider_short" != "Anthropic" && -n "$provider_short" ]]; then
    line1_parts+=("${BOLD}${model_display}${RESET} ${DIM}via${RESET} ${MAGENTA}${provider_short}${RESET}")
else
    line1_parts+=("${BOLD}${model_display}${RESET}")
fi

# Project name
if [[ -n "$project_name" ]]; then
    line1_parts+=("${BLUE}${project_name}${RESET}")
fi

# Git status
git_status=$(get_git_status "$workspace_dir")
if [[ -n "$git_status" ]]; then
    line1_parts+=("$git_status")
fi

# Session name (if set)
if [[ -n "$session_name" ]]; then
    line1_parts+=("${DIM}[${session_name}]${RESET}")
fi

# Line 2: Context & Usage
line2_parts=()

# Context remaining with total
format_tokens() {
    local tokens=$1
    if [[ "$tokens" -ge 1000 ]]; then
        printf "%.0fk" $((tokens / 1000))
    else
        echo "$tokens"
    fi
}

if [[ -n "$context_max_tokens" && "$context_max_tokens" != "0" ]]; then
    # Calculate used tokens from percentage
    if [[ -n "$context_remaining_pct" ]]; then
        used_tokens=$((context_max_tokens * (100 - context_remaining_pct) / 100))
        remaining_pct="$context_remaining_pct"
    elif [[ -n "$context_used_pct" ]]; then
        used_tokens=$((context_max_tokens * context_used_pct / 100))
        remaining_pct=$((100 - context_used_pct))
    else
        used_tokens=0
        remaining_pct=100
    fi
    used_str=$(format_tokens "$used_tokens")
    max_str=$(format_tokens "$context_max_tokens")
    line2_parts+=("Ctx: ${used_str}/${max_str} $(format_pct "$remaining_pct")")
elif [[ -n "$context_remaining_pct" ]]; then
    line2_parts+=("Ctx: $(format_pct "$context_remaining_pct")")
elif [[ -n "$context_used_pct" ]]; then
    remaining=$((100 - context_used_pct))
    line2_parts+=("Ctx: $(format_pct "$remaining")")
fi

# Rate limits (only available for Anthropic API)
if [[ -n "$five_hour_pct" ]]; then
    line2_parts+=("5h: $(format_pct "$five_hour_pct")")
fi

if [[ -n "$seven_day_pct" ]]; then
    line2_parts+=("7d: $(format_pct "$seven_day_pct")")
fi

# Token usage & Cost (shown when rate limits not available - for third-party APIs)
if [[ -z "$five_hour_pct" && -z "$seven_day_pct" ]]; then
    # Format token counts (K for thousands)
    if [[ -n "$total_input_tokens" && "$total_input_tokens" != "0" ]]; then
        if [[ "$total_input_tokens" -ge 1000 ]]; then
            in_k=$(printf "%.0fK" $((total_input_tokens / 1000)))
        else
            in_k="$total_input_tokens"
        fi
        if [[ -n "$total_output_tokens" && "$total_output_tokens" != "0" ]]; then
            if [[ "$total_output_tokens" -ge 1000 ]]; then
                out_k=$(printf "%.0fK" $((total_output_tokens / 1000)))
            else
                out_k="$total_output_tokens"
            fi
            line2_parts+=("${DIM}${in_k}in/${out_k}out${RESET}")
        else
            line2_parts+=("${DIM}${in_k}in${RESET}")
        fi
    fi

    # Cost
    if [[ -n "$total_cost" && "$total_cost" != "0" ]]; then
        cost_str=$(printf "%.2f" "$total_cost" 2>/dev/null)
        line2_parts+=("${DIM}\$${cost_str}${RESET}")
    fi
fi

# Output style (if not default)
if [[ -n "$output_style" && "$output_style" != "default" ]]; then
    line2_parts+=("${DIM}[${output_style}]${RESET}")
fi

# Provider info (full name on second line if custom)
if [[ "$provider_name" != "Anthropic" && -n "$provider_name" ]]; then
    line2_parts+=("${DIM}Provider: ${provider_name}${RESET}")
fi

# ------------------------------------------------------------------------------
# Output - use printf with %b to interpret escape sequences
# ------------------------------------------------------------------------------
line1_str=""
first=true
for part in "${line1_parts[@]}"; do
    if [[ -n "$part" ]]; then
        if [[ "$first" == "true" ]]; then
            line1_str="$part"
            first=false
        else
            line1_str+="${SEP} ${part}"
        fi
    fi
done

line2_str=""
first=true
for part in "${line2_parts[@]}"; do
    if [[ -n "$part" ]]; then
        if [[ "$first" == "true" ]]; then
            line2_str="$part"
            first=false
        else
            line2_str+="${SEP} ${part}"
        fi
    fi
done

# Output using printf %b to handle escape sequences
if [[ -n "$line1_str" ]]; then
    printf '%b\n' "$line1_str"
fi

if [[ -n "$line2_str" ]]; then
    printf '%b\n' "$line2_str"
fi
