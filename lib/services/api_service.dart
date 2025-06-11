import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Fetch currency conversion rate from ExchangeRate.host
  Future<double?> fetchCurrencyRate(
    String from,
    String to, {
    double amount = 1.0,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.exchangerate.host/convert?from=$from&to=$to&amount=$amount',
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
  Future<Map<String, dynamic>?> fetchTimeZone(
    double lat,
    double lon, {
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse(
        'http://api.timezonedb.com/v2.1/get-time-zone?key=$apiKey&format=json&by=position&lat=$lat&lng=$lon',
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
    String type, {
    required String apiKey,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v2/places?categories=$type&filter=circle:$lon,$lat,2000&limit=10&apiKey=$apiKey',
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

  // --- Unit Conversion Logic ---
  double convertLength(double value, String from, String to) {
    double meters;
    switch (from) {
      case 'm':
        meters = value;
        break;
      case 'km':
        meters = value * 1000;
        break;
      case 'mi':
        meters = value * 1609.34;
        break;
      case 'ft':
        meters = value * 0.3048;
        break;
      case 'yd':
        meters = value * 0.9144;
        break;
      case 'in':
        meters = value * 0.0254;
        break;
      default:
        throw 'Unsupported length unit: $from';
    }
    switch (to) {
      case 'm':
        return meters;
      case 'km':
        return meters / 1000;
      case 'mi':
        return meters / 1609.34;
      case 'ft':
        return meters / 0.3048;
      case 'yd':
        return meters / 0.9144;
      case 'in':
        return meters / 0.0254;
      default:
        throw 'Unsupported length unit: $to';
    }
  }

  double convertWeight(double value, String from, String to) {
    double grams;
    switch (from) {
      case 'kg':
        grams = value * 1000;
        break;
      case 'lb':
        grams = value * 453.592;
        break;
      case 'g':
        grams = value;
        break;
      case 'oz':
        grams = value * 28.3495;
        break;
      default:
        throw 'Unsupported weight unit: $from';
    }
    switch (to) {
      case 'kg':
        return grams / 1000;
      case 'lb':
        return grams / 453.592;
      case 'g':
        return grams;
      case 'oz':
        return grams / 28.3495;
      default:
        throw 'Unsupported weight unit: $to';
    }
  }

  double convertTemperature(double value, String from, String to) {
    double celsius;
    switch (from) {
      case 'C':
        celsius = value;
        break;
      case 'F':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'K':
        celsius = value - 273.15;
        break;
      default:
        throw 'Unsupported temperature unit: $from';
    }
    switch (to) {
      case 'C':
        return celsius;
      case 'F':
        return (celsius * 9 / 5) + 32;
      case 'K':
        return celsius + 273.15;
      default:
        throw 'Unsupported temperature unit: $to';
    }
  }
}
