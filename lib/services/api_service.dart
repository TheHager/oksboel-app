import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://script.google.com/macros/s/AKfycbyHtOHT7rN8FPBN9GvpAeF6WgK9snTmZhQIF-e0mhFy36e30cioVCp20QYfwc84llrQMg/exec';

  static Future<dynamic> fetchFromScript(String type) async {
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
