# ⚠️ GitHub Token 认证问题

**时间**: 2026-03-05 15:55

---

## 🔍 问题诊断

### Token 测试结果

❌ **Token 无法通过 API 认证**

```bash
curl -H "Authorization: token ghp_..." https://api.github.com/user
# 返回空或错误
```

**可能原因**:
1. Token 已失效/被撤销
2. Token 权限不足
3. Token 格式错误
4. GitHub API 限流

---

## ✅ 本地状态

| 项目 | 状态 |
|------|------|
| Git 仓库 | ✅ 已初始化 |
| 代码提交 | ✅ 已完成 |
| 远程 origin | ❌ 未配置/无效 |
| gh CLI 认证 | ❌ 失败 |

---

## 🔧 解决方案

### 方案 1: 重新创建 Token (推荐)

**1. 访问**: https://github.com/settings/tokens

**2. 删除旧 Token** (如果存在)

**3. 创建新 Token**:
- 点击 **Generate new token (classic)**
- **Note**: `pawchat-android-20260305`
- **Expiration**: `No expiration`
- **Select scopes**: ✅ 勾选 **`repo`** (全部权限)
- 点击 **Generate token**
- **复制新 Token** (以 `ghp_` 开头)

**4. 测试新 Token**:

```bash
# 替换 NEW_TOKEN 为新 Token
curl -H "Authorization: token NEW_TOKEN" https://api.github.com/user
# 应该返回用户信息
```

**5. 认证 gh CLI**:

```bash
echo "NEW_TOKEN" | gh auth login --with-token
```

**6. 推送代码**:

```bash
cd ~/.openclaw/workspace/pawchat-android
git remote add origin https://github.com/xsj/pawchat-android.git
git push -u origin main
```

---

### 方案 2: 使用 HTTPS 推送 (无需 gh CLI)

**1. 在 GitHub 创建仓库**:
- 访问 https://github.com/new
- 创建 `pawchat-android`
- 不要初始化

**2. 推送代码**:

```bash
cd ~/.openclaw/workspace/pawchat-android

# 添加远程
git remote add origin https://github.com/xsj/pawchat-android.git

# 推送 (会提示输入用户名和密码)
git push -u origin main
```

**输入**:
- Username: `xsj`
- Password: [Personal Access Token](file:///home/xsj/.openclaw/workspace/pawchat-android/android/app/src/main/java/com/pawchat/app/MainActivity.java) (不是登录密码！)

---

### 方案 3: 使用 SSH (推荐长期)

**1. 生成 SSH Key**:

```bash
ssh-keygen -t ed25519 -C "xsj@localhost"
```

**2. 添加 SSH Key 到 GitHub**:
- 复制公钥：`cat ~/.ssh/id_ed25519.pub`
- 访问 https://github.com/settings/keys
- 点击 **New SSH key**
- 粘贴公钥

**3. 使用 SSH 推送**:

```bash
cd ~/.openclaw/workspace/pawchat-android
git remote add origin git@github.com:xsj/pawchat-android.git
git push -u origin main
```

---

## 📋 验证步骤

**创建新 Token 后**:

```bash
# 1. 测试 Token
curl -H "Authorization: token ghp_xxx" https://api.github.com/user
# 应该看到 {"login":"xsj",...}

# 2. 认证 gh
echo "ghp_xxx" | gh auth login --with-token

# 3. 检查状态
gh auth status

# 4. 创建仓库
gh repo create xsj/pawchat-android --public --source=. --remote=origin --push

# 5. 查看构建
gh run list --repo xsj/pawchat-android
```

---

## 🌐 手动方案 (无需 Token)

**1. 网页创建仓库**:
```
https://github.com/new
→ pawchat-android
→ Create repository
```

**2. 复制推送命令**:
```bash
git remote add origin https://github.com/xsj/pawchat-android.git
git push -u origin main
```

**3. 输入 Token 推送**:
- Username: `xsj`
- Password: [Personal Access Token](file:///home/xsj/.openclaw/workspace/pawchat-android/android/app/src/main/java/com/pawchat/app/MainActivity.java)

---

## 🎯 下一步

**请选择**:

1. **重新创建 Token** → 告诉我新 Token，我帮你推送
2. **手动网页操作** → 访问 https://github.com/new 创建仓库
3. **使用 SSH** → 我帮你配置 SSH key

---

*Token 可能已失效，需要重新创建！🐾*
