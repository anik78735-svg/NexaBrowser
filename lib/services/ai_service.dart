import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = "https://nexa-ai-wbxo.onrender.com";

  //---------------------------------------------------------------------
  // Sends [message] to the Nexa AI backend's /chat endpoint and returns
  // the reply as plain text. [history] is optional — pass previous
  // turns as [["user msg", "ai reply"], ...] if you want the model to
  // remember context; leave it null/empty for a single-shot question.
  //---------------------------------------------------------------------
  static Future<String> ask(String message, {List<List<String>>? history}) async {
    final uri = Uri.parse("$_baseUrl/chat");

    try {
      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "message": message,
              "history": history ?? [],
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        return "AI backend error (status ${response.statusCode}). "
            "${response.body.length > 200 ? response.body.substring(0, 200) : response.body}";
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      final String? reply = body["reply"] as String?;

      if (reply == null || reply.trim().isEmpty) {
        return "No response received from Nexa AI.";
      }

      return reply;
    } on TimeoutException {
      return "Nexa AI server is waking up (free tier sleeps when idle). "
          "Please try again in 30-40 seconds.";
    } catch (e) {
      return "Connection error: Unable to reach Nexa AI. ($e)";
    }
  }
}