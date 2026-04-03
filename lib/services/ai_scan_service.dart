import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class AiScanResult {
  final bool isFree;
  final int confidence; // 0–100
  final String reason;

  const AiScanResult({
    required this.isFree,
    required this.confidence,
    required this.reason,
  });
}

class AiScanService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  Future<AiScanResult> scanParkingPhoto(String imagePath) async {
    // Web cannot read local file paths — return a safe default
    if (kIsWeb) {
      return const AiScanResult(
        isFree: true,
        confidence: 70,
        reason: 'AI scan unavailable on web — spot marked as likely free',
      );
    }

    if (AppConfig.claudeApiKey.isEmpty || AppConfig.claudeApiKey == 'YOUR_CLAUDE_API_KEY') {
      debugPrint('AiScanService: claudeApiKey not set in AppConfig');
      return const AiScanResult(
        isFree: true,
        confidence: 70,
        reason: 'AI key not configured — spot marked as likely free',
      );
    }

    try {
      final file = File(imagePath);
      if (!file.existsSync()) return _fallback('Image not found');

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = imagePath.split('.').last.toLowerCase();
      final mediaType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': AppConfig.claudeApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': 'claude-sonnet-4-6',
              'max_tokens': 150,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'image',
                      'source': {
                        'type': 'base64',
                        'media_type': mediaType,
                        'data': base64Image,
                      },
                    },
                    {
                      'type': 'text',
                      'text':
                          'Is there a free parking spot visible in this photo? '
                          'Reply ONLY with JSON, no other text: '
                          '{"is_free": true/false, "confidence": 0-100, "reason": "one sentence"}',
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final text = (body['content'][0]['text'] as String).trim();
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
        if (jsonMatch != null) {
          final result = jsonDecode(jsonMatch.group(0)!);
          return AiScanResult(
            isFree: result['is_free'] as bool? ?? true,
            confidence: (result['confidence'] as num?)?.toInt() ?? 70,
            reason: result['reason'] as String? ?? 'Spot analyzed',
          );
        }
      }
      debugPrint('AiScanService HTTP ${response.statusCode}: ${response.body}');
      return _fallback('AI scan failed — spot marked as likely free');
    } catch (e) {
      debugPrint('AiScanService error: $e');
      return _fallback('Could not reach AI — spot marked as likely free');
    }
  }

  AiScanResult _fallback(String reason) =>
      AiScanResult(isFree: true, confidence: 65, reason: reason);
}
