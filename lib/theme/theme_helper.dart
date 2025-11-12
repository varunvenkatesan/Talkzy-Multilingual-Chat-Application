import 'package:flutter/material.dart';
import 'package:talkzy_beta1/theme/app_theme.dart';

/// Helper class to get theme-aware colors based on current brightness
class ThemeHelper {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color backgroundColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
  }

  static Color cardColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkCardColor : AppTheme.cardColor;
  }

  static Color textPrimaryColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
  }

  static Color textSecondaryColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkTextSecondaryColor : AppTheme.textSecoundaryColor;
  }

  static Color primaryColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
  }

  static Color secondaryColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkSecondaryColor : AppTheme.secondaryColor;
  }

  static Color borderColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkBorderColor : AppTheme.borderColor;
  }

  static Color errorColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkErrorColor : AppTheme.errorColor;
  }

  static Color successColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkSuccessColor : AppTheme.successColor;
  }

  static Color warningColor(BuildContext context) {
    return isDark(context) ? AppTheme.darkWarningColor : AppTheme.warningColor;
  }

  /// Get a BoxDecoration with theme-aware colors
  static BoxDecoration cardDecoration(BuildContext context, {double radius = 16}) {
    return BoxDecoration(
      color: cardColor(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor(context).withOpacity(0.5),
        width: 1,
      ),
    );
  }

  /// Get TextStyle with theme-aware color
  static TextStyle headlineStyle(BuildContext context, {double fontSize = 24, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: textPrimaryColor(context),
    );
  }

  static TextStyle bodyStyle(BuildContext context, {double fontSize = 14, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: textSecondaryColor(context),
    );
  }

  static TextStyle titleStyle(BuildContext context, {double fontSize = 16, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: textPrimaryColor(context),
    );
  }
}
