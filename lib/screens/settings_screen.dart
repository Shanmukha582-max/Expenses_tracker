import 'package:flutter/material.dart';

import '../data/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currency = 'INR (₹)';
  bool _notificationsEnabled = true;

  void _showUnavailable(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is not configured yet.')));
  }

  Future<void> _editProfile() async {
    final profile = await DatabaseHelper.instance.getProfile();
    if (!mounted) return;
    final nameController = TextEditingController(text: profile['name']);
    final emailController = TextEditingController(text: profile['email']);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await DatabaseHelper.instance.saveProfile(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    emailController.dispose();
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _backup() async {
    try {
      final file = await DatabaseHelper.instance.exportBackup();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup saved to ${file.path}')));
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Backup failed: $error')));
      }
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'This replaces current expenses with the saved backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DatabaseHelper.instance.restoreBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored. Refresh expenses to see changes.'),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Restore failed: $error')));
      }
    }
  }

  Future<void> _backupAndRestore() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Back up now'),
              onTap: () => Navigator.pop(context, 'backup'),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Restore backup'),
              onTap: () => Navigator.pop(context, 'restore'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'backup') {
      await _backup();
    } else if (action == 'restore') {
      await _restore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('View and manage user information'),
            onTap: _editProfile,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Currency Settings'),
            subtitle: Text(_currency),
            onTap: () async {
              final selected = await showModalBottomSheet<String>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['INR (₹)', 'USD (\$)', 'EUR (€)']
                        .map(
                          (currency) => ListTile(
                            title: Text(currency),
                            trailing: currency == _currency
                                ? const Icon(Icons.check)
                                : null,
                            onTap: () => Navigator.pop(context, currency),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
              if (selected != null && mounted) {
                setState(() => _currency = selected);
              }
            },
          ),
        ),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme Settings'),
            subtitle: Text(widget.isDarkMode ? 'Dark mode' : 'Light mode'),
            value: widget.isDarkMode,
            onChanged: (_) => widget.onToggleTheme(),
          ),
        ),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Protect your expense data'),
            onTap: _backupAndRestore,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            subtitle: const Text('Expense Tracker • Version 1.0.0'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Expense Tracker',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.account_balance_wallet),
              children: const [
                Text('Track expenses and monitor your budget in one place.'),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            subtitle: const Text('Authentication is not configured'),
            onTap: () => _showUnavailable('Logout'),
          ),
        ),
      ],
    );
  }
}
