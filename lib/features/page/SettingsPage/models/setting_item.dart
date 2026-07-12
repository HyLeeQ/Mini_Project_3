import 'package:flutter/material.dart';

class SettingItem {
  final IconData      icon;
  final Color         color;
  final String        label;
  final String?       subtitle;
  final Widget?       trailing;
  final VoidCallback? onTap;

  const SettingItem({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}