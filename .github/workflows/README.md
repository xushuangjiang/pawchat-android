# GitHub Actions 构建状态

## 当前构建

- **工作流**: Build APK
- **Run ID**: 22784673093
- **状态**: 🔄 进行中
- **提交**: f0bfde5

## 查看构建进度

🔗 [点击此处查看实时构建状态](https://github.com/xushuangjiang/pawchat-android/actions/runs/22784673093)

## 构建流程

1. **test** - 运行协议验证和 WebChat 兼容性测试
2. **build** - 构建 release APK
3. **release** - 创建 GitHub Release (仅 tag)

## 下载 APK

构建完成后，APK 文件可在以下位置下载：
- GitHub Actions 页面 → Artifacts
- Release 页面 (如果是 tag 构建)

## 构建输出

- `app-arm64-v8a-release.apk` - ARM64 设备
- `app-armeabi-v7a-release.apk` - ARM32 设备
- `app-x86_64-release.apk` - x86_64 设备
