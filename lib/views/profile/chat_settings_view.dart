import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talkzy_beta1/controllers/theme_controller.dart';
import 'package:talkzy_beta1/controllers/chat_theme_controller.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';

class ChatSettingsView extends StatefulWidget {
  const ChatSettingsView({super.key});

  @override
  State<ChatSettingsView> createState() => _ChatSettingsViewState();
}

class _ChatSettingsViewState extends State<ChatSettingsView> {
  final ThemeController _themeController = Get.find<ThemeController>();
  final ChatThemeController _chatThemeController = Get.find<ChatThemeController>();
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final textColor = isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Chat Settings',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 16),
            
            Obx(() => _buildSwitchTile(
              context: context,
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              value: _themeController.isDarkMode,
              onChanged: (value) async {
                await _themeController.toggleTheme();
                Get.snackbar(
                  'Theme Changed',
                  value ? 'Dark mode enabled' : 'Light mode enabled',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: (value ? AppTheme.darkSuccessColor : AppTheme.successColor).withOpacity(0.1),
                  colorText: value ? AppTheme.darkSuccessColor : AppTheme.successColor,
                  duration: Duration(seconds: 2),
                );
              },
            )),
            
            SizedBox(height: 12),
            
            _buildThemeSelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardColor : AppTheme.cardColor;
    final borderColor = isDark ? AppTheme.darkBorderColor : AppTheme.borderColor;
    final textColor = isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textSecoundaryColor;
    final primaryColor = isDark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 22,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themes = [
      ChatThemeType.defaultTheme,
      ChatThemeType.ocean,
      ChatThemeType.forest,
      ChatThemeType.sunset,
      ChatThemeType.midnight,
    ];
    final isDark =  Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardColor : AppTheme.cardColor;
    final borderColor = isDark ? AppTheme.darkBorderColor : AppTheme.borderColor;
    final textColor = isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textSecoundaryColor;
    final primaryColor = isDark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final bgColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat Theme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose your chat bubble theme',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Obx(() {
            final current = _chatThemeController.currentType;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: themes.map((type) {
                final label = _chatThemeController.labelOf(type);
                final isSelected = current == type;
                final preview = _chatThemeController.themeOf(type, isDark: isDark);
                final chipBg = isSelected ? null : bgColor;
                return GestureDetector(
                  onTap: () async {
                    await _chatThemeController.setTheme(type);
                    Get.snackbar(
                      'Theme Selected',
                      '$label theme applied',
                      snackPosition: SnackPosition.TOP,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: chipBg,
                      gradient: isSelected ? preview.outgoingGradient : null,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // swatch
                        Container(
                          width: 28,
                          height: 28,
                          margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: preview.outgoingGradient,
                            color: preview.outgoingGradient == null ? preview.outgoingColor : null,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSelected ? Colors.white.withOpacity(0.6) : borderColor),
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? const Color.fromARGB(255, 26, 79, 255) : textColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}
