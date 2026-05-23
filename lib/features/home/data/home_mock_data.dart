import 'package:flutter/material.dart';
import '../domain/home_models.dart';

/// ─────────────────────────────────────────
///  MOCK DATA  (replace with API later)
/// ─────────────────────────────────────────
class HomeMockData {
  HomeMockData._();

  static const UserProfile currentUser = UserProfile(
    name: 'Savannah Nguyen',
    position: 'Product Designer',
    notificationCount: 3,
  );

  static const AttendanceSchedule todaySchedule = AttendanceSchedule(
    shiftLabel: 'Non Shift',
    date: 'May 23, 2025',
    startTime: '07:05',
    endTime: '16:30',
    isClockedIn: false,
    isClockedOut: false,
  );

  static const List<TeamMember> teamMembers = [
    TeamMember(id: '1', name: 'Leroy Davis',    position: 'Engineer',   isOnline: true),
    TeamMember(id: '2', name: 'Tatiana Chen',   position: 'Designer',   isOnline: false),
    TeamMember(id: '3', name: 'Cheyenne Moore', position: 'Marketing',  isOnline: true),
    TeamMember(id: '4', name: 'Nolan Douglas',  position: 'Sales',      isOnline: false),
  ];

  static const List<Announcement> announcements = [
    Announcement(
      id: 'a1',
      title: 'Sales Meetings',
      description: 'Activities to discuss among fellow team members for Q3 targets.',
      date: 'May 23, 2025',
      category: 'Meeting',
    ),
    Announcement(
      id: 'a2',
      title: 'SOP Updates',
      description: 'New standard operating procedures will be effective from June 1.',
      date: 'May 22, 2025',
      category: 'Policy',
    ),
    Announcement(
      id: 'a3',
      title: 'Public Holiday',
      description: 'Reminder: Office will be closed on May 29 for Eid holiday.',
      date: 'May 21, 2025',
      category: 'Holiday',
    ),
  ];
}

// Quick menu items configuration
class QuickMenuConfig {
  static List<Map<String, dynamic>> get items => [
        {'label': 'Work Schedule', 'icon': Icons.calendar_today_rounded,    'badge': null},
        {'label': 'Absence History','icon': Icons.history_rounded,           'badge': null},
        {'label': 'E-Certificate', 'icon': Icons.card_membership_rounded,   'badge': null},
        {'label': 'Other',         'icon': Icons.apps_rounded,               'badge': null},
      ];
}
