import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final String _baseUrl = dotenv.env['GOOGLE_APPS_SCRIPT_BASE_URL'] ?? '';

  static Future<dynamic> fetchFromScript(String type) async {
    if (_baseUrl.isEmpty) {
      throw Exception('GOOGLE_APPS_SCRIPT_BASE_URL mangler i .env filen');
    }

    final url = '$_baseUrl?type=$type';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Fejl ved hentning af data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fejl ved netværkskald: $e');
    }
  }
}
