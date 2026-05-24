import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/attendance_models.dart';
import '../../data/location_service.dart';

/// ─────────────────────────────────────────
///  STEP 1 – LOCATION CHECK (Google Maps real)
/// ─────────────────────────────────────────
class LocationCheckStep extends StatefulWidget {
  const LocationCheckStep({
    super.key,
    required this.office,
    required this.onLocationVerified,
  });

  final OfficeLocation office;
  final void Function(UserLocation location) onLocationVerified;

  @override
  State<LocationCheckStep> createState() => _LocationCheckStepState();
}

class _LocationCheckStepState extends State<LocationCheckStep>
    with SingleTickerProviderStateMixin {
  LocationStatus _status = LocationStatus.checking;
  UserLocation? _userLocation;
  double? _distanceMeters;

  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  late AnimationController _pulseCtrl;
  StreamSubscription<UserLocation>? _locationSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fetchLocation();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _locationSub?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _status = LocationStatus.checking;
      _userLocation = null;
    });

    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;

      final dist = LocationService.instance.getDistance(loc, widget.office);
      final inRange = LocationService.instance.isInRange(loc, widget.office);

      setState(() {
        _userLocation = loc;
        _distanceMeters = dist;
        _status = inRange ? LocationStatus.inRange : LocationStatus.outOfRange;
      });

      _updateMapMarkers(loc);
      _animateCameraToFitBoth(loc);

      // Start live stream updates
      _locationSub?.cancel();
      _locationSub = LocationService.instance.locationStream().listen((newLoc) {
        if (!mounted) return;
        final newDist = LocationService.instance.getDistance(newLoc, widget.office);
        final newInRange = LocationService.instance.isInRange(newLoc, widget.office);
        setState(() {
          _userLocation = newLoc;
          _distanceMeters = newDist;
          _status = newInRange ? LocationStatus.inRange : LocationStatus.outOfRange;
        });
        _updateMapMarkers(newLoc);
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = e.type == LocationExceptionType.permissionDenied ||
                e.type == LocationExceptionType.permissionPermanentlyDenied
            ? LocationStatus.permissionDenied
            : LocationStatus.error;
      });
    } catch (_) {
      if (mounted) setState(() => _status = LocationStatus.error);
    }
  }

  void _updateMapMarkers(UserLocation loc) {
    setState(() {
      final inRange = LocationService.instance.isInRange(loc, widget.office);

      _markers = {
        // Office marker
        Marker(
          markerId: const MarkerId('office'),
          position: LatLng(widget.office.latitude, widget.office.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: widget.office.name,
            snippet: widget.office.address,
          ),
        ),
        // User marker
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(loc.latitude, loc.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            inRange ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        ),
      };

      _circles = {
        Circle(
          circleId: const CircleId('radius'),
          center: LatLng(widget.office.latitude, widget.office.longitude),
          radius: widget.office.radiusMeters,
          fillColor: AppColors.primary.withOpacity(0.08),
          strokeColor: AppColors.primary.withOpacity(0.4),
          strokeWidth: 2,
        ),
      };
    });
  }

  void _animateCameraToFitBoth(UserLocation loc) {
    final ctrl = _mapCtrl;
    if (ctrl == null) return;

    final officeLat = widget.office.latitude;
    final officeLng = widget.office.longitude;

    final swLat = loc.latitude < officeLat ? loc.latitude : officeLat;
    final swLng = loc.longitude < officeLng ? loc.longitude : officeLng;
    final neLat = loc.latitude > officeLat ? loc.latitude : officeLat;
    final neLng = loc.longitude > officeLng ? loc.longitude : officeLng;

    ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(swLat - 0.002, swLng - 0.002),
          northeast: LatLng(neLat + 0.002, neLng + 0.002),
        ),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Google Map ──────────────────────
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.office.latitude,
                      widget.office.longitude,
                    ),
                    zoom: 16,
                  ),
                  onMapCreated: (ctrl) {
                    _mapCtrl = ctrl;
                    if (_userLocation != null) {
                      _updateMapMarkers(_userLocation!);
                      _animateCameraToFitBoth(_userLocation!);
                    }
                  },
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                ),

                // Office info chip top
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _MapInfoChip(office: widget.office),
                ),

                // Re-center button
                if (_userLocation != null)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _RecenterButton(onTap: () {
                      if (_userLocation != null) _animateCameraToFitBoth(_userLocation!);
                    }),
                  ),

                // Loading overlay
                if (_status == LocationStatus.checking)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: _GpsLoadingOverlay(),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Status card ─────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: switch (_status) {
            LocationStatus.checking => const _CheckingCard(key: ValueKey('c')),
            LocationStatus.inRange => _InRangeCard(
                key: const ValueKey('ok'),
                distance: _distanceMeters ?? 0,
                accuracy: _userLocation?.accuracy ?? 0,
                office: widget.office,
                onContinue: () => widget.onLocationVerified(_userLocation!),
              ),
            LocationStatus.outOfRange => _OutRangeCard(
                key: const ValueKey('out'),
                distance: _distanceMeters ?? 0,
                radius: widget.office.radiusMeters,
                onRetry: _fetchLocation,
              ),
            LocationStatus.permissionDenied => _PermissionCard(
                key: const ValueKey('perm'),
                onRetry: _fetchLocation,
              ),
            LocationStatus.error => _ErrorCard(
                key: const ValueKey('err'),
                onRetry: _fetchLocation,
              ),
          },
        ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────

