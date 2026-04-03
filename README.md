# manbo-forgejo-team

Manbo Agents 运行在 Docker 容器中，通过 Forgejo MCP 进行协作开发。

## 架构

- **Manager Agent**: 分析 Issue、分解任务、分配工作（1 份）
- **Worker Agent**: 开发 + 审查 + 测试执行（多份并发）

**多账号设计**：每个 Agent 使用独立的 Forgejo 账号，通过 @mention 和 assign 机制协作。

## Quick Start

### 1. 准备环境

```sh
# 安装依赖
npm install -g @anthropic-ai/claude-code

# 复制环境变量
cp .env.example .env
```

### 2. 配置环境变量

编辑 `.env` 文件，为每个 Agent 配置独立的账号：

```bash
# Forgejo 实例地址
FORGEJO_URL=https://your-forgejo-instance.com

# Manager Agent 配置
MANAGER_FORGEJO_TOKEN=<manager-bot-token>
MANAGER_ANTHROPIC_AUTH_TOKEN=<anthropic-token>

# Worker 1 配置
WORKER_1_FORGEJO_TOKEN=<worker-1-bot-token>
WORKER_1_ANTHROPIC_AUTH_TOKEN=<anthropic-token>

# Worker 2 配置
WORKER_2_FORGEJO_TOKEN=<worker-2-bot-token>
WORKER_2_ANTHROPIC_AUTH_TOKEN=<anthropic-token>

# Worker 3 配置
WORKER_3_FORGEJO_TOKEN=<worker-3-bot-token>
WORKER_3_ANTHROPIC_AUTH_TOKEN=<anthropic-token>

# 可选配置
ANTHROPIC_BASE_URL=
ANTHROPIC_MODEL=
```

**注意**：每个 `*_FORGEJO_TOKEN` 必须是不同 Forgejo 账号的访问令牌。

### 3. 生成 Forgejo Tokens

你需要为每个 Agent 创建独立的 Forgejo 账号并生成 Token：

1. 创建 4 个 Forgejo 账号（例如：`manager-bot`、`worker-1-bot`、`worker-2-bot`、`worker-3-bot`）
2. 对每个账号，访问 `<forgejo-url>/user/settings/applications`
3. 创建个人访问令牌（至少需要 `read:issue`, `write:issue`, `read:repository`, `write:repository` 权限）
4. 将 4 个 Token 分别填入 `.env` 文件

### 4. 启动 Agent Team

```sh
cd docker
docker compose build
docker compose up -d
```

### 5. 查看日志

```sh
docker compose logs -f manager
docker compose logs -f worker-1
```

### 6. 停止服务

```sh
docker compose down
```

## 目录结构

```
manbo-forgejo-team/
├── docker/
│   ├── Dockerfile.base          # 基础镜像
│   └── docker-compose.yml       # 多容器编排
├── agents/
│   ├── manager/
│   │   ├── CLAUDE.md            # Manager 角色定义
│   │   └── entrypoint.sh        # 启动脚本
│   ├── worker/
│   │   ├── CLAUDE.md            # Worker 角色定义
│   │   └── entrypoint.sh        # 启动脚本
│   └── PROTOCOL.md              # 协作协议
├── workspace/                    # 各 Agent 工作目录（运行后自动生成）
├── .env                          # 环境变量
├── .env.example                  # 环境变量示例
├── .mcp.json                     # MCP 配置
└── README.md                     # 本文件
```

## 协作流程

1. 用户在 Forgejo 创建 Issue，添加 `needs-triage` 标签
2. Manager Agent 检测到新 Issue，分析并分解为子任务
3. Worker Agents 领取任务（状态变为 `in-progress`）
4. Worker 开发完成，创建 PR（状态变为 `review-needed`）
5. 审查通过后合并，任务完成（状态变为 `done`）

## 标签说明

| 标签 | 含义 |
|------|------|
| `needs-triage` | 待分析 |
| `ready` | 可领取 |
| `in-progress` | 进行中 |
| `review-needed` | 待审查 |
| `blocked` | 已阻塞 |
| `done` | 已完成 |

## 运行模式

Agent 以**完全自动模式**运行：
- 启动后自动检查 Forgejo 任务
- 每 60 秒循环检查一次
- 自动执行任务并更新状态
- 日志输出到 stdout

### 查看日志

```sh
# 查看所有容器日志
docker compose logs -f

# 查看特定 Agent 日志
docker compose logs -f manager
docker compose logs -f worker-1
```

### 调整检查频率

修改 `agents/*/entrypoint.sh` 中的 `sleep 60` 值（单位：秒）

## 调整 Worker 数量

编辑 `docker/docker-compose.yml`，添加或删除 `worker-N` 服务：

```yaml
worker-4:
  build:
    context: ..
    dockerfile: docker/Dockerfile.base
  container_name: manbo-worker-4
  environment:
    - FORGEJO_URL=${FORGEJO_URL}
    - FORGEJO_TOKEN=${WORKER_4_FORGEJO_TOKEN}
    - ANTHROPIC_AUTH_TOKEN=${WORKER_4_ANTHROPIC_AUTH_TOKEN}
    - AGENT_ID=worker-4
  volumes:
    - ../workspace/worker-4:/workspace
    - ../agents/worker:/agents/worker:ro
  entrypoint: /agents/worker/entrypoint.sh
```

然后在 `.env` 中添加 `WORKER_4_*` 配置。

## 本地调试

如果想在本地运行单个 Agent（不使用 Docker）：

```sh
export $(grep -v '^#' .env | xargs)
export FORGEJO_TOKEN=$MANAGER_FORGEJO_TOKEN
export ANTHROPIC_AUTH_TOKEN=$MANAGER_ANTHROPIC_AUTH_TOKEN
claude -p "检查 Forgejo 上的 Issue"
```

## 故障排除

### 容器无法启动

检查环境变量是否正确配置：
```sh
docker compose config
```

### Agent 无法连接 Forgejo

检查 `FORGEJO_URL` 和 `FORGEJO_TOKEN` 是否正确。

### 查看容器状态

```sh
docker compose ps
```

### MCP 配置

MCP 配置在 `.mcp.json` 中，Forgejo MCP 会自动读取容器的 `FORGEJO_URL` 和 `FORGEJO_TOKEN` 环境变量。

## License

MIT
