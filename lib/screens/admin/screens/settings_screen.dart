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
            Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSection('General Settings', [
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
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Backup & Sync', [
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
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Account', [
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
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Privacy Policy'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text('Effective Date: 20-June-2025\n'),
                                        Text(
                                          'We value your privacy. This Privacy Policy explains how we collect, use, and protect your data.\n',
                                        ),
                                        Text(
                                          '1. Data We Collect\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'We collect the following types of information:\n',
                                        ),
                                        Text(
                                          '• Tuition admin details (name, phone, email)\n',
                                        ),
                                        Text(
                                          '• Student information (name, batch, attendance, fees, numbers, emails)\n',
                                        ),
                                        Text(
                                          '• App usage data (logins, actions, etc.)\n\n',
                                        ),
                                        Text(
                                          '2. How We Use Your Data\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text('We use the data to:\n'),
                                        Text(
                                          '• Display and manage student records\n',
                                        ),
                                        Text(
                                          '• Generate reports for attendance and fees\n',
                                        ),
                                        Text(
                                          '• Help tuition admins run their classes efficiently\n\n',
                                        ),
                                        Text(
                                          '3. Data Sharing\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'We do not sell or share your data with any third party.\nData is only used internally to improve platform performance and stability.\n\n',
                                        ),
                                        Text(
                                          '4. Data Security\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'All data is stored securely using encrypted databases (e.g., Firebase).\nAccess is protected by authentication. Please don\'t share your login.\n\n',
                                        ),
                                        Text(
                                          '5. Your Control Over Data\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'You can request us to delete your account and all related data at any time by contacting support.\n\n',
                                        ),
                                        Text(
                                          '6. Children\'s Data\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'The App may store student data, including minors, only as entered by tuition admins.\nWe do not collect data directly from children.\n\n',
                                        ),
                                        Text(
                                          '7. Changes to Privacy Policy\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'We may revise this policy as the app grows. Updated policies will be posted here.\n\n',
                                        ),
                                        Text(
                                          '📬 Contact Us\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'For questions or support, contact:\nEmail: writetokaranpednekar@gmail.com\nPhone: +91 9766153262',
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                      _buildButtonTile(
                        'Terms of Service',
                        'View our terms of service',
                        Icons.description,
                        () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Terms of Service'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text('Effective Date: 19-june-2025\n'),
                                        Text(
                                          'Welcome to Sankalp Academy ("the App"). By using the App, you agree to the following terms and conditions. Please read them carefully.\n',
                                        ),
                                        Text(
                                          '1. Use of the App\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'This App is provided to tuition class owners ("Admins") to manage their students, attendance, batches, fees, and other academic data.\nYou are responsible for all content and data you upload.\nYou agree to use the App only for lawful, educational, and administrative purposes.\n\n',
                                        ),
                                        Text(
                                          '2. Account and Access\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Admin accounts are created by or for tuition institutions only.\nYou are responsible for maintaining the confidentiality of your account credentials.\n\n',
                                        ),
                                        Text(
                                          '3. Data Accuracy\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'You must ensure that the data entered (students, fees, attendance) is accurate and updated regularly.\n\n',
                                        ),
                                        Text(
                                          '4. Limitations of Liability\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'The App is provided "as is." While we work to ensure data accuracy and uptime, we are not liable for data loss, misuse, or downtime.\nIt is your responsibility to keep manual backups until the App is fully stable.\n\n',
                                        ),
                                        Text(
                                          '5. Suspension or Termination\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'We reserve the right to suspend access to any account that violates these terms, uses the system for harmful purposes, or abuses the platform.\n\n',
                                        ),
                                        Text(
                                          '6. Changes to Terms\n',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'We may update these terms occasionally. Continued use after such changes means you agree to the new terms.',
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
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
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Danger Zone', [
                      _buildButtonTile(
                        'Delete Account',
                        'Permanently delete your account and all data',
                        Icons.delete_forever,
                        () {
                          // TODO: Implement account deletion
                        },
                        isDestructive: true,
                      ),
                    ]),
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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
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
        items:
            items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
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
        style: TextStyle(color: isDestructive ? AppTheme.errorColor : null),
      ),
      subtitle: Text(subtitle),
      leading: Icon(icon, color: isDestructive ? AppTheme.errorColor : null),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
