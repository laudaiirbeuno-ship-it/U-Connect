import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiRelatorio {
  static Future<List<dynamic>> getHistory({
    required String page,
    required String deviceId,
    required String fromDate,
    required String fromTime,
    required String toDate,
    required String toTime,
    required String userApiHash,
  }) async {
    final url = Uri.parse(
        'https://web.unnicatelemetria.com.br/api/get_history'
        '?device_id=$deviceId'
        '&from_date=$fromDate'
        '&from_time=$fromTime'
        '&to_date=$toDate'
        '&to_time=$toTime'
        '&lang=pt'
        '&user_api_hash=$userApiHash'
        '&page=$page');

    final response = await http.get(url, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['items'] ?? [];
    } else {
      return [];
    }
  }
}
