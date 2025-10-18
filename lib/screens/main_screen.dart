import 'package:flutter/material.dart';
import 'package:guardian_shield/screens/sos_screen.dart';
import 'package:guardian_shield/screens/location_tracking_screen.dart';
import 'package:guardian_shield/screens/public_incidents_screen.dart';
import 'package:guardian_shield/screens/ai_chat_screen.dart';
import 'package:guardian_shield/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = [
    const SOSScreen(),
    const LocationTrackingScreen(),
    const PublicIncidentsScreen(),
    const AIChatScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  icon: Icons.emergency,
                  label: 'SOS',
                  index: 0,
                  theme: theme,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.location_on,
                  label: 'Track',
                  index: 1,
                  theme: theme,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.public,
                  label: 'Incidents',
                  index: 2,
                  theme: theme,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.chat_bubble,
                  label: 'AI Assistant',
                  index: 3,
                  theme: theme,
                  isDark: isDark,
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  index: 4,
                  theme: theme,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
