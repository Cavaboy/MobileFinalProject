import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'converter_screen.dart';
import 'profile_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _position;
  String? _error;
  bool _loading = false;
  List<Map<String, dynamic>> _nearbyPlaces = [];

  Future<void> _getLocationAndNearby() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled.';
          _loading = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied.';
            _loading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied.';
          _loading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // Fetch from Geoapify
      final lat = pos.latitude;
      final lon = pos.longitude;
      final apiKey = '812b6ba40e0f47a2b0c1f4c4af964f07';
      final url = Uri.parse(
        'https://api.geoapify.com/v2/places?categories=catering.cafe,office.coworking&filter=circle:$lon,$lat,20000&limit=10&apiKey=$apiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;
        final List<Map<String, dynamic>> places =
            features.map((f) {
              final prop = f['properties'];
              return {
                'name': prop['name'] ?? 'Unknown',
                'address': prop['formatted'] ?? '',
                'lat': prop['lat'],
                'lon': prop['lon'],
              };
            }).toList();
        setState(() {
          _position = pos;
          _nearbyPlaces = places;
          _loading = false;
        });
        // Show notification when loaded
        NotificationService.showNearbyPlacesNotification();
      } else {
        setState(() {
          _position = pos;
          _error = 'Failed to fetch places (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to get location or places: \\${e.toString()}';
        _loading = false;
      });
    }
  }

  List<LatLng> get _placePins {
    if (_nearbyPlaces.isEmpty) return [];
    return _nearbyPlaces.map((p) => LatLng(p['lat'], p['lon'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Places')),
      body:
          user == null
              ? const Center(
                child: Text(
                  'Not signed in',
                  style: TextStyle(color: Colors.red),
                ),
              )
              : Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _loading ? null : _getLocationAndNearby,
                        child:
                            _loading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Find Nearby Places'),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (_position != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Your location: \\${_position!.latitude}, \\${_position!.longitude}',
                          ),
                        ),
                      if (_loading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (!_loading &&
                          _position != null &&
                          _nearbyPlaces.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No nearby places found.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      if (_position != null && _nearbyPlaces.isNotEmpty)
                        Expanded(
                          child: FlutterMap(
                            options: MapOptions(
                              center: LatLng(
                                _position!.latitude,
                                _position!.longitude,
                              ),
                              initialZoom: 16,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  // User location pin
                                  Marker(
                                    point: LatLng(
                                      _position!.latitude,
                                      _position!.longitude,
                                    ),
                                    width: 40,
                                    height: 40,
                                    rotate: false, // Always point down
                                    child: const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.blue,
                                      size: 40,
                                    ),
                                  ),
                                  // Place pins
                                  ..._placePins.asMap().entries.map(
                                    (entry) => Marker(
                                      point: entry.value,
                                      width: 180,
                                      height: 60,
                                      rotate: false, // Always point down
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxWidth: 170,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              _nearbyPlaces[entry.key]['name'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 36,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (_nearbyPlaces.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: _nearbyPlaces.length,
                            itemBuilder: (context, index) {
                              final place = _nearbyPlaces[index];
                              return ListTile(
                                leading: const Icon(Icons.place),
                                title: Text(
                                  place['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(place['address']),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Map is index 1
        onTap: (index) {
          if (index == 0) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ConverterScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Nearby'),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Converter',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
