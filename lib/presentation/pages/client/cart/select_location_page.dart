import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SelectedLocationResult {
  final String address;
  final double latitude;
  final double longitude;

  const SelectedLocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  GoogleMapController? _mapController;

  LatLng _initialPosition = const LatLng(-2.170998, -79.922359);
  LatLng? _selectedPosition;
  String _selectedAddress = 'Toca el mapa para seleccionar una ubicación';
  bool _isLoading = true;
  bool _isResolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _selectedPosition = _initialPosition;
          _isLoading = false;
        });
        await _resolveAddress(_initialPosition);
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _selectedPosition = _initialPosition;
          _isLoading = false;
        });
        await _resolveAddress(_initialPosition);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _initialPosition = currentLatLng;
        _selectedPosition = currentLatLng;
        _isLoading = false;
      });

      await _resolveAddress(currentLatLng);
    } catch (_) {
      setState(() {
        _selectedPosition = _initialPosition;
        _isLoading = false;
      });
      await _resolveAddress(_initialPosition);
    }
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() {
      _isResolvingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.trim().isNotEmpty).toList();

        setState(() {
          _selectedAddress =
          parts.isNotEmpty ? parts.join(', ') : 'Ubicación seleccionada';
        });
      } else {
        setState(() {
          _selectedAddress = 'Ubicación seleccionada';
        });
      }
    } catch (_) {
      setState(() {
        _selectedAddress = 'Ubicación seleccionada';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedPosition = currentLatLng;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 16),
      );

      await _resolveAddress(currentLatLng);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación actual'),
        ),
      );
    }
  }

  void _confirmSelection() {
    if (_selectedPosition == null) return;

    Navigator.of(context).pop(
      SelectedLocationResult(
        address: _selectedAddress,
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _selectedPosition == null
        ? <Marker>{}
        : {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedPosition!,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (position) async {
              setState(() {
                _selectedPosition = position;
              });
              await _resolveAddress(position);
            },
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección seleccionada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (_isResolvingAddress) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FloatingActionButton.small(
                  heroTag: 'current_location',
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedPosition == null ? null : _confirmSelection,
                  icon: const Icon(Icons.check),
                  label: const Text('Usar ubicación'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}