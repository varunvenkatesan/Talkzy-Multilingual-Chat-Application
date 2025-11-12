import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';

enum ChatThemeType { defaultTheme, ocean, forest, sunset, midnight }

class ChatPageBackground {
  final Gradient? gradient;
  final Color color;
  const ChatPageBackground({this.gradient, required this.color});
}

class ChatAppBarBackground {
  final Gradient? gradient;
  final Color color;
  final Color bottomBorderColor;
  const ChatAppBarBackground({this.gradient, required this.color, required this.bottomBorderColor});
}

class BubbleTheme {
  final Gradient? outgoingGradient;
  final Color outgoingColor;
  final Color incomingColor;
  final Color incomingBorderColor;
  final Color outgoingTextColor;
  final Color incomingTextColor;
  final Color translationDividerColorOnIncoming;

  const BubbleTheme({
    this.outgoingGradient,
    required this.outgoingColor,
    required this.incomingColor,
    required this.incomingBorderColor,
    required this.outgoingTextColor,
    required this.incomingTextColor,
    required this.translationDividerColorOnIncoming,
  });
}

class ChatThemeController extends GetxController {
  static const _prefsKey = 'chatBubbleTheme';

  final Rx<ChatThemeType> _current = ChatThemeType.defaultTheme.obs;

