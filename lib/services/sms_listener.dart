import 'package:flutter/material.dart';
import 'package:expense_tracker/services/sms_service.dart';
import 'package:expense_tracker/features/home/pages/new_transaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSms();
    });
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

  Future<void> _checkForSms() async {
    final service = SmsService();
    final messages = await service.getUnreadPaymentMessages();
  
    if (messages.isNotEmpty && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent closing by tapping outside
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              if (messages.isEmpty) {
                // Automatically close the dialog when all transactions are handled
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(dialogContext).pop();
                });
                return const SizedBox.shrink(); // Render nothing while closing
              }
  
              return AlertDialog(
                title: const Text('New Transactions Detected'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final amount = _extractAmount(msg.body ?? '');
                      
                      // A self-contained card for each detected transaction
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sms, color: Theme.of(context).primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(msg.sender ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  ),
                                  if (amount != null)
                                    Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(msg.body ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  child: const Text('ADD TRANSACTION'),
                                  onPressed: () {
                                    _navigateToAddTransaction(amount: amount);
                                    // Remove the item and rebuild the dialog's state
                                    setState(() {
                                      messages.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _navigateToAddTransaction({double? amount}) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (_) {
        return NewTransactionForm(
          (title, txAmount, category, date) async {
            await supabase.from('transactions').insert({
              'title': title,
              'amount': txAmount,
              'user_id': user.id,
              'category': category,
              'created_at': date.toUtc().toIso8601String(),
            });
          },
          initialAmount: amount,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}