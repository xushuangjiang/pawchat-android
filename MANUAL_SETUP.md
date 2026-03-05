# 🚀 手动创建 GitHub 仓库

**问题**: gh CLI 未认证，无法自动创建仓库

---

## 📋 手动步骤 (3 分钟)

### 1️⃣ 创建仓库

**访问**: https://github.com/new

**填写**:
- **Owner**: xsj
- **Repository name**: `pawchat-android`
- **Description**: PawChat Android - OpenClaw 客户端
- **Visibility**: ✅ Public 或 Private

**点击**: **Create repository**

---

### 2️⃣ 复制推送命令

创建后会显示:

```bash
git remote add origin https://github.com/xsj/pawchat-android.git
git push -u origin main
```

---

### 3️⃣ 推送代码

```bash
cd ~/.openclaw/workspace/pawchat-android

# 如果已有 origin，先删除
git remote remove origin 2>/dev/null || true

# 添加远程仓库
git remote add origin https://github.com/xsj/pawchat-android.git

# 推送
git push -u origin main
```

**需要认证**:
- 用户名：xsj
- 密码：Personal Access Token

---

## 🔑 获取 Personal Access Token

**访问**: https://github.com/settings/tokens

**步骤**:
1. 点击 **Generate new token (classic)**
2. **Note**: `pawchat-android`
3. **Expiration**: No expiration
4. **Select scopes**: 勾选 ✅ `repo`
5. 点击 **Generate token**
6. **复制 Token** (只显示一次！)

---

## ✅ 验证推送

```bash
# 查看远程仓库
git remote -v

# 应该看到:
# origin  https://github.com/xsj/pawchat-android.git (fetch)
# origin  https://github.com/xsj/pawchat-android.git (push)
```

---

## 📊 触发构建

推送成功后，自动触发 GitHub Actions:

**访问**: https://github.com/xsj/pawchat-android/actions

**看到**: Build APK 工作流正在运行 🟡

---

## ⚡ 一键命令

```bash
cd ~/.openclaw/workspace/pawchat-android

# 1. 创建仓库 (手动在网页操作)
# https://github.com/new

# 2. 添加远程并推送
git remote add origin https://github.com/xsj/pawchat-android.git
git push -u origin main

# 3. 查看构建
# https://github.com/xsj/pawchat-android/actions
```

---

*先在 GitHub 创建仓库，然后运行推送命令！🐾*
