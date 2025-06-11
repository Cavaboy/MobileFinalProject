import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart'; // Import LoginScreen for navigation

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

  // Fetches current location and nearby places
  Future<void> _getLocationAndNearby() async {
    setState(() {
      _loading = true;
      _error = null; // Clear previous errors
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled. Please enable them.';
          _loading = false;
        });
        return;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied. Please grant permission to find nearby places.';
            _loading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied. Please enable them in app settings.';
          _loading = false;
        });
        return;
      }

      // Get current position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch nearby places from Geoapify
      final lat = pos.latitude;
      final lon = pos.longitude;
      // TODO: Securely manage your API key (e.g., using environment variables or a build config)
      final apiKey = '812b6ba40e0f47a2b0c1f4c4af964f07'; // Your Geoapify API Key
      final url = Uri.parse(
        'https://api.geoapify.com/v2/places?categories=catering.cafe,office.coworking&filter=circle:$lon,$lat,20000&limit=10&apiKey=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>;
        final List<Map<String, dynamic>> places = features.map((f) {
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
          _position = pos; // Still show position even if places fetch fails
          _error = 'Failed to fetch places. Status Code: ${response.statusCode}. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      // Catch any other errors during location or API call
      setState(() {
        _error = 'An unexpected error occurred: ${e.toString()}. Please check your internet connection.';
        _loading = false;
      });
    }
  }

  // Helper getter to convert nearby places data to LatLng for map markers
  List<LatLng> get _placePins {
    if (_nearbyPlaces.isEmpty) return [];
    return _nearbyPlaces.map((p) => LatLng(p['lat'], p['lon'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from AuthService
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Places'),
        // AppBar style inherited from ThemeData in main.dart
      ),
      body: user == null
          ? _buildUnauthenticatedState(context) // Show this if user is not signed in
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // --- "Find Nearby Places" Button ---
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _getLocationAndNearby,
                    icon: _loading
                        ? SizedBox(
                            width: 20, // Slightly larger spinner
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5, // Thicker spinner
                              color: Theme.of(context).colorScheme.onPrimary, // White spinner on blue button
                            ),
                          )
                        : Icon(Icons.location_searching_rounded), // Search icon for clarity
                    label: Text(
                      _loading ? 'Finding Places...' : 'Find Nearby Places',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary, // Brand blue
                      foregroundColor: Theme.of(context).colorScheme.onPrimary, // White text/icon
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0), // Rounded corners
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0), // Comfortable padding
                      minimumSize: const Size.fromHeight(50), // Ensure a minimum height
                      elevation: 0, // No shadow for minimalist look
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing after button

                  // --- Error Message Display ---
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error, // Red from theme
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // --- User Location Display ---
                  if (_position != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Your current location: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // --- Map Section ---
                  if (_position != null && !_loading) // Only show map if location is available and not loading
                    Expanded(
                      flex: 3, // Give more space to the map
                      child: Card(
                        elevation: 4, // More pronounced shadow for the map card
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0), // Rounded corners
                        ),
                        clipBehavior: Clip.antiAlias, // Clip map content to rounded corners
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              _position!.latitude,
                              _position!.longitude,
                            ),
                            initialZoom: 14, // Zoom level for better visibility of nearby places
                            minZoom: 2,
                            maxZoom: 18,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.nomaddaily.app', // Good practice to include
                            ),
                            MarkerLayer(
                              markers: [
                                // User location marker (brand blue pin)
                                Marker(
                                  point: LatLng(
                                    _position!.latitude,
                                    _position!.longitude,
                                  ),
                                  width: 60, // Increased size for user marker
                                  height: 60,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.person_pin_circle_rounded, // User pin icon
                                      color: Colors.white, // White icon for contrast
                                      size: 40, // Icon size within the container
                                    ),
                                  ),
                                ),
                                // Nearby place markers
                                ..._nearbyPlaces.asMap().entries.map(
                                  (entry) => Marker(
                                    point: entry.value is Map<String, dynamic> && entry.value.containsKey('lat') && entry.value.containsKey('lon')
                                        ? LatLng(entry.value['lat'], entry.value['lon'])
                                        : LatLng(0, 0), // Fallback
                                    width: 120, // Adjusted width for text + icon
                                    height: 70, // Adjusted height for text + icon
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.95), // Slightly transparent white background
                                            borderRadius: BorderRadius.circular(10), // More rounded
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15), // Darker shadow
                                                blurRadius: 6, // More blur
                                                offset: const Offset(0, 3), // More offset
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            entry.value['name'] ?? 'Unknown Place',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontSize: 13, // Slightly larger font
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        Icon(
                                          Icons.push_pin_rounded, // Distinct push pin icon
                                          color: Theme.of(context).colorScheme.secondary, // Use secondary color for distinction
                                          size: 36, // Larger pin icon
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Map Attribution
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  'OpenStreetMap contributors',
                                  onTap: () => debugPrint('OpenStreetMap'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20), // Spacing between map and list

                  // --- Nearby Places List Section ---
                  if (!_loading && _nearbyPlaces.isNotEmpty)
                    Expanded(
                      flex: 2, // Give more space to the list if content is abundant
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nearby Places',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _nearbyPlaces.length,
                              itemBuilder: (context, index) {
                                final place = _nearbyPlaces[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12), // Spacing between cards
                                  elevation: 1, // Subtle elevation for list items
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.store_mall_directory_rounded, // Generic place icon
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                    ),
                                    title: Text(
                                      place['name'] ?? 'Unknown Place',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    subtitle: Text(
                                      place['address'] ?? 'No address available',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                    ),
                                    // You can add onTap functionality here for details view
                                    onTap: () {
                                      // Optional: Navigate to place details or show a dialog
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Tapped on ${place['name']}')),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_loading && _nearbyPlaces.isEmpty && _position != null)
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'No nearby places found within 20km.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // Private method to build the unauthenticated state UI
  Widget _buildUnauthenticatedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded, // Lock icon for signed-out state
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Access Restricted',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please sign in to view nearby places and unlock full features of NomadDaily.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
                elevation: 0,
              ),
              child: const Text(
                'Sign In Now',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}