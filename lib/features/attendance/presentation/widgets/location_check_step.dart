import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/attendance_models.dart';
import '../../data/location_service.dart';
import '../../../auth/data/auth_service.dart';
import '../../../../shared/widgets/app_avatar.dart';

class LocationCheckStep extends StatefulWidget {
  const LocationCheckStep({
    super.key,
    required this.offices,
    required this.onLocationVerified,
  });

  final List<OfficeLocation> offices;
  final void Function(UserLocation location, OfficeLocation nearestOffice) onLocationVerified;

  @override
  State<LocationCheckStep> createState() => _LocationCheckStepState();
}

class _LocationCheckStepState extends State<LocationCheckStep> {
  final MapController _mapCtrl = MapController();

  LocationStatus _status = LocationStatus.checking;
  UserLocation? _userLocation;
  OfficeLocation? _nearestOffice;
  double? _distanceMeters;

  StreamSubscription<UserLocation>? _locationSub;

  String? _userPhotoUrl;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserPhoto();
    _fetchLocation();
  }

  Future<void> _loadUserPhoto() async {
    final employee = await AuthService.instance.getEmployee();
    if (employee != null && mounted) {
      setState(() {
        _userPhotoUrl = employee.photoPath;
        _userName = employee.employeeName;
      });
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _status = LocationStatus.checking;
    });

    try {
      final loc = await LocationService.instance.getCurrentLocation();
      _updateNearestOffice(loc);

      if (!mounted) return;

      setState(() {
        _userLocation = loc;
        if (_nearestOffice != null && _distanceMeters != null) {
           final inRange = LocationService.instance.isInRange(loc, _nearestOffice!);
           _status = inRange ? LocationStatus.inRange : LocationStatus.outOfRange;
        }
      });

      _moveCamera(loc);

      _locationSub?.cancel();

      _locationSub = LocationService.instance.locationStream().listen((newLoc) {
        if (!mounted) return;
        _updateNearestOffice(newLoc);

        setState(() {
          _userLocation = newLoc;
          if (_nearestOffice != null && _distanceMeters != null) {
             final inRange = LocationService.instance.isInRange(newLoc, _nearestOffice!);
             _status = inRange ? LocationStatus.inRange : LocationStatus.outOfRange;
          }
        });

        _moveCamera(newLoc);
      });
    } on LocationException catch (e) {
      if (!mounted) return;

      setState(() {
        _status =
            e.type == LocationExceptionType.permissionDenied ||
                e.type == LocationExceptionType.permissionPermanentlyDenied
            ? LocationStatus.permissionDenied
            : LocationStatus.error;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _status = LocationStatus.error;
      });
    }
  }

  void _moveCamera(UserLocation loc) {
    _mapCtrl.move(LatLng(loc.latitude, loc.longitude), 16);
  }

  void _updateNearestOffice(UserLocation loc) {
    if (widget.offices.isEmpty) return;
    
    double minDist = double.infinity;
    OfficeLocation? nearest;

    for (final office in widget.offices) {
      final dist = LocationService.instance.getDistance(loc, office);
      if (dist < minDist) {
        minDist = dist;
        nearest = office;
      }
    }

    if (nearest != null) {
      _nearestOffice = nearest;
      _distanceMeters = minDist;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialLatLng = widget.offices.isNotEmpty 
        ? LatLng(widget.offices.first.latitude, widget.offices.first.longitude)
        : const LatLng(0, 0);

    final userLatLng = _userLocation != null
        ? LatLng(_userLocation!.latitude, _userLocation!.longitude)
        : null;

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: initialLatLng,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.taksaka',
                    ),

                    CircleLayer(
                      circles: widget.offices.map((office) => CircleMarker(
                        point: LatLng(office.latitude, office.longitude),
                        radius: office.radiusMeters,
                        useRadiusInMeter: true,
                        color: AppColors.primary.withOpacity(0.15),
                        borderStrokeWidth: 2,
                        borderColor: AppColors.primary,
                      )).toList(),
                    ),

                    MarkerLayer(
                      markers: [
                        ...widget.offices.map((office) => Marker(
                          point: LatLng(office.latitude, office.longitude),
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.business,
                            color: Colors.blue,
                            size: 40,
                          ),
                        )),

                        if (userLatLng != null)
                          Marker(
                            point: userLatLng,
                            width: 60,
                            height: 60,
                            child: AppAvatar(
                              imageUrl: _userPhotoUrl,
                              name: _userName ?? 'User',
                              size: 50,
                              borderColor: _status == LocationStatus.inRange
                                  ? Colors.green
                                  : Colors.red,
                              borderWidth: 3,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _nearestOffice != null 
                      ? _MapInfoChip(office: _nearestOffice!)
                      : const SizedBox.shrink(),
                ),

                if (_status == LocationStatus.checking)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_status) {
            LocationStatus.checking => const _CheckingCard(),

            LocationStatus.inRange => _InRangeCard(
              distance: _distanceMeters ?? 0,
              accuracy: _userLocation?.accuracy ?? 0,
              office: _nearestOffice!,
              onContinue: () {
                if (_userLocation != null && _nearestOffice != null) {
                  widget.onLocationVerified(_userLocation!, _nearestOffice!);
                }
              },
            ),

            LocationStatus.outOfRange => _OutRangeCard(
              distance: _distanceMeters ?? 0,
              radius: _nearestOffice?.radiusMeters ?? 0,
              onRetry: _fetchLocation,
            ),

            LocationStatus.permissionDenied => _PermissionCard(
              onRetry: _fetchLocation,
            ),

            LocationStatus.error => _ErrorCard(onRetry: _fetchLocation),
          },
        ),
      ],
    );
  }
}

class _MapInfoChip extends StatelessWidget {
  const _MapInfoChip({required this.office});

  final OfficeLocation office;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            office.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(office.address, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _CheckingCard extends StatelessWidget {
  const _CheckingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: CircularProgressIndicator(),
    );
  }
}

class _InRangeCard extends StatelessWidget {
  const _InRangeCard({
    required this.distance,
    required this.accuracy,
    required this.office,
    required this.onContinue,
  });

  final double distance;
  final double accuracy;
  final OfficeLocation office;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Lokasi valid (${distance.toStringAsFixed(0)}m)'),

        const SizedBox(height: 12),

        ElevatedButton(
          onPressed: onContinue,
          child: const Text('Lanjut Scan Wajah'),
        ),
      ],
    );
  }
}

class _OutRangeCard extends StatelessWidget {
  const _OutRangeCard({
    required this.distance,
    required this.radius,
    required this.onRetry,
  });

  final double distance;
  final double radius;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Di luar area (${distance.toStringAsFixed(0)}m / ${radius.toStringAsFixed(0)}m)',
        ),

        const SizedBox(height: 12),

        ElevatedButton(onPressed: onRetry, child: const Text('Refresh')),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Izin lokasi diperlukan'),

        const SizedBox(height: 12),

        ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Terjadi kesalahan GPS'),

        const SizedBox(height: 12),

        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
