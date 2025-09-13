import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/check.dart';
import '../../models/schedule.dart';
import '../../services/storage_service.dart';
import '../../services/schedule_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/schedule_picker.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/snooze_policy_editor.dart';

class AddCheckScreen extends StatefulWidget {
  final Check? checkToEdit;

  const AddCheckScreen({
    super.key,
    this.checkToEdit,
  });

  @override
  State<AddCheckScreen> createState() => _AddCheckScreenState();
}

class _AddCheckScreenState extends State<AddCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  CheckCategory _selectedCategory = CheckCategory.hydration;
  ScheduleType _scheduleType = ScheduleType.daily;
  Map<String, dynamic> _scheduleData = {};
  String? _rruleString;
  SnoozePolicy _snoozePolicy = SnoozePolicy.defaultPolicy();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.checkToEdit != null) {
      _loadExistingCheck();
    } else {
      _setDefaultSchedule();
    }
  }

  void _loadExistingCheck() {
    final check = widget.checkToEdit!;
    _titleController.text = check.title;
    _descriptionController.text = check.description ?? '';
    _selectedCategory = check.category;
    _scheduleType = check.scheduleType;
    _scheduleData = check.scheduleData ?? {};
    _rruleString = check.rruleString;
    _snoozePolicy = check.snoozePolicy;
  }

  void _setDefaultSchedule() {
    _scheduleData = {
      'type': 'daily',
      'time': {'hour': 9, 'minute': 0},
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.checkToEdit != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Check' : 'Add Check'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCheck,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBasicInfo(),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  _buildScheduleSection(),
                  const SizedBox(height: 24),
                  _buildSnoozePolicySection(),
                  const SizedBox(height: 24),
                  _buildPreviewSection(),
                  const SizedBox(height: 32),
                  if (!_isLoading) _buildActionButtons(isEditing),
                ],
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
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Drink Water',
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
                labelText: 'Description (optional)',
                hintText: 'e.g., Stay hydrated throughout the day',
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
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            CategorySelector(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
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
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SchedulePicker(
              scheduleType: _scheduleType,
              scheduleData: _scheduleData,
              rruleString: _rruleString,
              onScheduleChanged: (type, data, rrule) {
                setState(() {
                  _scheduleType = type;
                  _scheduleData = data;
                  _rruleString = rrule;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozePolicySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snooze Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SnoozePolicyEditor(
              snoozePolicy: _snoozePolicy,
              onChanged: (policy) {
                setState(() {
                  _snoozePolicy = policy;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getScheduleDescription(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Next 3 occurrences:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ..._getPreviewOccurrences().map((date) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                '• ${_formatPreviewDate(date)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _saveCheck,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Text(isEditing ? 'Update Check' : 'Create Check'),
        ),
        if (isEditing) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _deleteCheck,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
            ),
            child: const Text('Delete Check'),
          ),
        ],
      ],
    );
  }

  String _getScheduleDescription() {
    final tempCheck = Check(
      title: _titleController.text.isNotEmpty ? _titleController.text : 'New Check',
      category: _selectedCategory,
      scheduleType: _scheduleType,
      scheduleData: _scheduleData,
      rruleString: _rruleString,
    );
    
    return Provider.of<ScheduleService>(context, listen: false)
        .getScheduleDescription(tempCheck);
  }

  List<DateTime> _getPreviewOccurrences() {
    try {
      final tempCheck = Check(
        title: _titleController.text.isNotEmpty ? _titleController.text : 'New Check',
        category: _selectedCategory,
        scheduleType: _scheduleType,
        scheduleData: _scheduleData,
        rruleString: _rruleString,
      );
      
      return Provider.of<ScheduleService>(context, listen: false)
          .previewOccurrences(check: tempCheck, count: 3);
    } catch (e) {
      return [];
    }
  }

  String _formatPreviewDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    String dateStr;
    if (dateOnly == today) {
      dateStr = 'Today';
    } else if (dateOnly == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }
    
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  Future<void> _saveCheck() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      final check = widget.checkToEdit?.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        scheduleType: _scheduleType,
        scheduleData: _scheduleData,
        rruleString: _rruleString,
        snoozePolicy: _snoozePolicy,
      ) ?? Check(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        scheduleType: _scheduleType,
        scheduleData: _scheduleData,
        rruleString: _rruleString,
        snoozePolicy: _snoozePolicy,
      );

      await storageService.saveCheck(check);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.checkToEdit != null 
                ? 'Check updated successfully!' 
                : 'Check created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCheck() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Check'),
        content: const Text('Are you sure you want to delete this check? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.checkToEdit != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final storageService = Provider.of<StorageService>(context, listen: false);
        await storageService.deleteCheck(widget.checkToEdit!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check deleted successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.of(context).pop(true);
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
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

extension CheckCopyWith on Check {
  Check copyWith({
    String? title,
    String? description,
    CheckCategory? category,
    ScheduleType? scheduleType,
    Map<String, dynamic>? scheduleData,
    String? rruleString,
    bool? enabled,
    SnoozePolicy? snoozePolicy,
  }) {
    return Check(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduleData: scheduleData ?? this.scheduleData,
      rruleString: rruleString ?? this.rruleString,
      enabled: enabled ?? this.enabled,
      snoozePolicy: snoozePolicy ?? this.snoozePolicy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      analytics: analytics,
      iconName: iconName,
      colorValue: colorValue,
      tags: tags,
      isArchived: isArchived,
      pausedRanges: pausedRanges,
      skippedOccurrences: skippedOccurrences,
    );
  }
}
