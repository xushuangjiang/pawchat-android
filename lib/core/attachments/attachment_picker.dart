import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'attachment_service.dart';

/// 附件选择器
/// 
/// 提供从相册、相机、文件管理器选择附件的功能
class AttachmentPicker {
  final ImagePicker _picker = ImagePicker();

  /// 选择图片
  Future<AttachmentInfo?> pickImage({
    ImageSource source = ImageSource.gallery,
    bool multiple = false,
  }) async {
    try {
      final XFile? pickedFile;
      
      if (multiple) {
        // TODO: 多选图片 (需要 image_picker 支持)
        pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      } else {
        pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
      }

      if (pickedFile == null) {
        return null; // 用户取消选择
      }

      final file = File(pickedFile.path);
      return await AttachmentInfo.fromFile(file);
    } catch (e) {
      debugPrint('[AttachmentPicker] 选择图片失败：$e');
      return null;
    }
  }

  /// 选择文件
  Future<AttachmentInfo?> pickFile() async {
    // TODO: 使用 file_picker 包实现文件选择
    // 目前 Flutter Web 和 Mobile 的文件选择需要 file_picker 包
    debugPrint('[AttachmentPicker] 文件选择功能待实现 (需要 file_picker 包)');
    return null;
  }

  /// 拍照
  Future<AttachmentInfo?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null; // 用户取消拍摄
      }

      final file = File(pickedFile.path);
      return await AttachmentInfo.fromFile(file);
    } catch (e) {
      debugPrint('[AttachmentPicker] 拍照失败：$e');
      return null;
    }
  }
}

/// 附件预览组件
class AttachmentPreview extends StatelessWidget {
  final AttachmentInfo attachment;
  final VoidCallback? onRemove;

  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.all(4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _buildPreview(context),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(28, 28),
              ),
              onPressed: onRemove,
            ),
          ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    switch (attachment.type) {
      case AttachmentType.image:
        return _buildImagePreview();
      case AttachmentType.video:
        return _buildVideoPreview();
      case AttachmentType.audio:
        return _buildAudioPreview();
      case AttachmentType.file:
        return _buildFilePreview(context);
    }
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(attachment.path),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildIconPreview(Icons.image, Colors.blue);
        },
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildIconPreview(Icons.video_file, Colors.green),
        const Icon(Icons.play_arrow, color: Colors.white, size: 32),
      ],
    );
  }

  Widget _buildAudioPreview() {
    return _buildIconPreview(Icons.audio_file, Colors.orange);
  }

  Widget _buildFilePreview(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconPreview(Icons.insert_drive_file, Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              attachment.name,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              attachment.formattedSize,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconPreview(IconData icon, Color color) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 48,
        color: color,
      ),
    );
  }
}

/// 附件选择按钮
class AttachmentPickerButton extends StatelessWidget {
  final Function(AttachmentInfo attachment) onAttachmentPicked;

  const AttachmentPickerButton({
    super.key,
    required this.onAttachmentPicked,
  });

  Future<void> _showAttachmentOptions(BuildContext context) async {
    final picker = AttachmentPicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('选择文件'),
              onTap: () {
                // TODO: 文件选择
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('文件选择功能待实现')),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    AttachmentInfo? attachment;
    
    if (source == ImageSource.camera) {
      attachment = await picker.takePhoto();
    } else {
      attachment = await picker.pickImage(source: source);
    }

    if (attachment != null && context.mounted) {
      onAttachmentPicked(attachment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      tooltip: '添加附件',
      onPressed: () => _showAttachmentOptions(context),
    );
  }
}
