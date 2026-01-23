import 'dart:io';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();
  static const String _lastCheckKey = 'last_sms_check_timestamp';

  /// Checks for new payment-related SMS messages received since the last check.
  Future<List<SmsMessage>> getUnreadPaymentMessages() async {
    // SMS reading is primarily supported on Android
    if (!Platform.isAndroid) return [];

    // 1. Request Permission
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      final result = await Permission.sms.request();
      if (!result.isGranted) return [];
    }

    // 2. Get Last Check Time
    final prefs = await SharedPreferences.getInstance();
    final lastCheckMillis = prefs.getInt(_lastCheckKey);
    // Default to 24 hours ago if first time, to avoid scanning entire history
    final lastCheckDate = lastCheckMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastCheckMillis)
        : DateTime.now().subtract(const Duration(days: 1));

    // 3. Query Messages (Fetch last 50 to be safe)
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 50,
    );

    // 4. Filter for Payments and Time
    final List<SmsMessage> paymentMessages = [];
    final now = DateTime.now();

    for (final msg in messages) {
      if (msg.date == null || msg.body == null) continue;

      // Only check messages received after the last check
      if (msg.date!.isAfter(lastCheckDate)) {
        if (_isPaymentRelated(msg.body!)) {
          paymentMessages.add(msg);
        }
      }
    }

    // 5. Update Last Check Time
    await prefs.setInt(_lastCheckKey, now.millisecondsSinceEpoch);

    return paymentMessages;
  }

  bool _isPaymentRelated(String body) {
    final lower = body.toLowerCase();
    // Keywords common in transaction SMS
    return lower.contains('debited') || lower.contains('spent') || 
           lower.contains('payment') || lower.contains('txn') || 
           lower.contains('bank') || lower.contains('card') || lower.contains('purchase');
  }
}