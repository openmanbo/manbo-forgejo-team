#!/bin/bash
# Manager Agent 启动脚本

set -e

echo "=== Manager Agent Starting ==="

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
GIT_USER_NAME="${AGENT_ID:-manager}"
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

# 创建/读取 Agent 状态文件
AGENT_STATE_FILE="/workspace/.agent_state.json"
if [ ! -f "$AGENT_STATE_FILE" ]; then
    cat > "$AGENT_STATE_FILE" <<EOF
{
  "agent_id": "${AGENT_ID:-manager}",
  "role": "manager",
  "started_at": "$(date -Iseconds)",
  "last_cycle": null,
  "processed_issues": [],
  "processed_prs": [],
  "notes": []
}
EOF
fi
chown claude-user:claude-user "$AGENT_STATE_FILE"

# 输出启动信息
echo ""
echo "Forgejo URL: $FORGEJO_URL"
echo "Agent ID: ${AGENT_ID:-manager}"
echo "Git User: $GIT_USER_NAME <$GIT_USER_EMAIL>"
echo "Agent Role: manager"
echo "Mode: automatic"
echo "MCP Config: /root/.claude/mcp.json"
echo "Agent State: $AGENT_STATE_FILE"
echo ""
echo "Starting main loop... Checking for new issues every 60 seconds."
echo ""

while true; do
    echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Checking for new issues ==="

    # 切换到 claude-user 用户运行 claude，使用 --dangerously-skip-permissions
    su - claude-user -c "
export ANTHROPIC_AUTH_TOKEN='${ANTHROPIC_AUTH_TOKEN}'
export ANTHROPIC_BASE_URL='${ANTHROPIC_BASE_URL:-}'
export ANTHROPIC_MODEL='${ANTHROPIC_MODEL:-}'
cd /workspace && \
claude --mcp-config /home/claude-user/.claude/mcp.json --dangerously-skip-permissions -p '
你是 $AGENT_ID，Manager Agent。

**状态文件**: /workspace/.agent_state.json
- 执行前读取此文件，了解之前的处理历史和上下文
- 执行后更新此文件，记录本次处理的内容

**首次启动任务**：
1. 检查 ORGANIZATION.md 是否存在
2. 如果不存在或包含占位符，创建/更新此文件，登记你的 Agent ID 和用户名
3. 在 Forgejo 上创建一条全局通知或 Issue 评论，声明你的身份

**日常工作**：
请检查 Forgejo 上：
1. 标记为 needs-triage 的 Issue
2. 分配给你的 Issue
3. 标记为 review-needed 的 PR

对于每个需要处理的 Issue：
- 分析需求并分解为子任务
- 在评论中列出子任务
- 添加 ready 标签
- 如有需要，@mention 相关 Worker

对于每个需要审查的 PR：
- 审查代码并提供反馈
- 批准或请求修改
- 审查通过后合并 PR
- 更新关联 Issue 状态

执行完毕后，输出处理结果摘要并更新状态文件。
'
"

    echo ""
    echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Sleep 60 seconds ==="
    echo ""

    sleep 60
done
