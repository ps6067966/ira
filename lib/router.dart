import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ira/screens/chat_screen.dart';
import 'package:ira/screens/chatbot_selection_screen.dart';
import 'package:ira/screens/home_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/select-chatbot',
      name: 'select-chatbot',
      builder: (context, state) => const ChatbotSelectionScreen(),
    ),
    GoRoute(
      path: '/chat/:sessionId',
      name: 'chat',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId']!;
        return ChatScreen(sessionId: sessionId);
      },
    ),
  ],
);
