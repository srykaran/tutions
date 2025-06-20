import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/theme.dart';
import '../../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'INR';
  bool _autoBackupEnabled = true;
  String _backupFrequency = 'Daily';

  final List<String> _languages = ['English', 'Hindi', 'Gujarati'];
  final List<String> _currencies = ['INR', 'USD', 'EUR'];
  final List<String> _backupFrequencies = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSection(
                      'General Settings',
                      [
                        _buildSwitchTile(
                          'Enable Notifications',
                          'Receive notifications for important updates',
                          _notificationsEnabled,
                          (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),
                        _buildSwitchTile(
                          'Dark Mode',
                          'Enable dark theme for the app',
                          _darkModeEnabled,
                          (value) {
                            setState(() {
                              _darkModeEnabled = value;
                            });
                          },
                        ),
                        _buildDropdownTile(
                          'Language',
                          'Select your preferred language',
                          _selectedLanguage,
                          _languages,
                          (value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                          },
                        ),
                        _buildDropdownTile(
                          'Currency',
                          'Select your preferred currency',
                          _selectedCurrency,
                          _currencies,
                          (value) {
                            setState(() {
                              _selectedCurrency = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Backup & Sync',
                      [
                        _buildSwitchTile(
                          'Auto Backup',
                          'Automatically backup your data',
                          _autoBackupEnabled,
                          (value) {
                            setState(() {
                              _autoBackupEnabled = value;
                            });
                          },
                        ),
                        _buildDropdownTile(
                          'Backup Frequency',
                          'Select how often to backup your data',
                          _backupFrequency,
                          _backupFrequencies,
                          (value) {
                            setState(() {
                              _backupFrequency = value!;
                            });
                          },
                        ),
                        _buildButtonTile(
                          'Backup Now',
                          'Create a manual backup of your data',
                          Icons.backup,
                          () {
                            // TODO: Implement backup functionality
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Account',
                      [
                        _buildButtonTile(
                          'Change Password',
                          'Update your account password',
                          Icons.lock,
                          () {
                            // TODO: Implement password change
                          },
                        ),
                        _buildButtonTile(
                          'Privacy Policy',
                          'View our privacy policy',
                          Icons.privacy_tip,
                          () {
                            // TODO: Show privacy policy
                          },
                        ),
                        _buildButtonTile(
                          'Terms of Service',
                          'View our terms of service',
                          Icons.description,
                          () {
                            // TODO: Show terms of service
                          },
                        ),
                        _buildButtonTile(
                          'Logout',
                          'Sign out of your account',
                          Icons.logout,
                          () async {
                            try {
                              await ref.read(authProvider.notifier).logout();
                              if (mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          isDestructive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Danger Zone',
                      [
                        _buildButtonTile(
                          'Delete Account',
                          'Permanently delete your account and all data',
                          Icons.delete_forever,
                          () {
                            // TODO: Implement account deletion
                          },
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildButtonTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.errorColor : null,
        ),
      ),
      subtitle: Text(subtitle),
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorColor : null,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 