# Agent Team 协作协议

## 多账号架构

每个 Agent 运行在独立的 Docker 容器中，使用**不同的 Forgejo 账号**：

| Agent | 环境变量 | 说明 |
|-------|----------|------|
| Manager | `MANAGER_FORGEJO_TOKEN` | Manager -bot 账号 |
| Worker-1 | `WORKER_1_FORGEJO_TOKEN` | Worker-1-bot 账号 |
| Worker-2 | `WORKER_2_FORGEJO_TOKEN` | Worker-2-bot 账号 |
| Worker-3 | `WORKER_3_FORGEJO_TOKEN` | Worker-3-bot 账号 |

**协作方式**：
- 通过 Forgejo 的 **@mention** 机制互相通知
- 通过 **assign** 机制分配任务
- 通过 **Issue 评论** 进行异步沟通

## Issue 标签规范

### 状态标签

| 标签 | 含义 | 由谁设置 | 说明 |
|------|------|----------|------|
| `needs-triage` | 待分析 | 创建者 / Manager | 新 Issue，等待 Manager 分解任务 |
| `ready` | 可领取 | Manager | 任务已分解，等待 Worker 领取 |
| `in-progress` | 进行中 | Worker | Worker 已开始工作的任务 |
| `review-needed` | 待审查 | Worker | PR 已创建，等待审查 |
| `blocked` | 已阻塞 | Worker / Manager | 依赖其他任务，暂时无法继续 |
| `done` | 已完成 | Manager / Worker | PR 已合并，任务完成 |

### 类型标签

| 标签 | 含义 |
|------|------|
| `feature` | 新功能开发 |
| `bug` | Bug 修复 |
| `refactor` | 代码重构 |
| `test` | 测试相关 |
| `docs` | 文档更新 |
| `review` | 代码审查任务 |

## 任务分配机制

### Manager 分配流程

1. Manager 检测到 `needs-triage` 标签的 Issue
2. 分析 Issue，分解为子任务
3. 为每个子任务设置：
   - 清晰的标题和描述
   - 类型标签（`feature`/`bug` 等）
   - `ready` 状态标签
4. （可选）直接分配给特定 Worker

### Worker 领取流程

1. Worker 搜索 `label=ready` 的 Issue
2. 确认无阻塞依赖
3. 在 Issue 中评论"开始工作"
4. 将状态改为 `in-progress`
5. 开始开发

### 并发控制

- **Assign 机制**：每个 Issue/子任务只能有一个 assignee，Forgejo 天然防止多账号同时领取
- **状态检查**：Worker 只领取 `label=ready` 且 `assignee` 为空或 assignee 是自己的任务
- **评论通知**：开始/完成任务时在 Issue 中评论更新，使用 @mention 通知相关 Agent
- **跨账号通信**：
  - Manager 分配任务时使用 `@worker-1` 等 @mention 通知
  - Worker 请求帮助时使用 `@manager` 或 `@worker-X` @mention

## 状态流转规则

```
needs-triage ──(Manager 分析)──> ready
     │                              │
     │                              │ (Worker 领取)
     │                              ▼
     │                          in-progress
     │                              │
     │                              │ (完成开发，创建 PR)
     │                              ▼
     └──────────────────────> review-needed
                                    │
                                    │ (审查通过，合并)
                                    ▼
                                 done

任何状态 ──(遇到阻塞)──> blocked
blocked ──(阻塞解除)──> 原状态
```

## Forgejo Issue 模板

### 功能开发 Issue

```markdown
## 目标

[描述功能目标]

## 需求

- [ ] 需求点 1
- [ ] 需求点 2

## 技术要点

- 涉及的模块/文件
- 需要注意的地方

## 验收标准

- [ ] 功能正常工作
- [ ] 测试通过
- [ ] 代码审查通过
```

### Bug 修复 Issue

```markdown
## 问题描述

[描述 Bug 现象]

## 复现步骤

1. ...
2. ...

## 预期行为

[描述预期结果]

## 修复方案

[描述修复思路]

## 验收标准

- [ ] Bug 修复
- [ ] 不引入回归
- [ ] 测试通过
```

## 通信规范

### Issue 评论模板

**开始工作时：**
```
开始工作此任务。预计完成时间：[时间]
```

**进度更新：**
```
进度更新：[完成的内容]。遇到 [问题]，正在 [解决方案]。
```

**完成任务：**
```
任务完成。已创建 PR #xxx。
```

**请求帮助：**
```
需要帮助：[具体问题]。[@mention Manager 或其他 Worker]
```

## 紧急处理

如果 Manager 不在或无响应：
- Worker 可自发领取 `ready` 任务
- 复杂问题由 Worker 协商分工
- 争议问题在 Issue 中评论讨论
