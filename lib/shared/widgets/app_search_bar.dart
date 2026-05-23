import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────
///  APP SEARCH BAR
/// ─────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.backgroundColor,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: backgroundColor != null
                  ? AppColors.grey400
                  : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: readOnly
                  ? Text(
                      hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: backgroundColor != null
                            ? AppColors.grey400
                            : Colors.white.withOpacity(0.7),
                      ),
                    )
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      style: TextStyle(
                        fontSize: 14,
                        color: backgroundColor != null
                            ? AppColors.grey900
                            : Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: backgroundColor != null
                              ? AppColors.grey400
                              : Colors.white.withOpacity(0.7),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
