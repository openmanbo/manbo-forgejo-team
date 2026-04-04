---
name: forgejo
description: Forgejo MCP 工具使用指南，涵盖认证、工具分类、使用场景和最佳实践
---

## 概述

Forgejo 是一个轻量级自托管软件协作平台（类似 GitHub/GitLab），支持代码托管、Issue 跟踪、Pull Request、代码审查等功能。

Forgejo MCP 提供与 Forgejo 实例交互的能力，支持 Issues、Pull Requests、Reviews、Notifications 等完整工作流。

---

## 获取 Git Remote 配置

使用 `get_git_token` 工具获取 URL 和 Token，用于 git 操作：

```bash
get_git_token
```

返回：
```json
{
  "url": "https://<forgejo-host>",
  "token": "<access-token>"
}
```

---

## 工具分类

### 用户相关

| 工具 | 说明 |
|------|------|
| `get_git_token` | 获取 Git 认证所需的 URL 和 Token |

### 搜索与发现

| 工具 | 说明 |
|------|------|
| `search_issues` | 跨仓库搜索 Issues/PRs，支持 assigned、mentioned、review_requested 等过滤 |
| `search_repos` | 搜索仓库 |

### 仓库相关

| 工具 | 说明 |
|------|------|
| `get_repo` | 获取仓库详细信息 |

### Issue 管理

| 工具 | 说明 |
|------|------|
| `list_issues` | 列出指定仓库的 Issues |
| `get_issue` | 获取单个 Issue/PR 详情 |
| `create_issue` | 创建新 Issue |
| `edit_issue` | 编辑 Issue（标题、内容、状态、分配人等） |
| `list_issue_comments` | 查看 Issue/PR 评论 |
| `create_comment` | 发表评论 |

### Pull Request 管理

| 工具 | 说明 |
|------|------|
| `list_pull_requests` | 列出仓库的 PRs |
| `get_pull_request` | 获取单个 PR 详情（包括合并状态、是否冲突） |
| `create_pull_request` | 创建新 PR |
| `edit_pull_request` | 编辑 PR（标题、内容、状态、分支等） |
| `merge_pull_request` | 合并 PR（支持 merge/squash/rebase） |
| `get_pull_request_diff` | 获取 PR 的 diff |
| `get_pull_request_files` | 获取 PR 修改的文件列表 |
| `update_pull_request_branch` | 更新 PR 分支与 base 分支同步 |

### PR Review 相关

| 工具 | 说明 |
|------|------|
| `list_pull_request_reviews` | 列出 PR 的所有评审 |
| `get_pull_request_review` | 获取单个评审详情 |
| `get_pull_request_review_comments` | 获取评审的行级评论 |
| `create_pull_request_review` | 创建评审（APPROVED/REQUEST_CHANGES/COMMENT/PENDING） |
| `submit_pull_request_review` | 提交待处理的评审 |
| `delete_pull_request_review` | 删除评审 |
| `dismiss_pull_request_review` | 撤销评审 |

### 通知管理

| 工具 | 说明 |
|------|------|
| `list_notifications` | 列出未读通知 |
| `mark_notification_read` | 标记单个通知为已读 |
| `mark_all_notifications_read` | 标记所有通知为已读 |

---

## Forgejo 协作工作流

### 1. Issue 跟踪

**创建 Issue**
- 描述问题或需求
- 使用标签（labels）分类
- 分配给相关成员（assignees）
- 关联到里程碑（milestone）

**处理 Issue**
- 评论讨论
- 更新状态（open/closed）
- 跟踪进度

### 2. Pull Request 工作流

**贡献代码流程：**
```
1. Fork 仓库（或使用同一仓库）
2. 创建功能分支（git checkout -b feature/my-feature）
3. 提交代码（git commit）
4. 推送分支（git push origin feature/my-feature）
5. 创建 Pull Request
6. 等待代码审查
7. 根据反馈修改
8. 合并到主分支
```

**PR 审查流程：**
- 查看代码变更（diff）
- 阅读修改的文件
- 添加行级评论
- 提交评审意见（Approve/Request Changes/Comment）

### 3. 代码审查

**审查要点：**
- 代码正确性
- 代码风格和一致性
- 是否解决了对应 Issue
- 是否有适当的测试
- 是否有文档更新

