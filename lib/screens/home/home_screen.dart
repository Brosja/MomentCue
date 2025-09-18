import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/simple_check.dart';
import '../../services/simple_storage_service.dart';
import '../check/add_check_screen.dart';
import '../settings/settings_screen.dart';
import '../analytics/analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<SimpleCheck> _checks = [];
  bool _isLoading = true;
  final SimpleStorageService _storageService = SimpleStorageService.instance;

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final checks = await _storageService.getChecks();
      setState(() {
        _checks = checks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading checks: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'MomentCue',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  _DashboardTab(checks: _checks, isLoading: _isLoading, onCheckTap: _editCheck, onCheckDelete: _deleteCheck),
                  const AnalyticsScreen(),
                  const SettingsScreen(),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCheckDialog();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddCheckDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCheckScreen(),
      ),
    ).then((result) {
      if (result != null && result is SimpleCheck) {
        _addCheck(result);
      }
    });
  }

  Future<void> _addCheck(SimpleCheck check) async {
    try {
      await _storageService.addCheck(check);
      setState(() {
        _checks.add(check);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${check.title}" to your checks!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving check: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _editCheck(SimpleCheck check) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCheckScreen(editCheck: check),
      ),
    );
    
    if (result != null && result is SimpleCheck) {
      try {
        await _storageService.updateCheck(result);
        setState(() {
          final index = _checks.indexWhere((c) => c.id == result.id);
          if (index != -1) {
            _checks[index] = result;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated "${result.title}"'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating check: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCheck(SimpleCheck check) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Check'),
        content: Text('Are you sure you want to delete "${check.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storageService.deleteCheck(check.id);
        setState(() {
          _checks.removeWhere((c) => c.id == check.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${check.title}"'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting check: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}

class _DashboardTab extends StatelessWidget {
  final List<SimpleCheck> checks;
  final bool isLoading;
  final Function(SimpleCheck) onCheckTap;
  final Function(SimpleCheck) onCheckDelete;

  const _DashboardTab({
    required this.checks, 
    required this.isLoading,
    required this.onCheckTap,
    required this.onCheckDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your checks...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to MomentCue!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your personal wellness companion',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (checks.isEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Getting Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Tap the + button to add your first health check\n'
                      '2. Set up reminders for your wellness routines\n'
                      '3. Track your progress and build healthy habits',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // This will be handled by the floating action button
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Your First Check'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Health Checks (${checks.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // This will be handled by the floating action button
                  },
                  child: const Text('Add More'),
                ),
              ],
            ),
            const SizedBox(height: 12),
                    ...checks.map((check) => _buildCheckCard(context, check)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckCard(BuildContext context, SimpleCheck check) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onCheckTap(check),
        onLongPress: () => _showCheckOptions(context, check),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: check.enabled ? AppTheme.successColor : AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      check.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    check.enabled ? Icons.check_circle : Icons.pause_circle,
                    color: check.enabled ? AppTheme.successColor : AppTheme.errorColor,
                    size: 20,
                  ),
                ],
              ),
            if (check.description != null) ...[
              const SizedBox(height: 8),
              Text(
                check.description!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(check.category, Icons.category),
                const SizedBox(width: 8),
                _buildInfoChip(check.scheduleType, Icons.schedule),
                if (check.notificationsEnabled && check.notificationSchedules.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip('Notifications', Icons.notifications),
                ],
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showCheckOptions(BuildContext context, SimpleCheck check) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Check'),
              onTap: () {
                Navigator.pop(context);
                onCheckTap(check);
              },
            ),
            ListTile(
              leading: Icon(
                check.enabled ? Icons.pause : Icons.play_arrow,
                color: check.enabled ? AppTheme.warningColor : AppTheme.successColor,
              ),
              title: Text(check.enabled ? 'Disable' : 'Enable'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Toggle check enabled state
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Delete Check'),
              onTap: () {
                Navigator.pop(context);
                onCheckDelete(check);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'Analytics Coming Soon',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track your wellness journey with detailed insights',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'Settings Coming Soon',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Customize your MomentCue experience',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
