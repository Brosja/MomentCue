import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/simple_check.dart';
import '../../utils/app_theme.dart';
import '../../widgets/notification_schedule_builder.dart';
import '../../models/notification_schedule.dart';
import '../../services/notification_service.dart';

class AddCheckScreen extends StatefulWidget {
  final SimpleCheck? editCheck;
  
  const AddCheckScreen({super.key, this.editCheck});

  @override
  State<AddCheckScreen> createState() => _AddCheckScreenState();
}

class _AddCheckScreenState extends State<AddCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = CheckCategory.categories[0];
  String _selectedScheduleType = CheckScheduleType.types[0];
  bool _isEnabled = true;
  bool _notificationsEnabled = false;
  List<NotificationSchedule> _notificationSchedules = [];
  bool _allowSnooze = true;
  int _maxSnoozes = 3;

  @override
  void initState() {
    super.initState();
    if (widget.editCheck != null) {
      _loadCheckData(widget.editCheck!);
    }
  }

  void _loadCheckData(SimpleCheck check) {
    _titleController.text = check.title;
    _descriptionController.text = check.description ?? '';
    _selectedCategory = check.category;
    _selectedScheduleType = check.scheduleType;
    _isEnabled = check.enabled;
    _notificationsEnabled = check.notificationsEnabled;
    _notificationSchedules = List.from(check.notificationSchedules);
    _allowSnooze = check.allowSnooze;
    _maxSnoozes = check.maxSnoozes;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.editCheck != null ? 'Edit Health Check' : 'Add Health Check',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveCheck,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildScheduleSection(),
              const SizedBox(height: 24),
              _buildEnabledSection(),
              const SizedBox(height: 24),
              _buildNotificationSection(),
              const SizedBox(height: 32),
              _buildPreviewSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Check Title *',
                hintText: 'e.g., Drink Water, Take Medication',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add a note or reminder...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: CheckCategory.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedScheduleType,
              decoration: const InputDecoration(
                labelText: 'How often?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: CheckScheduleType.types.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedScheduleType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnabledSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.toggle_on, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Enable this check',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      children: [
        NotificationScheduleBuilder(
          initialSchedule: _notificationSchedules.isNotEmpty ? _notificationSchedules.first : null,
          onChanged: (schedule) {
            setState(() {
              _notificationSchedules = [schedule];
              _notificationsEnabled = schedule.isEnabled;
            });
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.snooze, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Snooze Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _allowSnooze,
                      onChanged: (value) {
                        setState(() {
                          _allowSnooze = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
                if (_allowSnooze) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Max snoozes:'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _maxSnoozes,
                        items: [1, 2, 3, 5, 10].map((count) {
                          return DropdownMenuItem(
                            value: count,
                            child: Text('$count'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _maxSnoozes = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Title: ${_titleController.text.isEmpty ? "Your check title" : _titleController.text}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Category: $_selectedCategory',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Schedule: $_selectedScheduleType',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Status: ${_isEnabled ? "Enabled" : "Disabled"}',
              style: TextStyle(
                color: _isEnabled ? AppTheme.successColor : AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_notificationsEnabled && _notificationSchedules.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notifications: ${_notificationSchedules.first.displayText}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              if (_allowSnooze) ...[
                const SizedBox(height: 4),
                Text(
                  'Snooze: Up to $_maxSnoozes times',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveCheck() async {
    if (_formKey.currentState!.validate()) {
      final check = SimpleCheck(
        id: widget.editCheck?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        scheduleType: _selectedScheduleType,
        enabled: _isEnabled,
        createdAt: widget.editCheck?.createdAt ?? DateTime.now(),
        notificationsEnabled: _notificationsEnabled,
        notificationSchedules: _notificationSchedules,
        allowSnooze: _allowSnooze,
        maxSnoozes: _maxSnoozes,
      );

      // Schedule notifications if enabled
      if (check.notificationsEnabled) {
        try {
          await NotificationService().scheduleCheckNotifications(check);
        } catch (e) {
          if (kDebugMode) {
            print('Error scheduling notifications: $e');
          }
        }
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Health check "${check.title}" created successfully!'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );

      // Return the check to the previous screen
      Navigator.pop(context, check);
    }
  }
}