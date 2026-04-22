import 'package:flutter/material.dart';
import 'package:mad/footer.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "bot", "content": "Hello! I am the NoSakit Assistant. Ask me about medicine, delivery, or our location!"}
  ];

  // --- KEYWORD DATABASE ---
  // You can add as many keywords and answers as you like here
  final Map<String, String> _botKnowledge = {
    "fever": "For fever, we recommend Paracetamol. Take 1-2 tablets every 4-6 hours.",
    "cough": "For dry cough, try our Cough Syrup. For wet cough, please consult a pharmacist.",
    "delivery": "Standard delivery takes 3-5 days (RM 5), Express takes 1 day (RM 12).",
    "payment": "We accept Credit Cards, FPX Online Banking, and E-wallets like TNG.",
    "location": "We are located at 123, Jalan Pharmacy, Kuala Lumpur. Open 9AM - 10PM.",
    "hello": "Hi there! How can I help you today?",
    "hi": "Hello! Need help finding a medicine?",
    "price": "You can check all prices in our 'Product' section on the home screen.",
    "vitamin": "We have Vitamin C and Multivitamins in stock. Check the 'Vitamin' category!",
  };

  void _handleMessage(String text) {
    if (text.trim().isEmpty) return;

    // 1. Add User Message to UI
    setState(() {
      _messages.add({"role": "user", "content": text});
    });
    String userQuery = text.toLowerCase();
    _controller.clear();

    // 2. Logic to find a match
    String botReply = "I'm sorry, I don't understand that. Try asking about 'fever', 'delivery', or 'location'.";

    // Loop through keys to see if the user mentioned any keyword
    for (var keyword in _botKnowledge.keys) {
      if (userQuery.contains(keyword)) {
        botReply = _botKnowledge[keyword]!;
        break; // Stop at the first match
      }
    }

    // 3. Simulate a short delay to make it feel more "real"
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add({"role": "bot", "content": botReply});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pharmacy Bot"), backgroundColor: Colors.green),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]['role'] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    child: Text(_messages[index]['content']!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _handleMessage,
                    decoration: const InputDecoration(
                      hintText: "Type 'fever', 'delivery'...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: () => _handleMessage(_controller.text),
                ),
              ],
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}