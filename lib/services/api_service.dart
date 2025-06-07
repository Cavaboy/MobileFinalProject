import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Add API logic for currency, timezone, and places

  // Fetch currency conversion rate from ExchangeRate.host
  Future<double?> fetchCurrencyRate(String from, String to) async {
    try {
      final url = Uri.parse(
        'https://api.exchangerate.host/convert?from=$from&to=$to',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['result'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch timezone info using TimeZoneDB (replace with your API key if needed)
  Future<Map<String, dynamic>?> fetchTimeZone(double lat, double lon) async {
    try {
      // Example using TimeZoneDB free API (replace with your key if needed)
      final url = Uri.parse(
        'http://api.timezonedb.com/v2.1/get-time-zone?key=YOUR_API_KEY&format=json&by=position&lat=$lat&lng=$lon',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch nearby places using Geoapify Places API (replace with your API key)
  Future<List<Map<String, dynamic>>> fetchNearbyPlaces(
    double lat,
    double lon,
    String type,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v2/places?categories=$type&filter=circle:$lon,$lat,2000&limit=10&apiKey=YOUR_GEOAPIFY_KEY',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['features'] as List)
            .map((e) => e['properties'] as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Unit converters
  double kmToMiles(double km) => km * 0.621371;
  double celsiusToFahrenheit(double c) => c * 9 / 5 + 32;
}
