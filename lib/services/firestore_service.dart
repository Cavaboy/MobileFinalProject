import 'dart:convert';
import 'package:http/http.dart' as http;

class FirestoreService {
  final String projectId;
  final String apiKey;

  FirestoreService({required this.projectId, required this.apiKey});

  // Get a document
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$docId?key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Get all documents in a collection
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection?key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['documents'] != null) {
        return List<Map<String, dynamic>>.from(data['documents']);
      }
    }
    return [];
  }

  // Add a document (auto ID)
  Future<Map<String, dynamic>?> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection?key=$apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"fields": _toFirestoreFields(data)}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Set a document (with custom ID)
  Future<Map<String, dynamic>?> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$docId?key=$apiKey';
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"fields": _toFirestoreFields(data)}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Update a document (partial update)
  Future<bool> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$docId?key=$apiKey';
    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"fields": _toFirestoreFields(data)}),
    );
    return response.statusCode == 200;
  }

  // Delete a document
  Future<bool> deleteDocument(String collection, String docId) async {
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$docId?key=$apiKey';
    final response = await http.delete(Uri.parse(url));
    return response.statusCode == 200;
  }

  // Helper: Convert Dart map to Firestore REST API fields
  Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
    final Map<String, dynamic> fields = {};
    data.forEach((key, value) {
      if (value is String) {
        fields[key] = {"stringValue": value};
      } else if (value is int) {
        fields[key] = {"integerValue": value.toString()};
      } else if (value is double) {
        fields[key] = {"doubleValue": value};
      } else if (value is bool) {
        fields[key] = {"booleanValue": value};
      } else if (value is Map) {
        fields[key] = {
          "mapValue": {
            "fields": _toFirestoreFields(Map<String, dynamic>.from(value)),
          },
        };
      } else if (value is List) {
        fields[key] = {
          "arrayValue": {
            "values":
                value
                    .map((v) => _toFirestoreFields({"value": v})["value"])
                    .toList(),
          },
        };
      }
    });
    return fields;
  }
}