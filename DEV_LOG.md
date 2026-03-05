# PawChat Android - 开发日志

记录重要决策、进展和待办事项。

---

## 2026-03-05 - v1.1 开发启动

### 完成功能

#### ✅ 自动重连机制

**实现内容**:
- 创建 `ReconnectManager` 类
- 指数退避策略 (1s, 2s, 4s, 8s, 16s, 30s...)
- 最大重连次数限制 (10 次)
- 重连状态回调
- 集成到 `ChatBloc`
- 创建 `ReconnectIndicator` UI 组件
- 网络状态指示器 (AppBar)

**技术细节**:
- 保存连接参数 (URL, Token) 用于重连
- WebSocket 错误/关闭时自动触发重连
- 用户手动断开时禁用自动重连
- 重连成功后自动加载会话历史

**文件变更**:
- ✨ `lib/core/websocket/reconnect_manager.dart` (新增)
- ✨ `lib/features/chat/presentation/reconnect_indicator.dart` (新增)
- 📝 `lib/features/chat/bloc/chat_bloc.dart` (集成重连)
- 📝 `lib/features/chat/presentation/chat_screen.dart` (UI 集成)

**测试要点**:
- [ ] 网络切换时自动重连
- [ ] Gateway 重启后自动重连
- [ ] 重连失败达到最大次数后的处理
- [ ] 重连过程中的 UI 状态显示

#### ✅ 消息搜索功能

**实现内容**:
- 创建 `MessageSearchService` 搜索服务
- 关键词匹配 (不区分大小写)
- 上下文预览 (前后 50 字符)
- 创建 `SearchScreen` 搜索页面
- 搜索结果高亮显示
- 集成到主界面 (AppBar 搜索按钮)

**技术细节**:
- 搜索所有会话或指定会话
- 限制最大返回结果数 (50 条)
- 显示消息时间、角色、上下文
- 支持点击跳转到对应会话 (TODO)

**文件变更**:
- ✨ `lib/features/search/service/message_search_service.dart` (新增)
- ✨ `lib/features/search/search_screen.dart` (新增)
- 📝 `lib/app/routes.dart` (添加搜索路由)
- 📝 `lib/features/chat/presentation/chat_screen.dart` (添加搜索按钮)

**测试要点**:
- [ ] 搜索中文/英文关键词
- [ ] 搜索长消息中的片段
- [ ] 空结果处理
- [ ] 搜索结果跳转功能

#### ✅ 附件上传功能

**实现内容**:
- 创建 `AttachmentUploadService` 附件服务
- 创建 `AttachmentPicker` 选择器 (相册/相机)
- 文件类型检测 (图片/视频/音频/文档)
- 文件大小限制 (20MB)
- 附件预览组件
- 集成到消息输入框
- 添加 `image_picker` 依赖

**技术细节**:
- 支持格式：JPG, PNG, GIF, WebP, MP4, MP3, PDF, DOCX 等
- 自动压缩图片 (1920x1080, 85% 质量)
- 附件预览 (缩略图/图标)
- 多附件支持 (水平滚动预览)
- Gateway 上传接口待实现 (模拟上传)

**文件变更**:
- ✨ `lib/core/attachments/attachment_service.dart` (新增)
- ✨ `lib/core/attachments/attachment_picker.dart` (新增)
- 📝 `lib/features/chat/presentation/message_input.dart` (附件支持)
- 📝 `pubspec.yaml` (添加 image_picker)

**测试要点**:
- [ ] 从相册选择图片
- [ ] 拍照上传
- [ ] 大文件限制
- [ ] 多附件预览
- [ ] Gateway 上传集成 (待实现)

#### ✅ 推送通知功能

**实现内容**:
- 创建 `NotificationService` 通知服务
- 创建 `MessageNotificationListener` 消息监听器
- Android 通知渠道配置
- iOS 通知权限配置
- 智能通知 (后台/非当前会话)
- 通知点击跳转 (待实现)
- 集成到 main.dart 初始化

**技术细节**:
- 使用 `flutter_local_notifications` 包
- Android 13+ 权限请求
- 高优先级通知 (声音/震动/灯光)
- 消息内容截断预览 (100 字符)
- 应用在前台时不显示通知
- 当前会话消息不显示通知

**文件变更**:
- ✨ `lib/core/notifications/notification_service.dart` (新增)
- ✨ `lib/core/notifications/message_notification_listener.dart` (新增)
- 📝 `lib/main.dart` (初始化通知服务)
- 📝 `pubspec.yaml` (添加 flutter_local_notifications)

**测试要点**:
- [ ] Android 通知权限请求
- [ ] 后台收到新消息通知
- [ ] 通知点击跳转
- [ ] 当前会话不重复通知
- [ ] 通知渠道设置

---

## v1.1 完成总结

**完成功能**: 4/4 (100%)
- ✅ 自动重连
- ✅ 消息搜索
- ✅ 附件上传
- ✅ 推送通知

**新增文件**: 10 个
**修改文件**: 8 个
**新增依赖**: 2 个 (image_picker, flutter_local_notifications)

---

## 2026-03-05 - v1.0 发布

### 完成功能

- ✅ WebSocket 连接/认证
- ✅ 消息收发 (流式响应)
- ✅ 多会话管理
- ✅ 消息缓存
- ✅ 设置持久化
- ✅ 深色主题
- ✅ 路由系统
- ✅ 工具扩展方法
- ✅ 下拉刷新加载历史

### 项目统计

- **总功能数**: 104
- **已完成**: 52 (50%)
- **进行中**: 0
- **计划中**: 52

---

## 下一步计划

### v1.1 剩余功能

1. **消息搜索** - 关键词搜索历史消息
2. **附件上传** - 图片/文件上传支持
3. **推送通知** - 消息通知

### v2.0 Vision

- 语音输入
- 端到端加密
- 多账号支持
- iOS 版本

---

_维护者：爪爪 🐾_
_最后更新：2026-03-05_
