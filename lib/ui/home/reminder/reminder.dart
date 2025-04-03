import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhd_tracker/helpers/notification.dart';
import 'package:adhd_tracker/models/goals.dart';
import 'package:adhd_tracker/models/reminder_db.dart';
import 'package:adhd_tracker/models/reminder_model.dart';
import 'package:adhd_tracker/utils/color.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final List<String> _soundOptions = NotificationService.soundMap.keys.toList();
  final List<String> _frequencyOptions = ['Once', 'Twice', 'Thrice'];
  
  String? _selectedSound;
  DateTime? _startDate;
  TimeOfDay? _selectedTime;
  String? _selectedFrequency;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _notesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _scheduleAndSaveReminder() async {
    // Validate required fields
    if (_startDate == null ||
        _selectedFrequency == null ||
        _selectedTime == null ||
        _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      // First create and save the reminder to database
      final reminder = Reminder(
        name: _titleController.text,
        frequency: _selectedFrequency!,
        startDate: _startDate!,
        notes: _notesController.text,
        scheduledTime: _selectedTime!,
        sound: _selectedSound ?? 'Default',
      );

      // Save to database
      await ReminderDatabaseHelper.instance.insertReminder(reminder);

      // Schedule the notification
      final success = await NotificationService.scheduleReminder(
        context: context,
        title: _titleController.text,
        notes: _notesController.text,
        startDate: _startDate!,
        selectedTime: _selectedTime!,
        frequency: _selectedFrequency!,
        sound: _selectedSound ?? 'Default',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder scheduled and saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error scheduling and saving reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule reminder. Please try again.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontScale = size.width < 360 ? 0.8 : size.width / 375.0;
    final isSmallScreen = size.height < 600;
    final darkPurple = Theme.of(context).textTheme.titleLarge?.color;
    final horizontalPadding = size.width * 0.05;
    final verticalSpacing = size.height * 0.02;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'New Reminder',
          style: GoogleFonts.lato(
            textStyle: TextStyle(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: verticalSpacing),
                    TextField(
                      style: TextStyle(color: Colors.grey[600]),
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 2),
                    TextField(
                      style: TextStyle(color: Colors.grey[600]),
                      controller: _notesController,
                      maxLines: isSmallScreen ? 3 : 5,
                      decoration: InputDecoration(
                        hintText: 'Add notes...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 2),
                    Text(
                      'Remind me on a day',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_startDate != null
                          ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"
                          : "Select Start Date"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_selectedTime != null
                          ? _selectedTime!.format(context)
                          : "Select Time"),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context),
                    ),
                    SizedBox(height: verticalSpacing),
                    Text(
                      'Frequency',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: Text(
                        'Select frequency',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      value: _selectedFrequency,
                      items: _frequencyOptions.map((freq) {
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(freq, style: TextStyle(color: Colors.grey[600])),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFrequency = value;
                        });
                      },
                    ),
                    SizedBox(height: verticalSpacing * 2),
                    Text(
                      'Sound',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        fillColor: Colors.grey[200],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: Text(
                        'Select Sound',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      value: _selectedSound,
                      items: _soundOptions.map((sound) {
                        return DropdownMenuItem(
                          value: sound,
                          child: Text(sound, style: TextStyle(color: Colors.grey[600])),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSound = value;
                        });
                      },
                    ),
                    SizedBox(height: verticalSpacing * 3),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalSpacing,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _scheduleAndSaveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.upeiRed,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Schedule Reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * fontScale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}