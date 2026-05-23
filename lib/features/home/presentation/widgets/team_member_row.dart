import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../domain/home_models.dart';

/// ─────────────────────────────────────────
///  YOUR MEMBER ROW
/// ─────────────────────────────────────────
class TeamMemberRow extends StatelessWidget {
  const TeamMemberRow({
    super.key,
    required this.members,
    this.onAddNew,
    this.onMemberTap,
  });

  final List<TeamMember> members;
  final VoidCallback? onAddNew;
  final ValueChanged<TeamMember>? onMemberTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add New button
          _AddNewMember(onTap: onAddNew),
          const SizedBox(width: AppSpacing.lg),

          // Members
          ...members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: _MemberItem(
                member: m,
                onTap: () => onMemberTap?.call(m),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddNewMember extends StatelessWidget {
  const _AddNewMember({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: AppSizes.avatarLg,
            height: AppSizes.avatarLg,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.grey400,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: const Icon(Icons.add_rounded,
                size: 22, color: AppColors.grey600),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Add New',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberItem extends StatelessWidget {
  const _MemberItem({required this.member, this.onTap});
  final TeamMember member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              AppAvatar(
                name: member.name,
                imageUrl: member.avatarUrl,
                size: AppSizes.avatarLg,
              ),
              if (member.isOnline)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 52,
            child: Text(
              member.shortName,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
