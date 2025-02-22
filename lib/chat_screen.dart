import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ira/gemini_api_key.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: geminiApiKey,
    );
    _chat = _model.startChat();
    _setAiPersonality();
  }

  Future<void> _setAiPersonality() async {
    try {
      await _chat.sendMessage(
        Content.text(
            'You are a funky and friendly AI assistant who always responds in Hinglish (mix of Hindi and English) with a fun attitude. Use casual language, popular Hindi slang, and Bollywood references when appropriate. Keep responses light and entertaining. For example, instead of "Hello, how can I help you?" say "Kya scene hai bro? Main hoon na to tension kaiko!". Add fun emojis occasionally. Never break character and always maintain this Hinglish style.'),
      );
    } catch (e) {
      debugPrint('Failed to set AI personality: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(
        Content.text(text),
      );

      final responseText = response.text;
      if (responseText != null) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: responseText,
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(
          const ChatMessage(
            text: "Sorry, I encountered an error. Please try again.",
            isUser: false,
          ),
        );
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ira',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 32,
            fontFamily: 'Arial Black',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFFE566),
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFF90B3), // Bright pink background
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return message
                      .animate()
                      .fade(duration: const Duration(milliseconds: 300))
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        duration: const Duration(milliseconds: 300),
                      );
                },
              ),
            ),
            if (_isTyping)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF98FF98), // Mint green
                        border: Border.all(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDot(),
                          const SizedBox(width: 4),
                          _buildDot(delay: 0.2),
                          const SizedBox(width: 4),
                          _buildDot(delay: 0.4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFE566), // Yellow
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildTextComposer(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({double delay = 0.0}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(5),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .scale(
          duration: const Duration(milliseconds: 600),
          begin: const Offset(1, 1),
          end: const Offset(0.5, 0.5),
          delay: Duration(milliseconds: (delay * 1000).toInt()),
          curve: Curves.easeInOut,
        );
  }

  Widget _buildTextComposer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.0),
              ),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF98FF98), // Mint green
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.black,
              ),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _handleSubmitted(_messageController.text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF98FF98) : Colors.white,
                      border: Border.all(color: Colors.black, width: 3),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: InkWell(
                      onLongPress: () => _copyToClipboard(context),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser ? const Color(0xFF98FF98) : const Color(0xFFFFE566),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person : Icons.smart_toy,
          size: 20,
          color: Colors.black,
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        width: 200,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
