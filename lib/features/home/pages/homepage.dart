import 'package:expense_tracker/features/home/pages/new_transaction.dart';
import 'package:expense_tracker/utils/category_icons.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/home/widgets/chart.dart';
import 'package:expense_tracker/services/sms_service.dart';
import 'package:expense_tracker/features/home/widgets/category_pie_chart.dart';
class Homepage extends StatefulWidget {
  final VoidCallback? toggleTheme;
  final bool? isDark;

   Homepage({super.key, this.toggleTheme, this.isDark=false});
  // ignore: non_constant_identifier_names
  

  double get totalspending{
    return 0.0;
  }

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final _supabase = Supabase.instance.client;
  bool _isLoadingLimit = true;
  double _monthlyBudget = 5000.0;
  late final Stream<List<Map<String, dynamic>>> _transactionsStream;
bool _isPieChartVisible=false;
String _searchQuery="";
void runFilter(String enteredKeyword){
  setState(() {
    _searchQuery=enteredKeyword;
  });}

  @override
  void initState() {
    super.initState();
    _transactionsStream = _supabase.from('transactions').stream(primaryKey: ['id']).order('created_at',ascending: false);

    // Check for SMS after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSms();
      _fetchMonthlyLimit();
    });
  }

  Future<void>_fetchMonthlyLimit()async{
    final user = _supabase.auth.currentUser;
    if(user==null) return;
   try{
     final data = await _supabase.from('users_settings').select().eq('user_id',user.id).limit(1);
     if(data.isNotEmpty){
       setState(() {
         _monthlyBudget=(data[0]['monthly_limit'] as num).toDouble();
         _isLoadingLimit=false;
       });
     }
   }catch(e){
     setState(() {
       _isLoadingLimit=false;
     });
     
   }
  }
  Future<void>_updateMonthlyLimit(double newLimit)async{
    final user = _supabase.auth.currentUser;
    if(user==null) return;
    setState(() {
       _monthlyBudget=newLimit;
     });
   try{
     await _supabase.from('users_settings').upsert({
       'user_id': user.id,
       'monthly_limit': newLimit.toInt(),
     });
   }catch(e){
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
     }
   }
  }
  void _showEditBudgetDialog() {
    final limitController = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Monthly Limit'),
        content: TextField(
          controller: limitController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter new limit'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              final newLimit = double.tryParse(limitController.text) ?? 0.0;
              _updateMonthlyLimit(newLimit);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  Future<void> _checkForSms() async {
    final service = SmsService();
    final messages = await service.getUnreadPaymentMessages();

    if (messages.isNotEmpty && mounted) {
      final currentMessages = messages.toList();
      final List<String> categories = ['Food','Travel','Shopping','Bills','Entertainment','Health','Others'];
      final List<String> selectedCategories = List.filled(currentMessages.length, 'Others', growable: true);
      final List<TextEditingController> amountControllers = currentMessages.map((msg) {
        final amount = _extractAmount(msg.body ?? '');
        return TextEditingController(text: amount?.toString() ?? '');
      }).toList();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('New Transactions Detected', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: currentMessages.isEmpty
                    ? const Center(child: Text('No more transactions'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: currentMessages.length,
                        itemBuilder: (context, index) {
                          final msg = currentMessages[index];
                          final merchant = _extractMerchant(msg.body ?? '');

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.payment, color: Colors.purple),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg.sender ?? 'Unknown',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              msg.body ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: amountControllers[index],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Amount',
                                      prefixText: '₹ ',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: selectedCategories[index],
                                        items: categories.map((String category) {
                                          return DropdownMenuItem<String>(
                                            value: category,
                                            child: Text(category),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          setStateDialog(() {
                                            selectedCategories[index] = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final enteredAmount = double.tryParse(amountControllers[index].text) ?? 0.0;
                                        await _addNewTransaction(
                                          merchant.isNotEmpty
                                              ? merchant
                                              : (msg.sender ?? 'Unknown'),
                                          enteredAmount,
                                          selectedCategories[index],
                                          DateTime.now(),
                                        );
                                        setStateDialog(() {
                                          currentMessages.removeAt(index);
                                          selectedCategories.removeAt(index);
                                          amountControllers[index].dispose();
                                          amountControllers.removeAt(index);
                                        });
                                        if (currentMessages.isEmpty) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text('Add Transaction', style: TextStyle(fontSize: 16)),
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
                TextButton(
                  onPressed: () {
                    for (var controller in amountControllers) {
                      controller.dispose();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  double? _extractAmount(String body) {
    final RegExp regex = RegExp(r'(?:Rs\.?|INR|₹)\s*(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false);
    final match = regex.firstMatch(body);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  String _extractMerchant(String body) {
    final RegExp regex = RegExp(r'(?:at|to|on)\s+([A-Za-z0-9\s\.]+?)(?:\s+(?:on|from|using|with|for|\.|$))', caseSensitive: false);
    final match = regex.firstMatch(body);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return '';
  }

  Future<void>_addNewTransaction(String txTile, double txAmount, String txCategory,DateTime selectedDate)async{
    final user = _supabase.auth.currentUser;
    if(user==null) return;
    await _supabase.from('transactions').insert({
      'title':txTile,
      'amount':txAmount,
      'user_id':user.id,
      'category':txCategory,
      'created_at':selectedDate.toUtc().toIso8601String(),
    });
  }

  void _startAddNewTransaction(BuildContext ctx, {double? amount, String? title}){
    showModalBottomSheet(context: ctx, builder: (_){
      // Ensure NewTransactionForm is updated to accept these parameters
      return NewTransactionForm(_addNewTransaction, initialAmount: amount, initialTitle: title);
    });
      
    }
  void _logout() async {
    await _supabase.auth.signOut();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacementNamed('/login');
    // Optionally, navigate the user back to the login screen
  }
 Future<void>_deleteTransaction(String id)async{
  await _supabase.from('transactions').delete().eq('id',id);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Transaction deleted')),
  );
 }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Tracker'),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDark! ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),  
        ],
      ),body: StreamBuilder(stream: _transactionsStream,
      builder: (context,snapshot){
        if(snapshot.connectionState==ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }
        if(snapshot.hasError){
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data=snapshot.data ;
        if(data==null || data.isEmpty){
          return const Center(child: Text('No transactions found.'));
        }
        final allTransactions = data.map((e) {
          final tx = Transaction.fromMap(e);
          return Transaction(
            id: tx.id,
            title: tx.title,
            amount: tx.amount,
            category: tx.category,
            date: tx.date.toLocal(),
            userId: tx.userId,
          );
        }).toList();
        final transactions= allTransactions ;
        final Filteredtransactions= allTransactions.where((tx){
          if(_searchQuery.isEmpty){
            return true;
          }
          return tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) || tx.category.toLowerCase().contains(_searchQuery.toLowerCase());

        }).toList();
        final currentMonthSpending = transactions
            .where((tx) =>
                tx.date.year == DateTime.now().year &&
                tx.date.month == DateTime.now().month)
            .fold(0.0, (sum, tx) => sum + tx.amount);
            double budgetlimit=_monthlyBudget;
            double remainingBudget=budgetlimit-currentMonthSpending;
            double percentageUsed=(currentMonthSpending/budgetlimit).clamp(0.0, 1.0);
            if(percentageUsed>1.0){
              percentageUsed=1.0;
            }
            Color budgetColor=Colors.green;
            if(percentageUsed>0.7 && percentageUsed<=1.0){
              budgetColor=Colors.red;
            }else if(percentageUsed>0.3 && percentageUsed<=0.7){
              budgetColor=Colors.yellow;
            }else if(percentageUsed<=0.3){
              budgetColor=Colors.green;
            }else{
              budgetColor=Colors.red;
            }
        return SingleChildScrollView(
          child: Column(
            children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Show Category Pie Chart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Switch(
                  value: _isPieChartVisible,
                  onChanged: (value) {
                    setState(() {
                      _isPieChartVisible = value;
                    });
                  },
                ),
              ],
            ),        ),
            if (_isPieChartVisible) CategoryPieChart(transactions: transactions),
            const SizedBox(height: 10),
            Chart(recentTransactions: transactions),
            const SizedBox(height: 10),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Monthly Budget',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.purple),
                            onPressed: _showEditBudgetDialog,
                          ), 
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentageUsed,
                        backgroundColor: Colors.grey[300],
                        color: budgetColor,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Spent: \$${currentMonthSpending.toStringAsFixed(2)} / \$${budgetlimit.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining Budget: \$${remainingBudget.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value){
                runFilter(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search Transactions',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),),
            const SizedBox(height: 10),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: Filteredtransactions.length,
                itemBuilder: (ctx,index){
                  final tx=Filteredtransactions[index];
                  return ListTile(
                    title: Text(tx.title),
                    subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: getCategoryColor(tx.category),
                      child: Icon(
                        getCategoryIcon(tx.category),
                        color: Colors.white,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\$${tx.amount.toStringAsFixed(2)}'),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color:Colors.red,
                          onPressed: ()=>_deleteTransaction(tx.id.toString()),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>_startAddNewTransaction(context),
        tooltip: 'Add Transaction',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 5,
        highlightElevation: 10,

        child: const Icon(Icons.add),
      ),
    );
  }
}
