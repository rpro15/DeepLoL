import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';

class MemeApiService {
  static final MemeApiService _instance = MemeApiService._();
  factory MemeApiService() => _instance;
  MemeApiService._();

  Future<String> generateCaption(String context, {String style = 'абсурд'}) async {
    try {
      final resp = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.generateEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt_context': context, 'style': style}),
          )
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['text'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<List<String>> generateDialogueCaptions(String context) async {
    final caption1 = await generateCaption('$context — первая мысль');
    final caption2 = await generateCaption('$context — реакция');
    return [caption1, caption2];
  }
}
