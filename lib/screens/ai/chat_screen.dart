import 'package:flutter/material.dart';

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

  final List<Map<String, dynamic>> _messages = [
    {
      "text": "👋 Merhaba Fatih!\nBen Oracly. Sana nasıl yardımcı olabilirim?",
      "isUser": false,
    },
  ];

  void _sendMessage() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        "text": text,
        "isUser": true,
      });
    });

    _controller.clear();

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _messages.add({
          "text":
              "Bunu söylediğin için teşekkür ederim 😊\nŞimdilik örnek cevap veriyorum. Çok yakında GPT-5.5 ile gerçek cevaplar vereceğim.",
          "isUser": false,
        });
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
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

          ChatInput(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}