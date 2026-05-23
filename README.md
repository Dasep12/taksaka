# HRMS Flutter App

Fondasi awal sistem HRMS (Human Resource Management System) dengan struktur yang bersih, component reusable, dan tema konsisten.

---

## 🎨 Design System

| Token | Value | Keterangan |
|-------|-------|-----------|
| Primary | `#06065D` | Navy – AppBar, buttons, nav |
| Secondary | `#FFFFFF` | White – surface, text on primary |
| Accent (Third) | `#F59E0B` | Amber – CTA, badge, highlights |

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                          # Entry point
├── hrms_exports.dart                  # Barrel exports
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart            # Semua warna brand
│   │   ├── app_text_styles.dart       # Typography system
│   │   └── app_theme.dart             # ThemeData lengkap
│   └── constants/
│       └── app_spacing.dart           # Spacing, radius, sizes
│
├── shared/
│   └── widgets/                       # Reusable components
│       ├── app_card.dart              # Generic card container
│       ├── app_avatar.dart            # Avatar with initials fallback
│       ├── app_button.dart            # Primary / Secondary / Ghost
│       ├── app_search_bar.dart        # Search input
│       ├── section_header.dart        # Title + View All
│       └── status_badge.dart          # Status chip (present, absent, etc.)
│
└── features/
    ├── home/
    │   ├── domain/
    │   │   └── home_models.dart       # Data models
    │   ├── data/
    │   │   └── home_mock_data.dart    # Mock data (ganti dengan API)
    │   └── presentation/
    │       ├── screens/
    │       │   └── home_screen.dart   # Main home screen
    │       └── widgets/
    │           ├── attendance_card.dart
    │           ├── quick_menu_grid.dart
    │           ├── team_member_row.dart
    │           └── announcement_card.dart
    │
    ├── auth/          # (next: login, forgot password)
    ├── attendance/    # (next: detail absensi)
    ├── request/       # (next: cuti, izin)
    ├── message/       # (next: chat internal)
    └── profile/       # (next: profil karyawan)
```

---

## 🧩 Komponen Reusable

### AppCard
```dart
AppCard(
  onTap: () {},
  child: Text('Hello'),
)
```

### AppAvatar
```dart
AppAvatar(
  name: 'Savannah Nguyen',
  size: AppSizes.avatarLg,
)
```

### AppButton
```dart
AppButton(
  label: 'Clock In',
  variant: AppButtonVariant.primary,
  icon: Icons.login_rounded,
  onPressed: () {},
)
```

### StatusBadge
```dart
StatusBadge(
  label: 'Present',
  status: BadgeStatus.present,
)
```

---

## 🚀 Cara Menjalankan

```bash
flutter pub get
flutter run
```

---

## 📌 Roadmap Fitur

- [ ] Auth (Login / Logout)
- [ ] Clock In / Out dengan GPS
- [ ] Leave Request
- [ ] Payslip viewer
- [ ] Push Notifications
- [ ] Dark Mode
