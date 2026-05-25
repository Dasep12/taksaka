/// ─────────────────────────────────────────
///  HOME SCREEN – DATA MODELS
/// ─────────────────────────────────────────

class UserProfile {
  const UserProfile({
    required this.name,
    required this.position,
    this.avatarUrl,
    this.notificationCount = 0,
  });

  final String name;
  final String position;
  final String? avatarUrl;
  final int notificationCount;

  String get firstName => name.split(' ').first;
}

class AttendanceSchedule {
  const AttendanceSchedule({
    required this.shiftLabel,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isClockedIn = false,
    this.isClockedOut = false,
    this.checkInTime,
    this.checkOutTime,
  });

  final String shiftLabel;
  final String date;
  final String startTime;
  final String endTime;
  final bool isClockedIn;
  final bool isClockedOut;
  final String? checkInTime;
  final String? checkOutTime;

  String get timeRange => '$startTime - $endTime';
}

class QuickMenuitem {
  const QuickMenuitem({
    required this.label,
    required this.iconPath,
    this.badge,
    this.onTap,
  });

  final String label;
  final String iconPath;
  final String? badge;
  final void Function()? onTap;
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.position,
    this.avatarUrl,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String position;
  final String? avatarUrl;
  final bool isOnline;

  String get shortName {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0]} ${parts[1][0]}.';
    return name;
  }
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.imageUrl,
    this.category,
  });

  final String id;
  final String title;
  final String description;
  final String date;
  final String? imageUrl;
  final String? category;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['content'] ?? '',
      date: json['created_at'] ?? '',
      category: json['category'],
    );
  }
}