class _GpsLoadingOverlay extends StatelessWidget {
  const _GpsLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Mendeteksi lokasi GPS...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
      ),
    );
  }
}

class _MapInfoChip extends StatelessWidget {
  const _MapInfoChip({required this.office});
  final OfficeLocation office;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.business_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(office.name, style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text(office.address, style: const TextStyle(fontSize: 10,
                    color: AppColors.grey600), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Radius ${office.radiusMeters.toInt()}m',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _CheckingCard extends StatelessWidget {
  const _CheckingCard({super.key});
  @override
  Widget build(BuildContext context) {
    return _StatusBase(
      color: AppColors.primarySurface,
      borderColor: AppColors.primary.withOpacity(0.2),
      child: Row(children: [
        const SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mendeteksi Lokasi GPS...', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.primary)),
          SizedBox(height: 2),
          Text('Mohon aktifkan GPS dan tunggu sebentar',
              style: TextStyle(fontSize: 12, color: AppColors.grey600)),
        ])),
      ]),
    );
  }
}

class _InRangeCard extends StatelessWidget {
  const _InRangeCard({super.key, required this.distance, required this.accuracy,
      required this.office, required this.onContinue});
  final double distance, accuracy;
  final OfficeLocation office;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _StatusBase(
      color: AppColors.success.withOpacity(0.06),
      borderColor: AppColors.success.withOpacity(0.3),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.location_on_rounded, color: AppColors.success, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Lokasi Terverifikasi ✅', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: AppColors.success)),
            Text('${distance.toStringAsFixed(0)}m dari ${office.name} · Akurasi ±${accuracy.toStringAsFixed(0)}m',
                style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
          ])),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.face_retouching_natural, size: 18),
            label: const Text('Lanjut Scan Wajah',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }
}

class _OutRangeCard extends StatelessWidget {
  const _OutRangeCard({super.key, required this.distance, required this.radius,
      required this.onRetry});
  final double distance, radius;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatusBase(
      color: AppColors.error.withOpacity(0.06),
      borderColor: AppColors.error.withOpacity(0.25),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.location_off_rounded, color: AppColors.error, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Di Luar Area Absensi ❌', style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: AppColors.error)),
            Text('Jarak ${distance.toStringAsFixed(0)}m — batas ${radius.toStringAsFixed(0)}m',
                style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
          ])),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 44,
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh Lokasi'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatusBase(
      color: AppColors.warning.withOpacity(0.07),
      borderColor: AppColors.warning.withOpacity(0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.security_rounded, color: AppColors.warning, size: 22),
          SizedBox(width: 10),
          Expanded(child: Text('Izin Lokasi Diperlukan', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.grey900))),
        ]),
        const SizedBox(height: 6),
        const Text('Berikan izin akses lokasi agar absensi bisa diverifikasi.',
            style: TextStyle(fontSize: 12, color: AppColors.grey600)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 44,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Beri Izin Lokasi'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatusBase(
      color: AppColors.grey100,
      borderColor: AppColors.grey200,
      child: Row(children: [
        const Icon(Icons.gps_off_rounded, color: AppColors.grey600, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GPS tidak tersedia', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppColors.grey900)),
          const Text('Aktifkan lokasi perangkat dan coba lagi.',
              style: TextStyle(fontSize: 12, color: AppColors.grey600)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero, minimumSize: Size.zero),
          ),
        ])),
      ]),
    );
  }
}

class _StatusBase extends StatelessWidget {
  const _StatusBase({required this.child, required this.color, required this.borderColor});
  final Widget child;
  final Color color, borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor)),
      child: child,
    );
  }
}
