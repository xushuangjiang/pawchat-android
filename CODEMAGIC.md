# 🚀 Codemagic 构建指南

**目标**: 使用 Codemagic 云构建 APK (无需本地 Flutter)  
**适用**: 三星 S24 Ultra (ARM64)  
**费用**: 免费版 (每月 500 分钟构建时间)

---

## 📋 步骤概览

| 步骤 | 时间 | 说明 |
|------|------|------|
| 1. 注册 Codemagic | 2 分钟 | 用 GitHub 登录 |
| 2. 添加项目 | 1 分钟 | 选择 pawchat-android |
| 3. 配置工作流 | 2 分钟 | 使用 codemagic.yaml |
| 4. 触发构建 | 1 分钟 | 推送代码 |
| 5. 等待构建 | 5-10 分钟 | 云端自动构建 |
| 6. 下载 APK | 1 分钟 | 直接下载 |

**总计**: 10-15 分钟

---

## 1️⃣ 注册 Codemagic

**访问**: https://codemagic.io/

**步骤**:
1. 点击 **Get Started for Free**
2. 选择 **Sign in with GitHub**
3. 授权 Codemagic 访问 GitHub
4. 完成注册

---

## 2️⃣ 添加项目

**登录后**:

1. 点击 **Add project**
2. 选择 **pawchat-android** 仓库
3. 点击 **Add project**

---

## 3️⃣ 配置工作流

### 方式 A: 使用 codemagic.yaml (推荐)

项目已包含配置文件：
```
codemagic.yaml
```

Codemagic 会自动检测并使用。

### 方式 B: 手动配置

**Workflow settings**:

| 设置 | 值 |
|------|-----|
| **Build name** | Build APK |
| **Project type** | Flutter |
| **Repository** | pawchat-android |
| **Branch** | main |

**Build settings**:

```yaml
# Environment variables
FLUTTER_VERSION: stable

# Build commands
flutter pub get
flutter analyze
flutter build apk --release --split-per-abi
```

**Artifacts**:
```
build/**/outputs/**/*.apk
```

---

## 4️⃣ 推送代码触发构建

```bash
cd ~/.openclaw/workspace/pawchat-android

# 添加 codemagic.yaml
git add codemagic.yaml
git commit -m "Add codemagic.yaml for CI/CD"
git push origin main
```

Codemagic 会自动检测推送并开始构建！

---

## 5️⃣ 查看构建进度

**访问**:
```
https://codemagic.io/builds
```

**状态**:
- 🟡 Building = 进行中
- 🟢 Success = 成功
- 🔴 Failed = 失败

---

## 6️⃣ 下载 APK

**构建成功后**:

1. 访问 Codemagic Builds 页面
2. 点击最新构建
3. 滚动到 **Artifacts** 部分
4. 下载:
   - `app-arm64-v8a-release.apk` ← **S24 Ultra 用这个**
   - `app-release.apk` (通用版)

---

## 📊 Codemagic vs GitHub Actions

| 特性 | Codemagic | GitHub Actions |
|------|-----------|----------------|
| **Flutter 支持** | ⭐⭐⭐⭐⭐ 原生支持 | ⭐⭐⭐⭐ 需要配置 |
| **构建速度** | ⭐⭐⭐⭐⭐ 快 (M1 Mac) | ⭐⭐⭐⭐ 快 |
| **配置难度** | ⭐⭐⭐⭐⭐ 简单 | ⭐⭐⭐ 中等 |
| **免费额度** | 500 分钟/月 | 2000 分钟/月 |
| **APK 下载** | 直接下载 | Artifacts (30 天) |
| **认证** | GitHub 一键登录 | 需要 Token |

---

## 🎯 快速开始

### 1. 注册并添加项目

```
1. 访问 https://codemagic.io/
2. Sign in with GitHub
3. Add project → pawchat-android
```

### 2. 推送代码

```bash
cd ~/.openclaw/workspace/pawchat-android

# 确保 codemagic.yaml 存在
git add codemagic.yaml
git commit -m "Add codemagic config"
git push origin main
```

### 3. 等待构建

```
访问：https://codemagic.io/builds
等待：5-10 分钟
```

### 4. 下载安装

```
1. 点击最新构建
2. 下载 app-arm64-v8a-release.apk
3. 传到 S24 Ultra 安装
```

---

## 🔧 codemagic.yaml 配置说明

```yaml
name: Build APK
triggering_events:
  - push           # 推送时触发
  - pull_request   # PR 时触发
branch_patterns:
  - pattern: 'main'
    include: true
    source: true

workflows:
  build-apk:
    name: Build APK for S24 Ultra
    max_build_duration: 30    # 最多 30 分钟
    instance_type: mac_mini_m1  # M1 Mac 构建
    
    environment:
      flutter: stable         # Flutter 稳定版
      xcode: latest
      cocoapods: default
    
    scripts:
      - name: Get dependencies
        script: flutter pub get
      
      - name: Analyze code
        script: flutter analyze
      
      - name: Build APK (ARM64)
        script: flutter build apk --release --split-per-abi
    
    artifacts:
      - build/**/outputs/**/*.apk  # 收集 APK
    
    publishing:
      email:
        recipients:
          - your@email.com
        notify:
          success: true
          failure: true
```

---

## 📱 安装到 S24 Ultra

**下载 APK 后**:

```bash
# 方法 1: USB 安装
adb install app-arm64-v8a-release.apk

# 方法 2: 直接传输
# 1. 将 APK 传到手机
# 2. 文件管理器点击安装
# 3. 允许"安装未知应用"
```

---

## ⚡ 优势

### ✅ 为什么选择 Codemagic

1. **无需认证** - GitHub 一键登录
2. **原生 Flutter 支持** - 自动检测 Flutter 项目
3. **构建速度快** - M1 Mac 实例
4. **配置简单** - YAML 文件自动检测
5. **直接下载** - APK 永久保存 (免费版 30 天)
6. **邮件通知** - 构建完成自动通知

---

## 🐛 常见问题

### Q: 构建失败？

**查看日志**:
1. 访问 Codemagic Builds
2. 点击失败的构建
3. 查看详细日志

**常见错误**:
- `pubspec.yaml` 格式错误 → 检查 YAML 缩进
- 依赖冲突 → 本地运行 `flutter pub get` 测试
- 编译错误 → 运行 `flutter analyze` 检查

### Q: 构建太慢？

- 首次构建需要下载依赖 (5-8 分钟)
- 后续构建使用缓存 (2-4 分钟)

### Q: 免费额度用完？

- 每月 500 分钟 (约 8 小时)
- 足够个人项目使用
- 升级计划：$29/月 (1500 分钟)

---

## 📞 总结

**Codemagic 流程**:

```
注册 → 添加项目 → 推送代码 → 自动构建 → 下载 APK
  ↓        ↓          ↓          ↓          ↓
2 分钟   1 分钟     1 分钟    5-10 分钟   1 分钟
```

**总时间**: 10-15 分钟

**优点**: 无需 Token，无需认证，配置简单！

---

*准备好开始了吗？访问 https://codemagic.io/ ！🐾*