**评审操作：**
- `APPROVED` - 批准合并
- `REQUEST_CHANGES` - 请求修改
- `COMMENT` - 仅评论
- `PENDING` - 暂存评审（稍后提交）

### 4. 通知与协作

**通知类型：**
- @ 提及（Mentions）
- Issue/PR 分配
- 审查请求
- 评论回复

---

## 个人工作流（处理和自己有关的工作）

### 查找我的任务

```bash
# 分配给我的 Issues
search_issues assigned=true type=issues state=open

# 请求我审查的 PRs
search_issues review_requested=true type=pulls

# 提及我的 Issues/PRs
search_issues mentioned=true

# 我创建的 Issues
search_issues created=true
```

### 处理通知

1. **查看未读通知**
   ```bash
   list_notifications  # 查看所有未读通知
   ```

2. **处理每个通知**
   - 读取 `get_issue` 或 `get_pull_request` 获取详情
   - 读取 `list_issue_comments` 查看最新讨论
   - 根据通知类型采取行动：
     - **分配任务** → 开始处理或创建子任务
     - **审查请求** → 查看代码并提交评审
     - **@提及** → 回复评论

3. **标记已读**
   ```bash
   mark_notification_read id=<通知 ID>
   # 或批量标记
   mark_all_notifications_read
   ```

### 每日工作检查清单

1. [ ] 检查未读通知 (`list_notifications`)
2. [ ] 查看分配给我的 Issues (`search_issues assigned=true`)
3. [ ] 查看请求审查的 PRs (`search_issues review_requested=true`)
4. [ ] 处理通知和评论
5. [ ] 更新正在进行的工作状态

---

## 使用场景

### Triage 工作流

1. `list_notifications` 获取新通知
2. `get_issue` 或 `get_pull_request` 查看详情
3. `list_issue_comments` 阅读讨论
4. `create_comment` 参与讨论或分配任务

### 代码审查工作流

1. `search_issues` (type=pulls, review_requested=true) 查找请求审查的 PR
2. `get_pull_request` 获取 PR 详情
3. `get_pull_request_diff` 查看代码变更
4. `get_pull_request_files` 查看修改的文件
5. `list_pull_request_reviews` 查看已有评审
6. `create_pull_request_review` 提交评审意见

### 合并 PR 工作流

**重要：合并前必须检查 PR 状态！**

1. **检查 PR 详情**
   ```bash
   get_pull_request number=<PR 号> owner=<所有者> repo=<仓库名>
   ```
   关键字段：
   - `mergeable` - 是否可以合并（true/false）
   - `merged` - 是否已合并
   - `state` - PR 状态（open/closed）
   - `merge_base` - 合并基准

2. **判断是否可合并**
   - `mergeable: true` → 可以合并
   - `mergeable: false` → 存在冲突，需要先更新分支
   - `merged: true` → 已合并，无需操作
   - `state: closed` → 已关闭，无法合并

3. **处理冲突**（如果不可合并）
   ```bash
   update_pull_request_branch number=<PR 号>
   ```
   然后重新检查 `get_pull_request` 直到 `mergeable: true`

4. **执行合并**
   ```bash
   merge_pull_request number=<PR 号> merge_style=merge
   ```
   merge_style 可选：`merge` / `squash` / `rebase`

5. **验证合并结果**
   ```bash
   get_pull_request number=<PR 号>  # 确认 merged: true
   ```

### 贡献代码工作流

1. `search_issues` (assigned=true) 查找分配给自己的 issue
2. `get_issue` 了解需求
3. 本地开发并提交代码
4. `create_pull_request` 创建 PR
5. 根据评审意见更新代码
6. **等待审查和合并**（由审查方执行合并，不是 PR 作者）
   - 审查方批准 PR 后，由审查方或 Manager 执行 `merge_pull_request`
   - PR 作者不应自己合并自己的 PR

---

## 最佳实践

1. **Git 操作**：使用 `get_git_token` 获取 token 用于 git clone/push
2. **精准搜索**：使用 `search_issues` 的过滤器（assigned、mentioned、review_requested）缩小范围
3. **分页处理**：列表工具支持 `page` 和 `limit` 参数，注意结果截断
4. **状态追踪**：使用 `mark_notification_read` 标记已处理的通知
5. **合并前检查**：使用 `get_pull_request` 检查 `mergeable` 字段，确认无冲突后再合并

---