  ChatThemeType get currentType => _current.value;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        _current.value = _fromString(saved);
      }
    } catch (_) {}
  }

  Future<void> setTheme(ChatThemeType type) async {
    if (_current.value == type) return;
    _current.value = type;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _toString(type));
    } catch (_) {}
  }

  BubbleTheme themeFor({required bool isDark}) {
    return themeOf(_current.value, isDark: isDark);
  }

  BubbleTheme themeOf(ChatThemeType type, {required bool isDark}) {
    switch (type) {
      case ChatThemeType.defaultTheme:
        return BubbleTheme(
          outgoingGradient: null,
          outgoingColor: isDark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
          incomingColor: isDark ? AppTheme.darkCardColor : AppTheme.cardColor,
          incomingBorderColor: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor,
          outgoingTextColor: Colors.white,
          incomingTextColor: isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor,
          translationDividerColorOnIncoming: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor,
        );
      case ChatThemeType.ocean:
        return BubbleTheme(
          outgoingGradient: LinearGradient(colors: [
            const Color(0xFF00B4DB),
            const Color(0xFF0083B0),
          ]),
          outgoingColor: const Color(0xFF0083B0),
          incomingColor: isDark ? const Color(0xFF0F2A3A) : const Color(0xFFE6F7FF),
          incomingBorderColor: isDark ? const Color(0xFF18465E) : const Color(0xFFB3E5FC),
          outgoingTextColor: Colors.white,
          incomingTextColor: isDark ? Colors.white : const Color(0xFF0E2A3B),
          translationDividerColorOnIncoming: isDark ? const Color(0xFF18465E) : const Color(0xFFB3E5FC),
        );
      case ChatThemeType.forest:
        return BubbleTheme(
          outgoingGradient: LinearGradient(colors: [
            const Color(0xFF11998E),
            const Color(0xFF38EF7D),
          ]),
          outgoingColor: const Color(0xFF11998E),
          incomingColor: isDark ? const Color(0xFF0F2B20) : const Color(0xFFEFF9F1),
          incomingBorderColor: isDark ? const Color(0xFF1C5D46) : const Color(0xFFB6EBC2),
          outgoingTextColor: Colors.white,
          incomingTextColor: isDark ? Colors.white : const Color(0xFF0D2A20),
          translationDividerColorOnIncoming: isDark ? const Color(0xFF1C5D46) : const Color(0xFFB6EBC2),
        );
      case ChatThemeType.sunset:
        return BubbleTheme(
          outgoingGradient: LinearGradient(colors: [
            const Color(0xFFFF7E5F),
            const Color(0xFFFD3A84),
          ]),
          outgoingColor: const Color(0xFFFF7E5F),
          incomingColor: isDark ? const Color(0xFF331F1F) : const Color(0xFFFFF1EC),
          incomingBorderColor: isDark ? const Color(0xFF6B3A3A) : const Color(0xFFFFD0C2),
          outgoingTextColor: Colors.white,
          incomingTextColor: isDark ? Colors.white : const Color(0xFF3A1F1F),
          translationDividerColorOnIncoming: isDark ? const Color(0xFF6B3A3A) : const Color(0xFFFFD0C2),
        );
      case ChatThemeType.midnight:
        return BubbleTheme(
          outgoingGradient: LinearGradient(colors: [
            const Color(0xFF0F2027),
            const Color(0xFF203A43),
          ]),
          outgoingColor: const Color(0xFF203A43),
          incomingColor: isDark ? const Color(0xFF141924) : const Color(0xFFEFF3FF),
          incomingBorderColor: isDark ? const Color(0xFF232B3E) : const Color(0xFFCBD5FF),
          outgoingTextColor: Colors.white,
          incomingTextColor: isDark ? Colors.white : const Color(0xFF0B1323),
          translationDividerColorOnIncoming: isDark ? const Color(0xFF232B3E) : const Color(0xFFCBD5FF),
        );
    }
  }

  String labelOf(ChatThemeType t) {
    switch (t) {
      case ChatThemeType.defaultTheme:
        return 'Default';
      case ChatThemeType.ocean:
        return 'Ocean';
      case ChatThemeType.forest:
        return 'Forest';
      case ChatThemeType.sunset:
        return 'Sunset';
      case ChatThemeType.midnight:
        return 'Midnight';
    }
  }

  static String _toString(ChatThemeType t) => t.name;
  static ChatThemeType _fromString(String s) {
    return ChatThemeType.values.firstWhere(
      (e) => e.name == s || (s == 'default' && e == ChatThemeType.defaultTheme),
      orElse: () => ChatThemeType.defaultTheme,
    );
  }

  ChatPageBackground pageBackgroundFor({required bool isDark}) {
    switch (_current.value) {
      case ChatThemeType.defaultTheme:
        return ChatPageBackground(
          gradient: null,
          color: isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor,
        );
      case ChatThemeType.ocean:
        return ChatPageBackground(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0B2A3B), Color(0xFF0E3C52)]
                : const [Color(0xFFE6F7FF), Color(0xFFCCF0FF)],
          ),
          color: isDark ? const Color(0xFF0B2A3B) : const Color(0xFFE6F7FF),
        );
      case ChatThemeType.forest:
        return ChatPageBackground(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0E2A21), Color(0xFF114235)]
                : const [Color(0xFFEFF9F1), Color(0xFFDFF3E4)],
          ),
          color: isDark ? const Color(0xFF0E2A21) : const Color(0xFFEFF9F1),
        );
      case ChatThemeType.sunset:
        return ChatPageBackground(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF2B1A1E), Color(0xFF3A1F2E)]
                : const [Color(0xFFFFF1EC), Color(0xFFFFE2DA)],
          ),
          color: isDark ? const Color(0xFF2B1A1E) : const Color(0xFFFFF1EC),
        );
      case ChatThemeType.midnight:
        return ChatPageBackground(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0E1220), Color(0xFF15243A)]
                : const [Color(0xFFEFF3FF), Color(0xFFDEE7FF)],
          ),
          color: isDark ? const Color(0xFF0E1220) : const Color(0xFFEFF3FF),
        );
    }
  }

  Color accentColorFor({required bool isDark}) {
    final t = themeFor(isDark: isDark);
    final grad = t.outgoingGradient;
    if (grad != null) {
      final colors = (grad as LinearGradient).colors;
      return colors.isNotEmpty ? colors.last : t.outgoingColor;
    }
    return t.outgoingColor;
  }

  ChatAppBarBackground appBarBackgroundFor({required bool isDark}) {
    switch (_current.value) {
      case ChatThemeType.defaultTheme:
        return ChatAppBarBackground(
          gradient: null,
          color: isDark ? AppTheme.darkCardColor : AppTheme.cardColor,
          bottomBorderColor: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor,
        );
      case ChatThemeType.ocean:
        return ChatAppBarBackground(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0B2A3B), Color(0xFF0E3C52)]
                : const [Color(0xFFF1FAFF), Color(0xFFE6F7FF)],
          ),
          color: isDark ? const Color(0xFF0B2A3B) : const Color(0xFFF1FAFF),
          bottomBorderColor: isDark ? const Color(0xFF18465E) : const Color(0xFFB3E5FC),
        );
      case ChatThemeType.forest:
        return ChatAppBarBackground(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0E2A21), Color(0xFF114235)]
                : const [Color(0xFFF5FBF7), Color(0xFFEFF9F1)],
          ),
          color: isDark ? const Color(0xFF0E2A21) : const Color(0xFFF5FBF7),
          bottomBorderColor: isDark ? const Color(0xFF1C5D46) : const Color(0xFFB6EBC2),
        );
      case ChatThemeType.sunset:
        return ChatAppBarBackground(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF2B1A1E), Color(0xFF3A1F2E)]
                : const [Color(0xFFFFF5F2), Color(0xFFFFE9E2)],
          ),
          color: isDark ? const Color(0xFF2B1A1E) : const Color(0xFFFFF5F2),
          bottomBorderColor: isDark ? const Color(0xFF6B3A3A) : const Color(0xFFFFD0C2),
        );
      case ChatThemeType.midnight:
        return ChatAppBarBackground(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0E1220), Color(0xFF15243A)]
                : const [Color(0xFFF4F6FF), Color(0xFFEFF3FF)],
          ),
          color: isDark ? const Color(0xFF0E1220) : const Color(0xFFF4F6FF),
          bottomBorderColor: isDark ? const Color(0xFF232B3E) : const Color(0xFFCBD5FF),
        );
    }
  }
}
