import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';

/// Custom schedule dialog for setting quiet hours
class CustomScheduleDialog extends StatefulWidget {
  final TimeOfDay initialStartTime;
  final TimeOfDay initialEndTime;
  final List<int> initialSelectedDays; // 0 = Monday, 6 = Sunday

  const CustomScheduleDialog({
    super.key,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.initialSelectedDays,
  });

  @override
  State<CustomScheduleDialog> createState() => _CustomScheduleDialogState();
}

class _CustomScheduleDialogState extends State<CustomScheduleDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
    _selectedDays = List.from(widget.initialSelectedDays);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final dialogHeight = size.height * 0.85; // 85% of screen height
    final dialogWidth = size.width > 400 ? 400.0 : size.width * 0.9;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'set_custom_schedule'.tr,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.mutedText),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            
            // Start Time Section
            Text(
              'start_time'.tr,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            _buildTimePicker(
              time: _startTime,
              onTimeChanged: (newTime) {
                setState(() {
                  _startTime = newTime;
                });
              },
              height: isSmallScreen ? 150 : 200,
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            
            // End Time Section
            Text(
              'end_time'.tr,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            _buildTimePicker(
              time: _endTime,
              onTimeChanged: (newTime) {
                setState(() {
                  _endTime = newTime;
                });
              },
              height: isSmallScreen ? 150 : 200,
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),
            
            // Days of Week Section
            Text(
              'select_days'.tr,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            _buildDaysSelector(),
            SizedBox(height: isSmallScreen ? 16 : 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    child: Text(
                      'cancel'.tr,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedDays.isEmpty
                        ? null
                        : () {
                            Get.back(result: {
                              'startTime': _startTime,
                              'endTime': _endTime,
                              'selectedDays': _selectedDays,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 14,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'save'.tr,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onTimeChanged,
    double height = 200,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Hour Picker
          Expanded(
            child: _buildScrollableNumberPicker(
              value: time.hour,
              min: 0,
              max: 23,
              onChanged: (hour) {
                onTimeChanged(TimeOfDay(hour: hour, minute: time.minute));
              },
              label: 'hour'.tr,
              itemExtent: height * 0.25,
            ),
          ),
          Text(
            ':',
            style: TextStyle(
              fontSize: height * 0.12,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          // Minute Picker
          Expanded(
            child: _buildScrollableNumberPicker(
              value: time.minute,
              min: 0,
              max: 59,
              step: 5, // 5-minute intervals
              onChanged: (minute) {
                onTimeChanged(TimeOfDay(hour: time.hour, minute: minute));
              },
              label: 'minute'.tr,
              itemExtent: height * 0.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableNumberPicker({
    required int value,
    required int min,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
    required String label,
    double itemExtent = 50,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: itemExtent,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
              initialItem: ((value - min) / step).round(),
            ),
            onSelectedItemChanged: (index) {
              final newValue = min + (index * step);
              if (newValue >= min && newValue <= max) {
                onChanged(newValue);
              }
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final itemValue = min + (index * step);
                final isSelected = itemValue == value;
                
                if (itemValue > max) return const SizedBox.shrink();
                
                return Center(
                  child: Text(
                    itemValue.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: isSelected 
                          ? (isSmallScreen ? 24 : 28) 
                          : (isSmallScreen ? 18 : 20),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryBlue : Colors.grey.shade600,
                    ),
                  ),
                );
              },
              childCount: ((max - min) / step).round() + 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final dayButtonSize = isSmallScreen ? 40.0 : 48.0;
    final spacing = isSmallScreen ? 6.0 : 8.0;
    
    final dayNames = [
      'mon'.tr,
      'tue'.tr,
      'wed'.tr,
      'thu'.tr,
      'fri'.tr,
      'sat'.tr,
      'sun'.tr,
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(index);
              } else {
                _selectedDays.add(index);
              }
              _selectedDays.sort();
            });
          },
          child: Container(
            width: dayButtonSize,
            height: dayButtonSize,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                dayNames[index],
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

