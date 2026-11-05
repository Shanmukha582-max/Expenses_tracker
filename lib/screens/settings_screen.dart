import 'package:flutter/material.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is not configured yet.')),
    );
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
            onTap: () => _showUnavailable('Profile management'),
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
              if (selected != null) setState(() => _currency = selected);
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
            subtitle: Text(
              _notificationsEnabled ? 'Enabled' : 'Disabled',
            ),
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
            onTap: () => _showUnavailable('Backup and restore'),
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
