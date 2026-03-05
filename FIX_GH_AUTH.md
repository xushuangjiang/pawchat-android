# 🔧 修复 GitHub CLI 认证

**问题**: gh CLI 未正确认证，无法通过 API 获取构建状态

---

## 🔍 当前状态

- ✅ 仓库已创建：https://github.com/xsj/pawchat-android
- ✅ 代码已推送
- ⚠️ gh CLI 未认证

---

## 🔑 修复方案

### 方案 1: 手动认证 (推荐)

```bash
# 运行登录命令
gh auth login

# 按提示操作:
# 1. 选择 GitHub.com
# 2. 选择 HTTPS
# 3. 选择 Yes (认证 Git)
# 4. 复制 One-Time Code
# 5. 访问 https://github.com/login/device
# 6. 输入代码
# 7. 授权
```

---

### 方案 2: 使用 Personal Access Token

**1. 创建 Token**

访问 https://github.com/settings/tokens

点击 **Generate new token (classic)**

填写:
- **Note**: `pawchat-android-cli`
- **Expiration**: No expiration
- **Select scopes**: 勾选 `repo` (Full control)

点击 **Generate token**

**复制 Token** (只显示一次！)

**2. 使用 Token 登录**

```bash
# 方法 A: 交互式
gh auth login --with-token

# 然后粘贴 Token

# 方法 B: 管道
echo "YOUR_TOKEN_HERE" | gh auth login --with-token
```

---

### 方案 3: 直接使用网页 (无需 gh CLI)

**查看构建**:
```
https://github.com/xsj/pawchat-android/actions
```

**下载 APK** (构建完成后):
1. 访问上述链接
2. 点击最新构建
3. 滚动到底部 Artifacts
4. 下载 `pawchat-apks`

---

## 📊 验证认证

```bash
# 检查认证状态
gh auth status

# 应该看到:
# ✓ Logged in to github.com as YOUR_USERNAME
```

---

## 🚀 认证后使用

```bash
# 查看构建运行
gh run list --repo xsj/pawchat-android

# 查看最新构建详情
gh run view --repo xsj/pawchat-android

# 下载产物
gh run download --repo xsj/pawchat-android --name pawchat-apks

# 实时监控
gh run watch --repo xsj/pawchat-android
```

---

## 🌐 网页版监控

**Actions 页面**:
```
https://github.com/xsj/pawchat-android/actions
```

**仓库主页**:
```
https://github.com/xsj/pawchat-android
```

---

## ⚡ 快速命令

```bash
# 1. 登录
gh auth login

# 2. 验证
gh auth status

# 3. 查看构建
gh run list --repo xsj/pawchat-android

# 4. 监控
gh run watch --repo xsj/pawchat-android
```

---

*选择方案 1 或 2 修复认证，或直接用方案 3 网页查看！🐾*
