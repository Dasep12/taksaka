import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────
//  FILE PICKER WIDGET  –  Reusable
//  Menampilkan tombol pilih file + daftar
//  file yang sudah dipilih dengan opsi hapus
// ─────────────────────────────────────────

class FilePickerWidget extends StatelessWidget {
  const FilePickerWidget({
    super.key,
    required this.files,
    required this.onPick,
    required this.onRemove,
  });

  final List<PlatformFile> files;
  final VoidCallback onPick;
  final void Function(int index) onRemove;

  String _fileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData _fileIcon(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':  return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':  return Icons.image_rounded;
      case 'doc':
      case 'docx': return Icons.article_rounded;
      case 'xls':
      case 'xlsx': return Icons.table_chart_rounded;
      default:     return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileColor(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':  return AppColors.error;
      case 'jpg':
      case 'jpeg':
      case 'png':  return AppColors.info;
      case 'doc':
      case 'docx': return AppColors.primary;
      case 'xls':
      case 'xlsx': return AppColors.success;
      default:     return AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pick button ──
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  files.isEmpty ? 'Pilih File' : 'Tambah File',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── File list ──
        if (files.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...List.generate(files.length, (i) {
            final f = files[i];
            final ext = f.extension;
            final fc = _fileColor(ext);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: fc.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: fc.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(_fileIcon(ext), color: fc, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _fileSize(f.size),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
