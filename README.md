# Claude Code Statusline

增强 Claude Code 状态栏，支持多供应商检测、Git 状态、上下文使用率、成本显示等功能。

## 功能特性

- 🏷️ **模型名称** + 供应商自动检测
- 📁 **项目名称** 显示
- 🔀 **Git 状态**（分支、暂存、修改、未跟踪）
- 📊 **上下文使用率** 颜色编码
- ⏱️ **配额监控**（5h/7d - 仅 Anthropic API）
- 📈 **Token 用量**（输入/输出 tokens - 第三方 API）
- 💰 **成本显示**（累计成本）
- 🌐 **多供应商支持**

## 支持的供应商

### 中国云服务商

| 供应商 | API 域名 | 显示名称 |
|--------|----------|----------|
| 智谱 GLM | `open.bigmodel.cn` | GLM |
| 阿里云百炼 | `dashscope.aliyuncs.com` | 阿里云 |
| 腾讯混元 | `hunyuan.cloud.tencent.com` | 腾讯 |
| MiniMax | `api.minimax.chat` | MiniMax |
| 硅基流动 | `api.siliconflow.cn` | SiliconFlow |
| Moonshot | `api.moonshot.cn` | Moonshot |
| 百川智能 | `api.baichuan-ai.com` | 百川 |
| 讯飞星火 | `api.xfyun.cn` | 讯飞 |

### 国际云服务商

| 供应商 | API 域名 | 显示名称 |
|--------|----------|----------|
| Anthropic | `anthropic.com` | Anthropic |
| OpenAI | `api.openai.com` | OpenAI |
| Google AI | `generativelanguage.googleapis.com` | Google |
| Cursor | `cursor.sh` / `cursor.com` | Cursor |
| Claude | `claude.ai` | Claude |
| DeepSeek | `api.deepseek.com` | DeepSeek |
| AWS Bedrock | `amazonaws.com` | Bedrock |
| Azure OpenAI | `azure.com` | Azure |
| OpenRouter | `openrouter.ai` | OR |
| Groq | `api.groq.com` | Groq |
| Mistral | `api.mistral.ai` | Mistral |
| Cerebras | `api.cerebras.ai` | Cerebras |

## 安装

### 前置要求

- `jq` - JSON 处理工具
- `git` - 版本控制
- `tput` - 终端颜色支持（通常内置）

### 快速安装

```bash
# 克隆或下载此目录
cd statusline

# 运行安装脚本
bash install.sh
```

### 手动安装

```bash
# 1. 复制脚本
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# 2. 编辑 settings.json，添加：
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## 卸载

```bash
bash install.sh --uninstall
```

## 输出示例

### Anthropic API（有配额）

```
claude-sonnet-4-0 │ my-project │ main +3 ~1
Ctx: 45% │ 5h: 30% │ 7d: 15%
```

### 第三方 API（显示 token 用量和成本）

```
glm-5 via GLM │ lanhu-skills │ master ~31 ?28
Ctx: 44% │ 446Kin/35Kout │ $6.12 │ Provider: 智谱 GLM
```

### Git 状态符号

| 符号 | 含义 | 颜色 |
|------|------|------|
| `+N` | 已暂存待提交 | 绿色 |
| `~N` | 已修改未暂存 | 黄色 |
| `?N` | 未跟踪文件 | 灰色 |

### 使用率颜色

| 范围 | 颜色 |
|------|------|
| < 70% | 绿色 |
| 70-89% | 黄色 |
| ≥ 90% | 红色 |

## 配置供应商

在 `~/.claude/settings.json` 中设置 `ANTHROPIC_BASE_URL`：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic"
  }
}
```

## 故障排除

### 颜色不显示

1. 检查终端是否支持 256 色：`echo $TERM`
2. 确认 `tput` 可用：`tput colors`
3. 尝试重启 Claude Code

### 配额/用量显示

- **Anthropic API**：显示 5h/7d 配额百分比
- **第三方 API**：显示 Token 用量（`XXXKin/XXXKout`）+ 累计成本（`$X.XX`）

### 供应商显示错误

确认 `settings.json` 中的 `ANTHROPIC_BASE_URL` 格式正确。

## 文件结构

```
claude-statusline/
├── statusline.sh              # 主脚本
├── install.sh                 # 安装/卸载脚本
├── README.md                  # 文档
├── CLAUDE.md                  # Claude Code 指南
├── .gitignore                 # Git 忽略规则
├── .claudeignore              # Claude Code 忽略规则
└── .claude/
    ├── settings.json          # Claude Code 项目配置
    └── agents/
        └── shell-linter.md    # Shell 脚本审查 agent
```
