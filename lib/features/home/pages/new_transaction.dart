import 'package:expense_tracker/utils/voice_handler.dart';
import 'package:flutter/material.dart';

class NewTransactionForm extends StatefulWidget {
  // Ye function hum HomePage se receive karenge
  // Taaki jab user 'Add' dabaye, to HomePage ko data mil jaye
  final Function(String, double,String, DateTime) addTx;
  final double? initialAmount;
  final String? initialTitle;

  const NewTransactionForm(this.addTx, {super.key, this.initialAmount, this.initialTitle});

  @override
  State<NewTransactionForm> createState() => _NewTransactionFormState();
  
}

class _NewTransactionFormState extends State<NewTransactionForm> {
  // Input Controllers (Text read karne ke liye)
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final VoiceHandler _voiceHandler = VoiceHandler();
bool _isListening = false; // Button ka color badalne ke liye

@override

void _listen() {
  if (!_isListening) {
    // Start Listening
    setState(() => _isListening = true);
    _voiceHandler.startListening((text) {
      // Jaise hi kuch sunayi de, process karo
      final data = _voiceHandler.parseCommand(text);

      setState(() {
        // Form Fields Auto-Fill karo!
        titleController.text = data['title'];
        amountController.text = data['amount'] == 0.0 ? '' : data['amount'].toStringAsFixed(0);
        selectedCategory = data['category'];
        // _isListening = false; // Auto-stop mat karo, user ko bolne do
      });
    });
  } else {
    // Stop Listening
    _voiceHandler.stopListening();
    setState(() => _isListening = false);
  }
}

  @override
  void initState() {
    super.initState();
    _voiceHandler.initSpeech();
    if (widget.initialTitle != null) {
      titleController.text = widget.initialTitle!;
    }
    if (widget.initialAmount != null) {
      amountController.text = widget.initialAmount.toString();
    }
  }

  String selectedCategory='Food';
  DateTime? selectedDate = DateTime.now();
  void _presentDatePicker(){
    showDatePicker(
      context: context, 
      initialDate: DateTime.now(), 
      firstDate: DateTime (2020), 
      lastDate: DateTime.now(),
      ).then((pickedDate){
        if(pickedDate==null){
          return;
        }
        setState(() {
          selectedDate=pickedDate;
        });
      });
  }
  final List<String> categories=['Food','Travel','Shopping','Bills','Entertainment','Health','Others'];

  // Data submit karne ka logic
  void _submitData() {
    final enteredTitle = titleController.text;
    
    // Amount ko String se Double mein convert karo. 
    // Agar empty hai to -1 maan lo taaki crash na ho.
    final enteredAmount = double.tryParse(amountController.text) ?? -1;

    // Validation: Agar title khali hai ya amount negative hai to kuch mat karo
    if (enteredTitle.isEmpty || enteredAmount <= 0) {
      return;
    }
  
  final dateToSubmit=selectedDate??DateTime.now();


    // Parent (HomePage) wala function call karo
    widget.addTx(
      enteredTitle,
      enteredAmount,
      selectedCategory,
      dateToSubmit,
    );

    // Form band karo (Close the bottom sheet)
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Padding allow karega ki keyboard aane par UI adjust ho
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        // Ye niche wala logic keyboard ke liye hai
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Jitni jagah chahiye utni hi le
          children: <Widget>[
            const Text(
              'Add New Transaction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Title Input
            TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title),
              ),
              controller: titleController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // Amount Input
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: '₹ ',
              ),
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSubmitted: (_) => _submitData(), // Enter dabane par submit
            ),

            const SizedBox(height: 16),
            // Category Dropdown
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _presentDatePicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              selectedDate == null
                                  ? 'No Date'
                                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                              style: const TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.calendar_today, size: 20, color: Theme.of(context).primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).primaryColor), // Background Color: Colors.transparent,
              child: Row(
                
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Add Transaction',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child:GestureDetector(
                      onTap: _listen,
                      child: CircleAvatar(
                        backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
                        radius: 24,
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
