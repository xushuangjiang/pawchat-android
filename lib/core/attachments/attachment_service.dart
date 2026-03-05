import 'dart:io';
import 'package:flutter/foundation.dart';

/// 附件类型枚举
enum AttachmentType {
  image,
  file,
  video,
  audio,
}

/// 附件信息
class AttachmentInfo {
  /// 附件类型
  final AttachmentType type;

  /// 文件路径
  final String path;

  /// 文件名
  final String name;

  /// 文件大小 (字节)
  final int size;

  /// MIME 类型
  final String mimeType;

  /// 缩略图路径 (可选，用于图片/视频)
  final String? thumbnailPath;

  /// 宽度 (可选，用于图片/视频)
  final int? width;

  /// 高度 (可选，用于图片/视频)
  final int? height;

  AttachmentInfo({
    required this.type,
    required this.path,
    required this.name,
    required this.size,
    required this.mimeType,
    this.thumbnailPath,
    this.width,
    this.height,
  });

  /// 获取格式化的文件大小
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 从文件创建附件信息
  static Future<AttachmentInfo> fromFile(File file) async {
    final path = file.path;
    final name = file.uri.pathSegments.last;
    final size = await file.length();
    
    // 判断文件类型
    final extension = name.split('.').last.toLowerCase();
    final type = _detectType(extension);
    final mimeType = _getMimeType(extension);

    // 如果是图片，尝试获取尺寸
    int? width, height;
    if (type == AttachmentType.image) {
      // TODO: 使用 image 包获取实际尺寸
      // final image = await decodeImageFromList(await file.readAsBytes());
      // width = image.width;
      // height = image.height;
    }

    return AttachmentInfo(
      type: type,
      path: path,
      name: name,
      size: size,
      mimeType: mimeType,
      width: width,
      height: height,
    );
  }

  /// 根据扩展名判断类型
  static AttachmentType _detectType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
        return AttachmentType.image;
      case 'mp4':
      case 'webm':
      case 'avi':
      case 'mov':
        return AttachmentType.video;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'aac':
        return AttachmentType.audio;
      default:
        return AttachmentType.file;
    }
  }

  /// 获取 MIME 类型
  static String _getMimeType(String extension) {
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'mp4': 'video/mp4',
      'webm': 'video/webm',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'aac': 'audio/aac',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }
}

/// 附件上传服务
class AttachmentUploadService {
  /// 最大文件大小 (默认 20MB)
  final int maxFileSize;

  /// 允许的文件类型
  final List<String> allowedExtensions;

  AttachmentUploadService({
    this.maxFileSize = 20 * 1024 * 1024, // 20MB
    this.allowedExtensions = const [
      // 图片
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg',
      // 文档
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt',
      // 压缩文件
      'zip', 'rar', '7z',
      // 视频
      'mp4', 'webm',
      // 音频
      'mp3', 'wav', 'ogg',
    ],
  });

  /// 验证文件
  ValidationResult validateFile(File file) {
    // 检查文件是否存在
    if (!file.existsSync()) {
      return ValidationResult(
        isValid: false,
        error: '文件不存在',
      );
    }

    final name = file.uri.pathSegments.last;
    final extension = name.split('.').last.toLowerCase();

    // 检查文件扩展名
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult(
        isValid: false,
        error: '不支持的文件类型：.$extension',
      );
    }

    // 检查文件大小
    try {
      final size = file.lengthSync();
      if (size > maxFileSize) {
        return ValidationResult(
          isValid: false,
          error: '文件过大 (${_formatSize(size)}),最大支持 ${_formatSize(maxFileSize)}',
        );
      }
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: '无法读取文件大小',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// 上传附件到 Gateway
  /// 
  /// TODO: 实现实际的上传逻辑
  /// 需要 Gateway 支持文件上传 API
  Future<UploadResult> upload({
    required File file,
    required String sessionKey,
    void Function(double progress)? onProgress,
  }) async {
    // 验证文件
    final validation = validateFile(file);
    if (!validation.isValid) {
      return UploadResult(
        success: false,
        error: validation.error,
      );
    }

    try {
      debugPrint('[AttachmentUpload] 开始上传：${file.path}');
      
      // TODO: 实现实际的上传逻辑
      // 1. 读取文件内容
      // 2. 发送到 Gateway 上传接口
      // 3. 获取文件 URL
      // 4. 发送消息时包含文件 URL
      
      // 模拟上传进度
      for (var i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(i / 100);
      }

      debugPrint('[AttachmentUpload] 上传完成');

      return UploadResult(
        success: true,
        url: 'https://example.com/files/${file.uri.pathSegments.last}',
        fileId: 'file_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('[AttachmentUpload] 上传失败：$e');
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({
    required this.isValid,
    this.error,
  });
}

/// 上传结果
class UploadResult {
  final bool success;
  final String? url;
  final String? fileId;
  final String? error;

  UploadResult({
    required this.success,
    this.url,
    this.fileId,
    this.error,
  });
}
