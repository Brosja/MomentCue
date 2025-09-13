import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/check.dart';
import '../../services/storage_service.dart';
import '../../services/schedule_service.dart';
import '../../services/time_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/analytics_chart.dart';
import '../../widgets/analytics_card.dart';
import '../../widgets/heatmap_calendar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Check> _checks = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final scheduleService = Provider.of<ScheduleService>(context, listen: false);
      final timeService = Provider.of<TimeService>(context, listen: false);

      final allChecks = storageService.getAllChecks();
      final now = timeService.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Calculate analytics
      final analytics = _calculateAnalytics(allChecks, now, thirtyDaysAgo);

      setState(() {
        _checks = allChecks;
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _calculateAnalytics(List<Check> checks, DateTime now, DateTime thirtyDaysAgo) {
    int totalScheduled = 0;
    int totalCompleted = 0;
    int totalMissed = 0;
    double averageCompletionRate = 0.0;
    int currentStreak = 0;
    int bestStreak = 0;
    Map<String, int> dailyCompletions = {};
    Map<String, int> categoryStats = {};

    for (final check in checks) {
      if (check.analytics != null) {
        totalScheduled += check.analytics!.totalScheduled;
        totalCompleted += check.analytics!.totalCompleted;
        totalMissed += check.analytics!.totalMissed;
        
        if (check.analytics!.currentStreak > currentStreak) {
          currentStreak = check.analytics!.currentStreak;
        }
        
        if (check.analytics!.bestStreak > bestStreak) {
          bestStreak = check.analytics!.bestStreak;
        }

        // Category statistics
        final categoryName = _getCategoryDisplayName(check.category);
        categoryStats[categoryName] = (categoryStats[categoryName] ?? 0) + check.analytics!.totalCompleted;
      }
    }

    if (totalScheduled > 0) {
      averageCompletionRate = totalCompleted / totalScheduled;
    }

    // Generate daily completions for the last 30 days
    for (int i = 0; i < 30; i++) {
      final date = thirtyDaysAgo.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyCompletions[dateStr] = 0; // This would be calculated from actual occurrence data
    }

    return {
      'totalScheduled': totalScheduled,
      'totalCompleted': totalCompleted,
      'totalMissed': totalMissed,
      'averageCompletionRate': averageCompletionRate,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'dailyCompletions': dailyCompletions,
      'categoryStats': categoryStats,
      'checksCount': checks.length,
      'activeChecksCount': checks.where((c) => c.enabled).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Progress'),
                    Tab(text: 'Insights'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildProgressTab(),
                      _buildInsightsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildStreakCard(),
          const SizedBox(height: 24),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: AnalyticsCard(
            title: 'Total Completed',
            value: _analytics['totalCompleted']?.toString() ?? '0',
            icon: Icons.check_circle,
            color: AppTheme.successColor,
            subtitle: '${_analytics['totalScheduled'] ?? 0} scheduled',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnalyticsCard(
            title: 'Completion Rate',
            value: '${((_analytics['averageCompletionRate'] ?? 0.0) * 100).toInt()}%',
            icon: Icons.trending_up,
            color: AppTheme.primaryColor,
            subtitle: 'Average',
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakItem(
                  'Current Streak',
                  _analytics['currentStreak']?.toString() ?? '0',
                  Icons.local_fire_department,
                  AppTheme.warningColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _buildStreakItem(
                  'Best Streak',
                  _analytics['bestStreak']?.toString() ?? '0',
                  Icons.emoji_events,
                  AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final categoryStats = _analytics['categoryStats'] as Map<String, int>? ?? {};
    
    if (categoryStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart,
                size: 48,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 12),
              Text(
                'No data yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Complete some checks to see category breakdown',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryStats.entries.map((entry) => _buildCategoryItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, int count) {
    final total = _analytics['totalCompleted'] as int? ?? 1;
    final percentage = (count / total * 100).toInt();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(category),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: count / total,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count ($percentage%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCompletionChart(),
          const SizedBox(height: 24),
          _buildHeatmapCalendar(),
        ],
      ),
    );
  }

  Widget _buildCompletionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: AnalyticsChart(
                data: _generateChartData(),
                type: ChartType.line,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapCalendar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Heatmap',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            HeatmapCalendar(
              data: _analytics['dailyCompletions'] as Map<String, int>? ?? {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInsightCard(
            'Consistency',
            _getConsistencyInsight(),
            Icons.trending_up,
            AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            'Best Category',
            _getBestCategoryInsight(),
            Icons.star,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            'Improvement',
            _getImprovementInsight(),
            Icons.lightbulb,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String content, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateChartData() {
    // Generate sample data for the last 7 days
    final spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), (i * 2 + 3).toDouble()));
    }
    return spots;
  }

  String _getConsistencyInsight() {
    final rate = _analytics['averageCompletionRate'] as double? ?? 0.0;
    if (rate >= 0.8) {
      return 'Excellent! You\'re maintaining great consistency with your health checks.';
    } else if (rate >= 0.6) {
      return 'Good progress! Try to complete a few more checks to improve consistency.';
    } else {
      return 'Keep going! Every small step counts towards building healthy habits.';
    }
  }

  String _getBestCategoryInsight() {
    final categoryStats = _analytics['categoryStats'] as Map<String, int>? ?? {};
    if (categoryStats.isEmpty) {
      return 'Complete some checks to see which category you excel in!';
    }
    
    final bestCategory = categoryStats.entries.reduce((a, b) => a.value > b.value ? a : b);
    return 'You\'re doing great with ${bestCategory.key.toLowerCase()}! Keep up the excellent work.';
  }

  String _getImprovementInsight() {
    final currentStreak = _analytics['currentStreak'] as int? ?? 0;
    final bestStreak = _analytics['bestStreak'] as int? ?? 0;
    
    if (currentStreak == bestStreak && currentStreak > 0) {
      return 'You\'re on your best streak! Try to maintain this momentum.';
    } else if (currentStreak > 0) {
      return 'You\'re building a good streak. Your best was $bestStreak days - you can beat it!';
    } else {
      return 'Start a new streak today! Even one check can begin a positive habit.';
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
}
