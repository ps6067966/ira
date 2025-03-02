import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ira/models/chatbot_model.dart';

// Model for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Model for chat session
class ChatSessionData {
  final String id;
  final ChatbotModel chatbot;
  final List<ChatMessage> messages;
  final GenerativeModel model;
  final ChatSession chatSession;

  ChatSessionData({
    required this.id,
    required this.chatbot,
    required this.model,
    required this.chatSession,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  ChatSessionData copyWith({
    String? id,
    ChatbotModel? chatbot,
    List<ChatMessage>? messages,
    GenerativeModel? model,
    ChatSession? chatSession,
  }) {
    return ChatSessionData(
      id: id ?? this.id,
      chatbot: chatbot ?? this.chatbot,
      messages: messages ?? this.messages,
      model: model ?? this.model,
      chatSession: chatSession ?? this.chatSession,
    );
  }
}

// Provider for the selected chatbot
final selectedChatbotProvider = StateProvider<ChatbotModel>((ref) {
  return predefinedChatbots.first;
});

// Provider for all chat sessions
final chatSessionsProvider =
    StateNotifierProvider<ChatSessionsNotifier, List<ChatSessionData>>((ref) {
  return ChatSessionsNotifier();
});

// Provider for the current chat session
final currentChatSessionProvider = StateProvider<String?>((ref) {
  return null;
});

// Provider that returns the current chat session data
final currentChatSessionDataProvider = Provider<ChatSessionData?>((ref) {
  final currentSessionId = ref.watch(currentChatSessionProvider);
  final sessions = ref.watch(chatSessionsProvider);

  if (currentSessionId == null) return null;

  try {
    return sessions.firstWhere(
      (session) => session.id == currentSessionId,
    );
  } catch (e) {
    return null;
  }
});

// Notifier for managing chat sessions
class ChatSessionsNotifier extends StateNotifier<List<ChatSessionData>> {
  ChatSessionsNotifier() : super([]);

  // Create a new chat session
  Future<String> createChatSession(ChatbotModel chatbot, String apiKey) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
    );

    final chatSession = model.startChat();

    // Set the AI personality
    try {
      await chatSession.sendMessage(Content.text(chatbot.personalityPrompt));
    } catch (e) {
      log('Failed to set AI personality: $e');
    }

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final newSession = ChatSessionData(
      id: sessionId,
      chatbot: chatbot,
      model: model,
      chatSession: chatSession,
    );

    state = [...state, newSession];
    return sessionId;
  }

  // Send a message in a chat session
  Future<void> sendMessage(String sessionId, String message) async {
    if (message.trim().isEmpty) return;

    // Find the session
    final sessionIndex = state.indexWhere((session) => session.id == sessionId);
    if (sessionIndex == -1) return;

    final session = state[sessionIndex];

    // Add user message
    final userMessage = ChatMessage(text: message, isUser: true);
    final updatedMessages = [...session.messages, userMessage];

    // Update state with user message
    state = [
      ...state.sublist(0, sessionIndex),
      session.copyWith(messages: updatedMessages),
      ...state.sublist(sessionIndex + 1),
    ];

    try {
      // Send message to AI
      final response =
          await session.chatSession.sendMessage(Content.text(message));

      final responseText = response.text;
      if (responseText != null) {
        // Add AI response
        final aiMessage = ChatMessage(text: responseText, isUser: false);
        final updatedMessagesWithAi = [...updatedMessages, aiMessage];

        // Update state with AI response
        state = [
          ...state.sublist(0, sessionIndex),
          session.copyWith(messages: updatedMessagesWithAi),
          ...state.sublist(sessionIndex + 1),
        ];
      }
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage(
        text: "Sorry, I encountered an error. Please try again.",
        isUser: false,
      );
      final updatedMessagesWithError = [...updatedMessages, errorMessage];

      // Update state with error message
      state = [
        ...state.sublist(0, sessionIndex),
        session.copyWith(messages: updatedMessagesWithError),
        ...state.sublist(sessionIndex + 1),
      ];
    }
  }

  // Delete a chat session
  void deleteChatSession(String sessionId) {
    state = state.where((session) => session.id != sessionId).toList();
  }
}
