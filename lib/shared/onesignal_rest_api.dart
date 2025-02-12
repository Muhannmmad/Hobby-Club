import 'dart:convert';

import 'package:http/http.dart' as http;

class OnesignalRestApi {
  static Future<bool> sendPushNotification(List<String> playerIds, String title,
      String message, String chatID) async {
    var url = Uri.parse("https://onesignal.com/api/v1/notifications");
    var headers = {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization":
          "Key os_v2_app_7wh2vdwiubgjddetmjtf6v3nowrejoowjiluus5pzkijmslpngsfbhv42vq4yxzosz5772h5gsfuvy6p6ko5dntwtoh7jbd2zf2t6gy"
    };
    var body = jsonEncode({
      "app_id": "fd8faa8e-c8a0-4c91-8c93-62665f576d75",
      "include_player_ids": playerIds,
      "headings": {"en": title},
      "contents": {"en": message},
      "data": {"chatID": chatID},
    });
    var response = await http.post(url, headers: headers, body: body);
    print("Response: ${response.body}");
    return response.statusCode == 200;
  }
}
