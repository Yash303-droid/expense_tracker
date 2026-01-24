import 'package:flutter/material.dart';
import 'package:expense_tracker/services/sms_service.dart';

class SmsListener extends StatefulWidget {
  final Widget child;
  const SmsListener({super.key, required this.child});

  @override
  State<SmsListener> createState() => _SmsListenerState();
}

class _SmsListenerState extends State<SmsListener> {
  @override
  void initState() {
    super.initState();
    // Check for SMS after the widget is built
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _checkForSms();
    // });
  }

  double? _extractAmount(String body) {
    // Regex to find amounts like Rs. 100, INR 500.50, etc.
    final RegExp regex = RegExp(r'(?:Rs\.?|INR|₹)\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false);
    final match = regex.firstMatch(body);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  String _extractMerchant(String body) {
    // Attempt to extract merchant name after 'at', 'to', or 'on'
    final RegExp regex = RegExp(r'(?:at|to|on)\s+([A-Za-z0-9\s\.]+?)(?:\s+(?:on|from|using|with|for|\.|$))', caseSensitive: false);
    final match = regex.firstMatch(body);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return '';
  }

  Future<void> _checkForSms() async {
    final service = SmsService();
    final messages = await service.getUnreadPaymentMessages();

    if (messages.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('New Transactions Detected'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final amount = _extractAmount(msg.body ?? '');
                
                return ListTile(
                  leading: Icon(Icons.payment, color: Theme.of(context).primaryColor),
                  title: Text(msg.sender ?? 'Unknown'),
                  subtitle: Text(
                    msg.body ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: amount != null 
                    ? Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                    : null,
                  isThreeLine: true,
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAddTransaction(
                      amount: amount,
                      merchant: _extractMerchant(msg.body ?? ''),
                      sender: msg.sender,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToAddTransaction({double? amount, String? merchant, String? sender}) {
    

    // Temporary feedback to show it works
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detected: ₹$amount at ${merchant?.isNotEmpty == true ? merchant : sender}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}