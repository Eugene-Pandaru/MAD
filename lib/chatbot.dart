import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    setState(() {
      _messages.add({"role": "user", "content": text});
    });
    String userQuery = text.toLowerCase();
    _controller.clear();

    String botReply = "I'm sorry, I don't understand that. Try asking about 'fever', 'delivery', or 'location'.";

    for (var keyword in _botKnowledge.keys) {
      if (userQuery.contains(keyword)) {
        botReply = _botKnowledge[keyword]!;
        break;
      }
    }

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🟢 Header (Matching home page style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Pharmacy Bot",
                    style: GoogleFonts.openSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // 🟢 Chat Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  bool isUser = _messages[index]['role'] == "user";
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isUser 
                            ? const Color(0xFF1392AB) 
                            : const Color(0xFF8DC6BC).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 0),
                          bottomRight: Radius.circular(isUser ? 0 : 20),
                        ),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: Text(
                        _messages[index]['content']!,
                        style: GoogleFonts.openSans(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🟢 Input Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: _controller,
                        onSubmitted: _handleMessage,
                        style: GoogleFonts.openSans(),
                        decoration: InputDecoration(
                          hintText: "Ask about medicine...",
                          hintStyle: GoogleFonts.openSans(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _handleMessage(_controller.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1392AB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
