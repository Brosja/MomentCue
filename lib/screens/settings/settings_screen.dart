import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/simple_storage_service.dart';
import '../../services/backup_service.dart';
import '../../services/onboarding_service.dart';
import '../../providers/theme_provider.dart';
import '../../models/notification_sound.dart';
import '../../models/simple_check.dart';
import '../../models/notification_schedule.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'English';
  int _snoozeDuration = 15; // minutes
  bool _showOnLockScreen = true;
  NotificationSound _selectedNotificationSound = NotificationSound.getDefault();
  bool _allowSnooze = true;
  int _maxSnoozes = 3;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from storage
    // For now, we'll use default values
    _selectedNotificationSound = NotificationService().getSelectedSound();
    setState(() {});
  }

  Future<void> _saveSettings() async {
    // Save settings to storage
    // Implementation would go here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotificationsSection(),
          const SizedBox(height: 24),
          _buildAppearanceSection(),
          const SizedBox(height: 24),
          _buildBehaviorSection(),
          const SizedBox(height: 24),
          _buildDataSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Allow MomentCue to send notifications'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                if (value) {
                  await NotificationService().initialize();
                }
                await _saveSettings();
              },
              activeColor: AppTheme.primaryColor,
            ),
            if (_notificationsEnabled) ...[
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play sound for notifications'),
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                  _saveSettings();
                },
                activeColor: AppTheme.primaryColor,
              ),
              if (_soundEnabled) ...[
                ListTile(
                  title: const Text('Notification Sound'),
                  subtitle: Text(_selectedNotificationSound.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showSoundSelectionDialog(),
                ),
              ],
              SwitchListTile(
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate for notifications'),
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                  _saveSettings();
                },
                activeColor: AppTheme.primaryColor,
              ),
              SwitchListTile(
                title: const Text('Show on Lock Screen'),
                subtitle: const Text('Display notifications on lock screen'),
                value: _showOnLockScreen,
                onChanged: (value) {
                  setState(() {
                    _showOnLockScreen = value;
                  });
                  _saveSettings();
                },
                activeColor: AppTheme.primaryColor,
              ),
              const Divider(),
              ListTile(
                title: const Text('Test Notification (5s)'),
                subtitle: const Text('Send a test notification in 5 seconds'),
                trailing: const Icon(Icons.notifications_active),
                onTap: () async {
                  await NotificationService().scheduleTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification scheduled!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Test Notification (Now)'),
                subtitle: const Text('Send an immediate test notification'),
                trailing: const Icon(Icons.notifications),
                onTap: () async {
                  await NotificationService().showImmediateNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Immediate notification sent!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Debug 1-Min Notification'),
                subtitle: const Text('Test check notification in 1 minute'),
                trailing: const Icon(Icons.science),
                onTap: () async {
                  await NotificationService().scheduleDebugCheckNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debug notification scheduled for 1 minute!'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('List Pending Notifications'),
                subtitle: const Text('Show all scheduled notifications'),
                trailing: const Icon(Icons.list),
                onTap: () async {
                  await NotificationService().listPendingNotifications();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Check console for pending notifications list'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Check Exact Alarm Permission'),
                subtitle: const Text('Check if Android allows exact alarms'),
                trailing: const Icon(Icons.security),
                onTap: () async {
                  await NotificationService().checkExactAlarmPermission();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Check console for permission status'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Test Reliable Notification'),
                subtitle: const Text('Test reliable scheduling (like working test)'),
                trailing: const Icon(Icons.verified),
                onTap: () async {
                  // Create a dummy check and schedule for testing reliable notifications
                  final dummyCheck = SimpleCheck(
                    id: 'test-reliable',
                    title: 'Reliable Test',
                    description: 'Testing reliable notification',
                    category: 'Test',
                    scheduleType: 'daily',
                    enabled: true,
                    createdAt: DateTime.now(),
                    notificationsEnabled: true,
                    notificationSchedules: [],
                    allowSnooze: false,
                    maxSnoozes: 0,
                  );
                  
                  final now = DateTime.now();
                  final testTime = now.add(const Duration(minutes: 1));
                  
                  final dummySchedule = NotificationSchedule(
                    id: 'test-schedule-reliable',
                    checkId: 'test-reliable',
                    title: 'Reliable Test Schedule',
                    scheduleType: ScheduleType.daily,
                    scheduleData: {
                      'times': [{'hour': testTime.hour, 'minute': testTime.minute}]
                    },
                    createdAt: DateTime.now(),
                    isEnabled: true,
                  );
                  
                  await NotificationService().scheduleReliableNotification(dummyCheck, dummySchedule);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reliable notification scheduled for 1 minute!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Test Inexact Notification'),
                subtitle: const Text('Test inexact scheduling (fallback method)'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  // Create a dummy check and schedule for testing inexact notifications
                  final dummyCheck = SimpleCheck(
                    id: 'test-inexact',
                    title: 'Inexact Test',
                    description: 'Testing inexact notification',
                    category: 'Test',
                    scheduleType: 'daily',
                    enabled: true,
                    createdAt: DateTime.now(),
                    notificationsEnabled: true,
                    notificationSchedules: [],
                    allowSnooze: false,
                    maxSnoozes: 0,
                  );
                  
                  final now = DateTime.now();
                  final testTime = now.add(const Duration(minutes: 1));
                  
                  final dummySchedule = NotificationSchedule(
                    id: 'test-schedule',
                    checkId: 'test-inexact',
                    title: 'Inexact Test Schedule',
                    scheduleType: ScheduleType.daily,
                    scheduleData: {
                      'times': [{'hour': testTime.hour, 'minute': testTime.minute}]
                    },
                    createdAt: DateTime.now(),
                    isEnabled: true,
                  );
                  
                  await NotificationService().scheduleInexactNotification(dummyCheck, dummySchedule);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inexact notification scheduled for 1 minute!'),
                        backgroundColor: AppTheme.warningColor,
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                    _saveSettings();
                  },
                  activeColor: AppTheme.primaryColor,
                );
              },
            ),
            ListTile(
              title: const Text('Language'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showLanguageDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Behavior',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Allow Snooze'),
              subtitle: const Text('Enable snooze functionality'),
              value: _allowSnooze,
              onChanged: (value) {
                setState(() {
                  _allowSnooze = value;
                });
                _saveSettings();
              },
              activeColor: AppTheme.primaryColor,
            ),
            if (_allowSnooze) ...[
              ListTile(
                title: const Text('Snooze Duration'),
                subtitle: Text('$_snoozeDuration minutes'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showSnoozeDurationDialog();
                },
              ),
              ListTile(
                title: const Text('Max Snoozes'),
                subtitle: Text('$_maxSnoozes per check'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showMaxSnoozesDialog();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data & Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Export your checks and settings'),
              trailing: const Icon(Icons.download),
              onTap: () {
                _exportData();
              },
            ),
            ListTile(
              title: const Text('Import Data'),
              subtitle: const Text('Import checks and settings'),
              trailing: const Icon(Icons.upload),
              onTap: () {
                _importData();
              },
            ),
            ListTile(
              title: const Text('Reset Onboarding'),
              subtitle: const Text('Show onboarding screen again'),
              trailing: const Icon(Icons.refresh, color: AppTheme.infoColor),
              onTap: () {
                _showResetOnboardingDialog();
              },
            ),
            ListTile(
              title: const Text('Clear All Data'),
              subtitle: const Text('Delete all checks and settings'),
              trailing: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
              onTap: () {
                _showClearDataDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
              trailing: const Icon(Icons.info),
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              subtitle: const Text('View our privacy policy'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showPrivacyPolicy();
              },
            ),
            ListTile(
              title: const Text('Terms of Service'),
              subtitle: const Text('View terms of service'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showTermsOfService();
              },
            ),
            ListTile(
              title: const Text('Support'),
              subtitle: const Text('Get help and support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showSupport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: _selectedLanguage == 'English' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'English';
                });
                Navigator.pop(context);
                _saveSettings();
              },
            ),
            ListTile(
              title: const Text('Español'),
              trailing: _selectedLanguage == 'Español' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'Español';
                });
                Navigator.pop(context);
                _saveSettings();
              },
            ),
            ListTile(
              title: const Text('Deutsch'),
              trailing: _selectedLanguage == 'Deutsch' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'Deutsch';
                });
                Navigator.pop(context);
                _saveSettings();
              },
            ),
            ListTile(
              title: const Text('Français'),
              trailing: _selectedLanguage == 'Français' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _selectedLanguage = 'Français';
                });
                Navigator.pop(context);
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSoundSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Notification Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NotificationSound.availableSounds.map((sound) {
            return RadioListTile<NotificationSound>(
              title: Text(sound.name),
              subtitle: sound.isDefault ? const Text('Default system sound') : null,
              value: sound,
              groupValue: _selectedNotificationSound,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedNotificationSound = value;
                  });
                  NotificationService().setSelectedSound(value);
                  _saveSettings();
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSnoozeDurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: $_snoozeDuration minutes'),
            Slider(
              value: _snoozeDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '$_snoozeDuration minutes',
              onChanged: (value) {
                setState(() {
                  _snoozeDuration = value.round();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSettings();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMaxSnoozesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Snoozes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: $_maxSnoozes per check'),
            Slider(
              value: _maxSnoozes.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_maxSnoozes',
              onChanged: (value) {
                setState(() {
                  _maxSnoozes = value.round();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSettings();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your checks and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      await SimpleStorageService.instance.clearAllChecks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    // TODO: Show privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy policy coming soon!'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _showTermsOfService() {
    // TODO: Show terms of service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms of service coming soon!'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _showSupport() {
    // TODO: Show support information
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support information coming soon!'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final filePath = await BackupService.exportChecks();
      await Share.shareXFiles([XFile(filePath)], text: 'MomentCue Backup');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data exported successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export data: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        await BackupService.importChecks(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data imported successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import data: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _manageBackups() async {
    final backups = await BackupService.getBackupFiles();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Backups'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (context, index) {
              final file = backups[index];
              final fileName = file.path.split('/').last;
              final modified = file.statSync().modified;
              
              return ListTile(
                title: Text(fileName),
                subtitle: Text('Modified: ${modified.toString().split('.')[0]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                  onPressed: () async {
                    try {
                      await BackupService.deleteBackupFile(file.path);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup deleted successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete backup: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetOnboardingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding'),
        content: const Text(
          'This will reset the onboarding flow and show it again when you restart the app. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await OnboardingService.resetOnboarding();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Onboarding reset successfully! Restart the app to see the onboarding screen.'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}