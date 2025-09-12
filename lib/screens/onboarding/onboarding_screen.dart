import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/check.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  final Set<CheckCategory> _selectedCategories = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          children: [
            _buildWelcomePage(),
            _buildPermissionPage(),
            _buildCategoriesPage(),
            _buildCompletePage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to MomentCue',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your privacy-first wellness companion for micro-health check-ins',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildFeatureList(),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _nextPage(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {
        'icon': Icons.lock,
        'title': 'Privacy First',
        'description': 'All data stored locally on your device',
      },
      {
        'icon': Icons.notifications_active,
        'title': 'Smart Reminders',
        'description': 'Flexible scheduling with one-tap actions',
      },
      {
        'icon': Icons.analytics,
        'title': 'Track Progress',
        'description': 'Insights to help you build healthy habits',
      },
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    feature['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active,
            size: 100,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            'Stay on track — allow reminders',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'MomentCue uses local notifications to gently remind you of quick health checks. Notifications are stored only on your device.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Card(
            color: AppTheme.infoColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can manage notification settings anytime in your device settings.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _isLoading ? null : _requestNotificationPermission,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Allow Notifications'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _nextPage(),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'What would you like to track?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose categories that matter to you. We\'ll create helpful default reminders.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: CheckCategory.values
                  .where((category) => category != CheckCategory.custom)
                  .map((category) => _buildCategoryCard(category))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedCategories.isNotEmpty || _isLoading
                ? (_isLoading ? null : _createDefaultChecks)
                : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_selectedCategories.isEmpty
                    ? 'Skip and continue'
                    : 'Create ${_selectedCategories.length} checks'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CheckCategory category) {
    final isSelected = _selectedCategories.contains(category);
    final categoryInfo = _getCategoryInfo(category);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(category);
          } else {
            _selectedCategories.add(category);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryInfo['icon'] as IconData,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              categoryInfo['name'] as String,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              categoryInfo['description'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re all set!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your wellness journey starts now. Remember, small consistent actions lead to big changes.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Card(
            color: AppTheme.successColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.successColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pro Tip',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start with just one or two reminders and gradually add more as they become habits.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _completeOnboarding,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Start Your Journey'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryInfo(CheckCategory category) {
    switch (category) {
      case CheckCategory.hydration:
        return {
          'name': 'Hydration',
          'description': 'Water reminders',
          'icon': Icons.water_drop,
        };
      case CheckCategory.posture:
        return {
          'name': 'Posture',
          'description': 'Stretch breaks',
          'icon': Icons.accessibility_new,
        };
      case CheckCategory.medication:
        return {
          'name': 'Medication',
          'description': 'Medicine reminders',
          'icon': Icons.medication,
        };
      case CheckCategory.screenBreak:
        return {
          'name': 'Screen Breaks',
          'description': 'Eye rest periods',
          'icon': Icons.remove_red_eye,
        };
      case CheckCategory.breathing:
        return {
          'name': 'Breathing',
          'description': 'Mindful moments',
          'icon': Icons.air,
        };
      case CheckCategory.exercise:
        return {
          'name': 'Movement',
          'description': 'Activity breaks',
          'icon': Icons.fitness_center,
        };
      default:
        return {
          'name': 'Custom',
          'description': 'Personal reminders',
          'icon': Icons.star,
        };
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.requestPermissions();
      _nextPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request permissions: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultChecks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);

      for (final category in _selectedCategories) {
        final check = _createDefaultCheck(category);
        await storageService.saveCheck(check);
      }

      _nextPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create checks: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Check _createDefaultCheck(CheckCategory category) {
    final categoryInfo = _getCategoryInfo(category);
    
    Map<String, dynamic> scheduleData;
    switch (category) {
      case CheckCategory.hydration:
        scheduleData = {
          'type': 'daily',
          'time': {'hour': 9, 'minute': 0},
          'interval': 2, // Every 2 hours during work day
        };
        break;
      case CheckCategory.posture:
        scheduleData = {
          'type': 'weekdays',
          'time': {'hour': 14, 'minute': 0},
        };
        break;
      case CheckCategory.screenBreak:
        scheduleData = {
          'type': 'weekdays',
          'time': {'hour': 11, 'minute': 0},
        };
        break;
      default:
        scheduleData = {
          'type': 'daily',
          'time': {'hour': 9, 'minute': 0},
        };
    }

    return Check(
      title: categoryInfo['name'],
      description: _getDefaultDescription(category),
      category: category,
      scheduleType: ScheduleType.daily,
      scheduleData: scheduleData,
    );
  }

  String _getDefaultDescription(CheckCategory category) {
    switch (category) {
      case CheckCategory.hydration:
        return 'Time for a glass of water! Stay hydrated throughout the day.';
      case CheckCategory.posture:
        return 'Take a moment to check your posture and stretch if needed.';
      case CheckCategory.medication:
        return 'Remember to take your medication as prescribed.';
      case CheckCategory.screenBreak:
        return 'Give your eyes a break! Look away from the screen for 20 seconds.';
      case CheckCategory.breathing:
        return 'Take 5 deep breaths and center yourself.';
      case CheckCategory.exercise:
        return 'Time for a quick movement break! Stretch or walk around.';
      default:
        return 'Time for your wellness check-in.';
    }
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }
}
