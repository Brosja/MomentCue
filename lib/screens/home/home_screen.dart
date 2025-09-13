import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/check.dart';
import '../../models/schedule.dart';
import '../../services/storage_service.dart';
import '../../services/schedule_service.dart';
import '../../services/time_service.dart';
import '../../utils/app_theme.dart';
import '../check/add_check_screen.dart';
import '../check/check_detail_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/check_card.dart';
import '../../widgets/daily_progress_card.dart';
import '../../widgets/upcoming_reminders_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  List<Check> _checks = [];
  List<ScheduleOccurrence> _todayOccurrences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final scheduleService = Provider.of<ScheduleService>(context, listen: false);
      final timeService = Provider.of<TimeService>(context, listen: false);

      final allChecks = storageService.getActiveChecks();
      final today = timeService.startOfDay(timeService.now());
      final tomorrow = today.add(const Duration(days: 1));

      final todayOccurrences = <ScheduleOccurrence>[];
      
      for (final check in allChecks) {
        final occurrences = scheduleService.generateOccurrences(
          check: check,
          count: 10,
          startFrom: today,
        );
        
        todayOccurrences.addAll(
          occurrences.where((occ) => 
            occ.scheduledTime.isAfter(today) && 
            occ.scheduledTime.isBefore(tomorrow)
          ),
        );
      }

      // Sort by scheduled time
      todayOccurrences.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      setState(() {
        _checks = allChecks;
        _todayOccurrences = todayOccurrences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildChecksTab(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Checks',
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
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => _navigateToAddCheck(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: AppTheme.primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _getGreeting(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColorDark,
                  ],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DailyProgressCard(
                        occurrences: _todayOccurrences,
                        onTap: () => _navigateToAnalytics(),
                      ),
                      const SizedBox(height: 16),
                      UpcomingRemindersCard(
                        occurrences: _todayOccurrences.take(5).toList(),
                        onOccurrenceTap: _handleOccurrenceTap,
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChecksTab() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Your Checks'),
          floating: true,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        SliverToBoxAdapter(
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _checks.isEmpty
                  ? _buildEmptyState()
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: AppTheme.primaryColor,
                            tabs: const [
                              Tab(text: 'Active'),
                              Tab(text: 'Categories'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildActiveChecks(),
                                _buildCategorizedChecks(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildActiveChecks() {
    return ListView.builder(
      itemCount: _checks.length,
      itemBuilder: (context, index) {
        final check = _checks[index];
        return CheckCard(
          check: check,
          onTap: () => _navigateToCheckDetail(check),
          onToggle: (enabled) => _toggleCheck(check, enabled),
        );
      },
    );
  }

  Widget _buildCategorizedChecks() {
    final categorizedChecks = <CheckCategory, List<Check>>{};
    
    for (final check in _checks) {
      categorizedChecks.putIfAbsent(check.category, () => []).add(check);
    }

    return ListView.builder(
      itemCount: categorizedChecks.length,
      itemBuilder: (context, index) {
        final category = categorizedChecks.keys.elementAt(index);
        final checksInCategory = categorizedChecks[category]!;
        
        return ExpansionTile(
          title: Text(_getCategoryDisplayName(category)),
          leading: Icon(_getCategoryIcon(category)),
          children: checksInCategory.map((check) => CheckCard(
            check: check,
            onTap: () => _navigateToCheckDetail(check),
            onToggle: (enabled) => _toggleCheck(check, enabled),
          )).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No health checks yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first reminder to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToAddCheck,
              icon: const Icon(Icons.add),
              label: const Text('Create Check'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: Icons.add,
                  label: 'Add Check',
                  onTap: _navigateToAddCheck,
                ),
                _buildQuickActionButton(
                  icon: Icons.analytics,
                  label: 'Analytics',
                  onTap: _navigateToAnalytics,
                ),
                _buildQuickActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: _navigateToSettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getCategoryDisplayName(CheckCategory category) {
    switch (category) {
      case CheckCategory.hydration:
        return 'Hydration';
      case CheckCategory.posture:
        return 'Posture';
      case CheckCategory.medication:
        return 'Medication';
      case CheckCategory.screenBreak:
        return 'Screen Breaks';
      case CheckCategory.breathing:
        return 'Breathing';
      case CheckCategory.exercise:
        return 'Exercise';
      case CheckCategory.custom:
        return 'Custom';
    }
  }

  IconData _getCategoryIcon(CheckCategory category) {
    switch (category) {
      case CheckCategory.hydration:
        return Icons.water_drop;
      case CheckCategory.posture:
        return Icons.accessibility_new;
      case CheckCategory.medication:
        return Icons.medication;
      case CheckCategory.screenBreak:
        return Icons.remove_red_eye;
      case CheckCategory.breathing:
        return Icons.air;
      case CheckCategory.exercise:
        return Icons.fitness_center;
      case CheckCategory.custom:
        return Icons.star;
    }
  }

  void _handleOccurrenceTap(ScheduleOccurrence occurrence) {
    final check = _checks.firstWhere(
      (c) => c.id == occurrence.checkId,
      orElse: () => _checks.first,
    );
    _navigateToCheckDetail(check);
  }

  Future<void> _toggleCheck(Check check, bool enabled) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      check.enabled = enabled;
      await storageService.saveCheck(check);
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Check enabled' : 'Check disabled'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating check: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _navigateToAddCheck() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddCheckScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _navigateToCheckDetail(Check check) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCheckScreen(checkToEdit: check),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _navigateToAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AnalyticsScreen(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}
