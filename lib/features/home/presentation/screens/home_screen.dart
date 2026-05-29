import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
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
import '../../../request/presentation/screens/request_dashboard_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../attendance/presentation/screens/attendance_history_screen.dart';
import '../../../schedule/presentation/screens/schedule_screen.dart';
import '../../../request/presentation/screens/proposed_screen.dart';
import '../../../eslip/presentation/screens/eslip_screen.dart';
import 'announcement_detail_screen.dart';
import '../../../approval/presentation/screens/approval_screen.dart';

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

  /// Buka bottom sheet pilihan absensi
  void _openAttendanceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttendanceActionSheet(
        onClockIn: () {
          Navigator.pop(context);
          _handleClockIn();
        },
        onClockOut: () {
          Navigator.pop(context);
          _handleClockOut();
        },
        onHistory: () {
          Navigator.pop(context);
          _handleHistory();
        },
      ),
    );
  }

  /// Navigasi ke riwayat absensi
  void _handleHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
    );
  }

  void _handleSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
  }

  void _handleEslip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EslipScreen()),
    );
  }

  void _handleApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ApprovalScreen()),
    );
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
      body: _selectedIndex == 1
          ? const RequestDashboardScreen()
          : _selectedIndex == 3
          ? const ProposedScreen()
          : _selectedIndex == 4
          ? const ProfileScreen()
          : Column(
              children: [
                // ── Header (primary color bg) ──
                _HomeHeader(user: user),

                // ── Scrollable body (white sheet) ──
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.scaffoldBg,
                    ),
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
                            QuickMenuGrid(
                              items: [
                                {
                                  'label': 'Schedule',
                                  'icon': Icons.calendar_today_rounded,
                                  'badge': null,
                                  'onTap': _handleSchedule,
                                },
                                {
                                  'label': 'History',
                                  'icon': Icons.history_rounded,
                                  'badge': null,
                                  'onTap': _handleHistory,
                                },
                                {
                                  'label': 'E-Slip',
                                  'icon': Icons.card_membership_rounded,
                                  'badge': null,
                                  'onTap': _handleEslip,
                                },
                                {
                                  'label': 'Approval',
                                  'icon': Icons.check_circle_outline_rounded,
                                  'badge': '99+',
                                  'onTap': _handleApproval,
                                },
                                {
                                  'label': 'HR',
                                  'icon': Icons.apps_rounded,
                                  'badge': null,
                                  'onTap': null,
                                },
                                {
                                  'label': 'Loan',
                                  'icon': Icons.money_rounded,
                                  'badge': null,
                                  'onTap': null,
                                },
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Your Member
                            SectionHeader(
                              title: 'Your member',
                              onViewAll: () {},
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TeamMemberRow(
                              members: HomeMockData.teamMembers,
                              onAddNew: () {},
                              onMemberTap: (m) =>
                                  _showSnack('${m.name} tapped'),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Announcements
                            SectionHeader(
                              title: 'Announcement',
                              onViewAll: () {},
                            ),
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
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AnnouncementDetailScreen(
                                                announcement: a,
                                              ),
                                        ),
                                      );
                                    },
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
        onTap: (i) {
          if (i == 2) {
            _openAttendanceSheet();
          } else {
            setState(() => _selectedIndex = i);
          }
        },
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
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
                icon: Icons.assignment_rounded,
                label: 'Proposed',
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

/// ─── Attendance Action Sheet ──────────────
class _AttendanceActionSheet extends StatelessWidget {
  const _AttendanceActionSheet({
    required this.onClockIn,
    required this.onClockOut,
    required this.onHistory,
  });

  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'Absensi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.login_rounded,
                  label: 'Clock In',
                  subtitle: 'Catat waktu masuk kerja',
                  color: AppColors.success,
                  onTap: onClockIn,
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Clock Out',
                  subtitle: 'Catat waktu selesai kerja',
                  color: AppColors.error,
                  onTap: onClockOut,
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.history_rounded,
                  label: 'Riwayat Absensi',
                  subtitle: 'Lihat rekap kehadiran bulanan',
                  color: AppColors.primary,
                  onTap: onHistory,
                ),
              ],
            ),
          ),

          // Cancel
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
