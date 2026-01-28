import 'package:expense_tracker/utils/voice_handler.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// --- WIDGET IMPORTS ---
import 'package:expense_tracker/features/home/pages/new_transaction.dart';
import 'package:expense_tracker/features/home/widgets/expense_heatmap.dart';
import 'package:expense_tracker/features/home/widgets/chart.dart';
import 'package:expense_tracker/features/home/widgets/category_pie_chart.dart';

// --- UTILS & SERVICES IMPORTS ---
import 'package:expense_tracker/utils/category_icons.dart';
import 'package:expense_tracker/services/sms_service.dart';
import 'package:expense_tracker/models/transaction.dart';

class Homepage extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme; // Using VoidCallback is cleaner for void Function()

  const Homepage({
    super.key, 
    required this.isDark, 
    required this.toggleTheme
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // --- UI State Variables ---
  String? _activeFloatingChart;
  String _searchQuery = "";
  
  // --- Voice Variables ---
  final VoiceHandler _voiceHandler = VoiceHandler();
  bool _isListening = false;
  String _liveVoiceText = ""; 

  // --- Data Variables ---
  final _supabase = Supabase.instance.client;
  double _monthlyBudget = 5000.0;
  bool _isLoadingLimit = true;
  late final Stream<List<Map<String, dynamic>>> _transactionsStream;

  @override
  void initState() {
    super.initState();
    // Initialize Database Stream
    _transactionsStream = _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    // Initialize Services after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSms();
      _fetchMonthlyLimit();
      _initVoice();
    });
  }

  void _initVoice() async {
    await _voiceHandler.initSpeech();
    if (mounted) setState(() {});
  }

  // ==========================================
  // 🎙️ VOICE LOGIC (Toggle Style)
  // ==========================================
  void _toggleVoiceListener() {
    // CASE 1: STOPPING (User clicked to finish)
    if (_isListening) {
      _voiceHandler.stopListening();
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (_liveVoiceText.isEmpty || _liveVoiceText == "Listening...") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Didn't catch any voice command.")),
        );
        return;
      }

      // Parse & Add
      final command = _voiceHandler.parseCommand(_liveVoiceText);
      
      if (command['amount'] > 0) {
        _addNewTransaction(
          command['title'],
          command['amount'],
          command['category'],
          DateTime.now(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Success! Added ₹${command['amount']} for ${command['title']}"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("Could not parse: '$_liveVoiceText'"),
             backgroundColor: Colors.orange,
             behavior: SnackBarBehavior.floating,
            ),
        );
      }
      _liveVoiceText = ""; // Reset

    } else {
      // CASE 2: STARTING (User clicked to start)
      setState(() {
        _isListening = true;
        _liveVoiceText = "Listening...";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Listening... Tap button again to stop."),
          duration: Duration(days: 1), // Keep open
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _voiceHandler.startListening((resultText) {
        if (mounted) {
          setState(() {
            _liveVoiceText = resultText;
          });
          // Update Feedback
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hearing: '$_liveVoiceText'"),
              duration: const Duration(days: 1),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  // --- Logic: Chart Toggling ---
  void _toggleChart(String chartType) {
    setState(() {
      if (_activeFloatingChart == chartType) {
        _activeFloatingChart = null;
      } else {
        _activeFloatingChart = chartType;
      }
    });
  }

  // --- Logic: Filtering ---
  void runFilter(String enteredKeyword) {
    setState(() {
      _searchQuery = enteredKeyword;
    });
  }

  // --- Logic: Database Operations ---
  Future<void> _fetchMonthlyLimit() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase.from('users_settings').select().eq('user_id', user.id).limit(1);
      if (mounted && data.isNotEmpty) {
        setState(() {
          _monthlyBudget = (data[0]['monthly_limit'] as num).toDouble();
          _isLoadingLimit = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLimit = false);
    }
  }

  Future<void> _updateMonthlyLimit(double newLimit) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _monthlyBudget = newLimit);
    try {
      await _supabase.from('users_settings').upsert({
        'user_id': user.id,
        'monthly_limit': newLimit.toInt(),
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addNewTransaction(String txTitle, double txAmount, String txCategory, DateTime selectedDate) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('transactions').insert({
      'title': txTitle,
      'amount': txAmount,
      'user_id': user.id,
      'category': txCategory,
      'created_at': selectedDate.toUtc().toIso8601String(),
    });
  }

  Future<void> _deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
  }

  void _startAddNewTransaction(BuildContext ctx, {double? amount, String? title}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (_) {
        return NewTransactionForm(_addNewTransaction, initialAmount: amount, initialTitle: title);
      },
    );
  }

  void _logout() async {
    await _supabase.auth.signOut();
    // Navigation is handled by main.dart StreamBuilder
  }

  void _showEditBudgetDialog() {
    final limitController = TextEditingController(text: _monthlyBudget.toStringAsFixed(2));
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
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
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
       // Your SMS Dialog Logic (Preserved)
    }
  }

  // ==========================================
  // MAIN UI BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Use Theme brightness to determine dark mode for consistent UI
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('FinWiz', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: StreamBuilder(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final data = snapshot.data;
          final allTransactions = (data ?? []).map((e) {
            final tx = Transaction.fromMap(e);
            return Transaction(
              id: tx.id, title: tx.title, amount: tx.amount, category: tx.category,
              date: tx.date.toLocal(), userId: tx.userId,
            );
          }).toList();

          final currentMonthSpending = allTransactions
              .where((tx) => tx.date.year == DateTime.now().year && tx.date.month == DateTime.now().month)
              .fold(0.0, (sum, tx) => sum + tx.amount);
          
          double percentageUsed = (currentMonthSpending / _monthlyBudget).clamp(0.0, 1.0);
          Color budgetColor = percentageUsed > 1.0 ? Colors.red : (percentageUsed > 0.7 ? Colors.orange : Colors.green);

          final filteredTransactions = allTransactions.where((tx) {
            if (_searchQuery.isEmpty) return true;
            return tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   tx.category.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Stack(
            children: [
              // --- LAYER 1: BASE CONTENT ---
              Column(
                children: [
                  _buildBudgetCard(currentMonthSpending, _monthlyBudget - currentMonthSpending, percentageUsed, budgetColor),
                  
                  // Control Strip
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFilterButton('🔥 Intensity', 'heatmap'),
                        _buildFilterButton('📊 Daily', 'bar'),
                        _buildFilterButton('🥧 Categories', 'pie'),
                      ],
                    ),
                  ),

                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: TextField(
                      onChanged: runFilter,
                      decoration: InputDecoration(
                        hintText: 'Search Transactions',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),

                  // List
                  Expanded(
                    child: filteredTransactions.isEmpty 
                    ? const Center(child: Text("No transactions found"))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 100),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (ctx, index) {
                          final tx = filteredTransactions[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            color: isDarkMode ? Colors.grey[850] : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: getCategoryColor(tx.category).withOpacity(0.15),
                                child: Icon(getCategoryIcon(tx.category), color: getCategoryColor(tx.category), size: 22),
                              ),
                              title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(DateFormat.MMMd().format(tx.date)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('₹${tx.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode? Colors.white : Colors.black)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                    onPressed: () => _deleteTransaction(tx.id.toString()),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ),
                ],
              ),

              // --- LAYER 2: FLOATING CHARTS ---
              
              // 1. Heatmap (Left)
              _buildFloatingChartWrapper(
                isActive: _activeFloatingChart == 'heatmap',
                alignment: Alignment.centerLeft,
                offScreenOffset: const Offset(-1.2, 0),
                title: "Spending Intensity",
                child: ExpenseHeatmap(transactions: allTransactions), 
              ),

              // 2. Bar Chart (Bottom)
              _buildFloatingChartWrapper(
                isActive: _activeFloatingChart == 'bar',
                alignment: Alignment.bottomCenter,
                offScreenOffset: const Offset(0, 1.2),
                title: "Daily Analysis",
                child: Chart(recentTransactions: allTransactions), 
              ),

              // 3. Pie Chart (Right) - Scrollable
              _buildFloatingChartWrapper(
                isActive: _activeFloatingChart == 'pie',
                alignment: Alignment.centerRight,
                offScreenOffset: const Offset(1.2, 0),
                title: "Category Breakdown",
                // The CategoryPieChart is designed to manage its own layout and scrolling.
                child: CategoryPieChart(transactions: allTransactions),
              ),
            ],
          );
        },
      ),
      
      // ==========================================
      // 🚀 VERTICAL BUTTON LAYOUT
      // ==========================================
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min, 
        children: [
          // Voice Button (Smaller)
          FloatingActionButton.small(
            heroTag: "voice_btn",
            onPressed: _toggleVoiceListener, 
            backgroundColor: _isListening ? Colors.redAccent : Colors.grey[800],
            child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
          ),
          
          const SizedBox(height: 15),
          
          // Add Button (Main)
          FloatingActionButton(
            heroTag: "add_btn",
            onPressed: () => _startAddNewTransaction(context),
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Drawer _buildDrawer(BuildContext context) {
    final user = _supabase.auth.currentUser;
    // Use widget.isDark for the toggle switch state
    final isDark = widget.isDark;
    final primaryColor = Theme.of(context).primaryColor;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('FinWiz', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                if (user != null) Text(user.email ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: (value) => widget.toggleTheme(),
            secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(double spent, double remaining, double percent, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [Colors.grey[900]!, Colors.grey[800]!] 
            : [Theme.of(context).primaryColor.withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              InkWell(
                onTap: _showEditBudgetDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.edit, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: percent, color: color, backgroundColor: Colors.grey.withOpacity(0.2), minHeight: 12),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spent', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('₹${spent.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Remaining', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('₹${remaining.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String chartKey) {
    bool isActive = _activeFloatingChart == chartKey;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _toggleChart(chartKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
            ? Theme.of(context).primaryColor 
            : (isDarkMode ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : Colors.grey.withOpacity(0.2)),
          boxShadow: isActive ? [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : (isDarkMode ? Colors.white : Colors.black87), 
            fontWeight: FontWeight.w600,
            fontSize: 13
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingChartWrapper({
    required bool isActive,
    required Alignment alignment,
    required Offset offScreenOffset,
    required Widget child,
    required String title,
  }) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSlide(
      offset: isActive ? Offset.zero : offScreenOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      child: Align(
        alignment: alignment,
        child: Container(
          width: size.width * 0.92,
          height: 420, 
          margin: const EdgeInsets.only(top: 80), 
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 15, right: 15,
                child: InkWell(
                  onTap: () => setState(() => _activeFloatingChart = null),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}