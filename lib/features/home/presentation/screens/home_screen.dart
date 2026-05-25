import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/home_mock_data.dart';
import '../../domain/home_models.dart';
import '../widgets/attendance_card.dart';
import '../widgets/quick_menu_grid.dart';
import '../widgets/team_member_row.dart';
import '../widgets/announcement_card.dart';
import '../../../attendance/domain/attendance_models.dart';
import '../../../attendance/presentation/screens/attendance_screen.dart';
import '../../../auth/presentation/screens/face_register_screen.dart';
import '../../../attendance/data/face_service.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/home_service.dart';

/// ─────────────────────────────────────────
///  HOME SCREEN
/// ─────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  AttendanceSchedule _schedule = HomeMockData.todaySchedule;
  List<Announcement> _announcements = HomeMockData.announcements;

  String _userId = 'demo_user';
  String _userName = 'User';
  String? _userAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    var employee = await AuthService.instance.fetchMe();
    employee ??= await AuthService.instance.getEmployee();
    final user = await AuthService.instance.getUser();
    final schedule = await HomeService.instance.getTodaySchedule();
    final announcements = await HomeService.instance.getAnnouncements();

    if (mounted) {
      setState(() {
        if (employee != null) {
          _userId = employee.employeeId.toString();
          _userName = employee.employeeName;
          _userAvatarUrl = employee.photoPath;
        } else if (user != null) {
          _userId = user.id.toString();
          _userName = user.name;
        }

        if (schedule != null) {
          _schedule = schedule;
        }

        if (announcements.isNotEmpty) {
          _announcements = announcements;
        }
      });
    }
  }

  Future<void> _handleClockIn() async {
    final registered = await FaceService.instance.hasRegisteredFace(_userId);
    if (!registered && mounted) {
      final ok = await _promptFaceRegister();
      if (ok != true) return;
    }
    if (!mounted) return;
    final result = await Navigator.push<AttendanceRecord>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AttendanceScreen(type: AttendanceType.clockIn, userId: _userId),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _schedule = AttendanceSchedule(
          shiftLabel: _schedule.shiftLabel,
          date: _schedule.date,
          startTime: result.formattedTime,
          endTime: _schedule.endTime,
          isClockedIn: true,
          isClockedOut: false,
        );
      });
      _showSnack('Clock In pukul ${result.formattedTime} berhasil! ✅');
    }
  }

  Future<void> _handleClockOut() async {
    final registered = await FaceService.instance.hasRegisteredFace(_userId);
    if (!registered && mounted) {
      final ok = await _promptFaceRegister();
      if (ok != true) return;
    }
    if (!mounted) return;
    final result = await Navigator.push<AttendanceRecord>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AttendanceScreen(type: AttendanceType.clockOut, userId: _userId),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _schedule = AttendanceSchedule(
          shiftLabel: _schedule.shiftLabel,
          date: _schedule.date,
          startTime: _schedule.startTime,
          endTime: result.formattedTime,
          isClockedIn: true,
          isClockedOut: true,
        );
      });
      _showSnack('Clock Out pukul ${result.formattedTime} berhasil! 👋');
    }
  }

  Future<bool?> _promptFaceRegister() async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.face_retouching_natural, color: AppColors.primary),
            SizedBox(width: 10),
            Text(
              'Registrasi Wajah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Anda belum meregistrasi wajah untuk absensi.\nRegistrasi sekarang untuk melanjutkan.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FaceRegisterScreen(userId: _userId, userName: _userName),
                ),
              );

              if (!mounted) return;

              if (ok == true) {
                // success action
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Daftar Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = UserProfile(
      name: _userName,
      position: HomeMockData.currentUser.position,
      avatarUrl: _userAvatarUrl,
      notificationCount: HomeMockData.currentUser.notificationCount,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // ── Header (primary color bg) ──
          _HomeHeader(user: user),

          // ── Scrollable body (white sheet) ──
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: AppColors.scaffoldBg),
              child: RefreshIndicator(
                onRefresh: _loadUserData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Attendance card
                      AttendanceCard(
                        schedule: _schedule,
                        onClockIn: _handleClockIn,
                        onClockOut: _handleClockOut,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Quick Menu
                      QuickMenuGrid(items: QuickMenuConfig.items),
                      const SizedBox(height: AppSpacing.xl),

                      // Your Member
                      SectionHeader(title: 'Your member', onViewAll: () {}),
                      const SizedBox(height: AppSpacing.md),
                      TeamMemberRow(
                        members: HomeMockData.teamMembers,
                        onAddNew: () {},
                        onMemberTap: (m) => _showSnack('${m.name} tapped'),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Announcements
                      SectionHeader(title: 'Announcement', onViewAll: () {}),
                      const SizedBox(height: AppSpacing.md),
                      if (_announcements.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              'No announcements yet.',
                              style: TextStyle(color: AppColors.grey500),
                            ),
                          ),
                        )
                      else
                        ..._announcements.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: AnnouncementCard(
                              announcement: a,
                              onTap: () => _showSnack(a.title),
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Navigation ──
      bottomNavigationBar: _HomeBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

/// ─── Header Widget ───────────────────────
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        top + AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          // Top row: avatar + greeting + bell
          Row(
            children: [
              AppAvatar(
                name: user.name,
                imageUrl: user.avatarUrl,
                size: AppSizes.avatarMd,
                borderColor: Colors.white,
                borderWidth: 2,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Good Morning ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              _NotificationBell(count: user.notificationCount),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Search bar
          AppSearchBar(hint: 'Search', readOnly: true, onTap: () {}),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ─── Bottom Navigation ───────────────────
class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSizes.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                selected: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.inbox_rounded,
                label: 'Request',
                index: 1,
                selected: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.qr_code_scanner_rounded,
                label: '',
                index: 2,
                selected: selectedIndex,
                onTap: onTap,
                isCta: true,
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message',
                index: 3,
                selected: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                index: 4,
                selected: selectedIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    this.isCta = false,
  });

  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;
  final bool isCta;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == index;

    if (isCta) {
      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.grey400,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
