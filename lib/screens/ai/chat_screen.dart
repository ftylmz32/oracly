import 'package:flutter/material.dart';

import '../../services/ai_service.dart';
import '../../services/memory_extractor.dart';
import '../../widgets/chat_input.dart';
import '../../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final AiService _aiService = AiService();
  final MemoryExtractor _memoryExtractor = MemoryExtractor();

  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      "text": "👋 Merhaba Fatih!\nBen Oracly. Sana nasıl yardımcı olabilirim?",
      "isUser": false,
    },
  ];


  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isLoading) return;


    setState(() {
      _messages.add({
        "text": text,
        "isUser": true,
      });

      _isLoading = true;
    });


    _controller.clear();

    _scrollToBottom();


    // 🧠 Mesajı hafıza açısından analiz et
    await _memoryExtractor.analyzeMessage(text);


    // 🤖 GPT cevabı
    final response = await _aiService.sendMessage(text);


    if (!mounted) return;


    setState(() {
      _messages.add({
        "text": response,
        "isUser": false,
      });

      _isLoading = false;
    });


    _scrollToBottom();
  }



  void _scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (!_scrollController.hasClients) return;

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }



  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Oracly AI"),
        centerTitle: true,
      ),


      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,

              itemBuilder: (context, index) {

                final message = _messages[index];

                return MessageBubble(
                  message: message["text"],
                  isUser: message["isUser"],
                );

              },
            ),
          ),



          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                "Oracly düşünüyor...",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),



          ChatInput(
            controller: _controller,
            onSend: _sendMessage,
          ),

        ],
      ),
    );
  }
}