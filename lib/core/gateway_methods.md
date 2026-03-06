# GatewayClient 方法列表

总计: 41 个公共方法

## 聊天 (Chat)
- `sendMessage(content, {sessionKey})` - 发送消息
- `abort()` - 中止响应
- `getChatHistory({sessionKey, limit})` - 获取历史

## 会话 (Sessions)
- `getSessions({limit})` - 获取会话列表
- `resetSession(sessionKey)` - 重置会话
- `deleteSession(sessionKey)` - 删除会话
- `patchSession(sessionKey, {title})` - 修改会话

## 系统状态 (System)
- `getHealth()` - 获取健康状态
- `getStatus()` - 获取状态

## 配置 (Config)
- `getConfig()` - 获取配置
- `setConfig(path, value)` - 设置配置
- `applyConfig()` - 应用配置

## 模型和代理 (Models & Agents)
- `getModels()` - 获取模型列表
- `getAgents()` - 获取代理列表
- `getAgentIdentity(agentId)` - 获取代理身份
- `getAgentFiles(agentId)` - 获取代理文件列表
- `getAgentFile(agentId, path)` - 获取代理文件
- `setAgentFile(agentId, path, content)` - 设置代理文件

## 节点 (Nodes)
- `getNodes()` - 获取节点列表

## 渠道 (Channels)
- `getChannelsStatus()` - 获取渠道状态
- `channelsLogout(channelId)` - 渠道登出

## 工具 (Tools)
- `getToolsCatalog()` - 获取工具目录

## Skills
- `getSkillsStatus()` - 获取 Skills 状态
- `installSkill(skillId, {version})` - 安装 Skill
- `updateSkill(skillId, {version})` - 更新 Skill

## 使用统计 (Usage)
- `getUsageCost()` - 获取使用成本
- `getSessionsUsage()` - 获取会话使用情况
- `getSessionsUsageLogs({limit})` - 获取使用日志
- `getSessionsUsageTimeseries()` - 获取使用统计

## 定时任务 (Cron)
- `getCronList()` - 获取定时任务列表
- `getCronStatus()` - 获取定时任务状态
- `addCronJob(params)` - 添加定时任务
- `removeCronJob(jobId)` - 删除定时任务
- `runCronJob(jobId)` - 运行定时任务
- `getCronRuns()` - 获取运行历史
- `updateCronJob(jobId, params)` - 更新定时任务

## 日志 (Logs)
- `getLogsTail({lines})` - 获取日志尾部

## 设备 (Device)
- `getDevicePairList()` - 获取设备配对列表
- `approveDevicePair(requestId)` - 批准设备配对
- `rejectDevicePair(requestId)` - 拒绝设备配对
- `rotateDeviceToken(deviceId)` - 轮换设备令牌
- `revokeDeviceToken(deviceId)` - 撤销设备令牌

## 执行批准 (Exec)
- `resolveExecApproval(id, decision, {reason})` - 执行批准决议

## Web 登录
- `webLoginStart(channel, userId)` - Web 登录开始
- `webLoginWait(requestId)` - Web 登录等待

## 更新 (Update)
- `runUpdate()` - 运行更新
