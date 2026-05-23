import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// ─────────────────────────────────────────
///  APP AVATAR
/// ─────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppSizes.avatarMd,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 0,
    this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color get _bgColor {
    if (backgroundColor != null) return backgroundColor!;
    if (name == null) return AppColors.grey200;
    // deterministic color from name
    final colors = [
      const Color(0xFF06065D),
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.36;
    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(fontSize),
        ),
      );
    } else {
      avatar = _buildInitials(fontSize);
    }

    if (borderWidth > 0) {
      avatar = Container(
        width: size + borderWidth * 2,
        height: size + borderWidth * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppColors.secondary,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }

  Widget _buildInitials(double fontSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor ?? AppColors.secondary,
        ),
      ),
    );
  }
}
