import 'package:speech_to_text/speech_to_text.dart';

class VoiceHandler {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

 
  Future<bool> initSpeech() async {
    return await _speech.initialize();
  }


  void startListening(Function(String) onResult) {
    _speech.listen(onResult: (result) {
      onResult(result.recognizedWords); 
    });
  }


  void stopListening() {
    _speech.stop();
  }

 
  Map<String, dynamic> parseCommand(String text) {
    String lowerText = text.toLowerCase();
    
   
    double amount = 0.0;
    try {
     
      final RegExp numberRegex = RegExp(r'(\d+)'); 
      final match = numberRegex.firstMatch(text);
      if (match != null) {
        amount = double.parse(match.group(0)!);
      }
    } catch (e) {
      amount = 0.0;
    }

  
    String category = 'Others';
    if (_contains(lowerText, ['food', 'burger', 'pizza', 'samosa', 'chai', 'coffee', 'khana'])) {
      category = 'Food';
    } else if (_contains(lowerText, ['travel', 'taxi', 'auto', 'uber', 'petrol', 'bus', 'kiraya'])) {
      category = 'Travel';
    } else if (_contains(lowerText, ['shopping', 'shirt', 'pant', 'shoes', 'kapde', 'buy'])) {
      category = 'Shopping';
    } else if (_contains(lowerText, ['movie', 'film', 'netflix', 'game'])) {
      category = 'Entertainment';
    }
    String title = text;

    return {
      'amount': amount,
      'category': category,
      'title': title,
    };
  }

  bool _contains(String text, List<String> keywords) {
    for (var word in keywords) {
      if (text.contains(word)) return true;
    }
    return false;
  }
}
