#!/bin/bash
# Worker Agent 启动脚本

set -e

echo "=== Worker Agent Starting ==="

# 检查必要的环境变量
if [ -z "$FORGEJO_URL" ]; then
    echo "Error: FORGEJO_URL not set"
    exit 1
fi

if [ -z "$FORGEJO_TOKEN" ]; then
    echo "Error: FORGEJO_TOKEN not set"
    exit 1
fi

if [ -z "$ANTHROPIC_AUTH_TOKEN" ]; then
    echo "Error: ANTHROPIC_AUTH_TOKEN not set"
    exit 1
fi

# 进入工作目录
cd /workspace

# 初始化 git 配置（使用 AGENT_ID）
GIT_USER_NAME="${AGENT_ID:-worker}"
GIT_USER_EMAIL="${GIT_USER_NAME}@noreply.localhost"
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# 动态生成 MCP 配置文件
mkdir -p /root/.claude /root/.config/claude-code /home/claude-user/.claude
cat > /root/.claude/mcp.json <<EOF
{
  "mcpServers": {
    "tavily": {
      "command": "npx",
      "args": ["-y", "tavily-mcp"],
      "env": {
        "TAVILY_API_KEY": "${TAVILY_API_KEY:-}"
      }
    },
    "forgejo": {
      "command": "npx",
      "args": ["-y", "@openmanbo/forgejo-mcp"],
      "env": {
        "FORGEJO_URL": "$FORGEJO_URL",
        "FORGEJO_TOKEN": "$FORGEJO_TOKEN"
      }
    },
    "lsp": {
      "command": "npx",
      "args": ["-y", "lsp-mcp-server"]
    }
  }
}
EOF

# 复制 MCP 配置到 claude-code settings 和 claude-user 目录
cp /root/.claude/mcp.json /root/.config/claude-code/settings.json
cp /root/.claude/mcp.json /home/claude-user/.claude/mcp.json
chown claude-user:claude-user /home/claude-user/.claude/mcp.json

# 输出启动信息
echo ""
echo "Forgejo URL: $FORGEJO_URL"
echo "Agent ID: $AGENT_ID"
echo "Git User: $GIT_USER_NAME <$GIT_USER_EMAIL>"
echo "Agent Role: worker"
echo "Mode: automatic"
echo "MCP Config: /root/.claude/mcp.json"
echo ""
echo "Starting main loop... Checking for tasks every 60 seconds."
echo ""

while true; do
    echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Checking for tasks ==="

    # 切换到 claude-user 用户运行 claude，使用 --dangerously-skip-permissions
    su - claude-user -c "
export ANTHROPIC_AUTH_TOKEN='${ANTHROPIC_AUTH_TOKEN}'
export ANTHROPIC_BASE_URL='${ANTHROPIC_BASE_URL:-}'
export ANTHROPIC_MODEL='${ANTHROPIC_MODEL:-}'
cd /workspace && \
claude --mcp-config /home/claude-user/.claude/mcp.json --dangerously-skip-permissions -p '
你是 $AGENT_ID，Worker Agent。

**首次启动任务**：
1. 检查 ORGANIZATION.md 是否存在
2. 如果存在且没有你的 Agent ID，在评论中登记身份
3. 如果不存在，等待 Manager 创建

**日常工作**：
请检查 Forgejo 上：
1. 分配给你的 Issue（assigned=true）
2. 标记为 ready 的 Issue
3. 标记为 review-needed 的 PR

如果有可领取或正在进行的任务：
- 领取任务（评论并 assign 给自己）
- 开始开发
- 创建功能分支并编写代码
- 完成后创建 PR

如果有需要审查的 PR：
- 审查代码并提供反馈
- 批准或请求修改

如果 PR 审查通过且标记为 merge-ready：
- 合并 PR
- 删除功能分支
- 更新 Issue 状态

执行完毕后，输出处理结果摘要。
'
"

    echo ""
    echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Sleep 60 seconds ==="
    echo ""

    sleep 60
done
