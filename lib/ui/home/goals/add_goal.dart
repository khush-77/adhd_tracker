import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhd_tracker/models/database_helper.dart';
import 'package:adhd_tracker/models/goals.dart';
import 'package:adhd_tracker/utils/color.dart';

class NewGoalPage extends StatefulWidget {
  const NewGoalPage({super.key});

  @override
  State<NewGoalPage> createState() => _NewGoalPageState();
}

class _NewGoalPageState extends State<NewGoalPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? selectedFrequency;
  String? _selectedFrequency;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _notesController = TextEditingController();
   final TextEditingController _nameController = TextEditingController();
  Timer? _debounce;

  final _frequencyOptions = [
    'Every day',
    'Every other day',
    'Every 3 days',
    'Every 4 days',
    'Every 5 days',
    'Every 6 days',
    'Every Week'
  ];
  int _selectedFrequencyIndex = 0;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime today = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? today) : (_endDate ?? today),
      firstDate: today,
      lastDate: DateTime(today.year + 10),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollStopped);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollStopped);
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

   void _saveGoal() async {
    if (_startDate == null || selectedFrequency == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final goal = Goal(
      name: _nameController.text.trim(),
      frequency: selectedFrequency!,
      startDate: _startDate!,
      notes: _notesController.text,
    );

    await DatabaseHelper.instance.insertGoal(goal);
    Navigator.pop(context);
  }

  void _onScrollStopped() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 100), () {
      final offset = _scrollController.offset;
      final itemHeight = 56.0;
      final index = (offset / itemHeight).round();

      setState(() {
        _selectedFrequencyIndex = index;
      });
    });
  }

  void _selectFrequency(int index) {
    setState(() {
      _selectedFrequencyIndex = index;
      _scrollController.animateTo(
        index * 56.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size and calculate responsive values
    final size = MediaQuery.of(context).size;
    final fontScale = size.width < 360 ? 0.8 : size.width / 375.0;
    final isSmallScreen = size.height < 600;
    final padding = size.width * 0.04;

    // Colors

    final grey = const Color(0xFFF5F5F5);
    final darkPurple = Theme.of(context).textTheme.titleLarge?.color;

    // Padding
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
          'New Goal',
          style: GoogleFonts.lato(
            textStyle: TextStyle(
              fontSize: 20 * fontScale,
              fontWeight: FontWeight.bold,
              color: darkPurple,
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
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    TextField(
                        controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'E.g. Read 20 pages',
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
                      'Frequency',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: _FrequencyButton(
                            label: 'Daily',
                            isSelected: selectedFrequency == 'Daily',
                            onPressed: () {
                              setState(() {
                                selectedFrequency = 'Daily';
                              });
                            },
                          ),
                        ),
                        SizedBox(width: horizontalPadding * 0.25),
                        Expanded(
                          child: _FrequencyButton(
                            label: 'Weekly',
                            isSelected: selectedFrequency == 'Weekly',
                            onPressed: () {
                              setState(() {
                                selectedFrequency = 'Weekly';
                              });
                            },
                          ),
                        ),
                        SizedBox(width: horizontalPadding * 0.25),
                        Expanded(
                          child: _FrequencyButton(
                            label: 'Monthly',
                            isSelected: selectedFrequency == 'Monthly',
                            onPressed: () {
                              setState(() {
                                selectedFrequency = 'Monthly';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: verticalSpacing * 2),
                    Text(
                      'How often?',
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: darkPurple,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    SizedBox(
                      height: isSmallScreen ? 100 : 120,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _frequencyOptions.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _selectFrequency(index),
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: verticalSpacing * 0.4,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalSpacing * 0.6,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedFrequencyIndex == index
                                    ? grey
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: _selectedFrequencyIndex == index
                                    ? Border.all(color: grey, width: 1.5)
                                    : null,
                              ),
                              child: Text(
                                _frequencyOptions[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14 * fontScale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 2),
                    TextField(
                      controller: _notesController,
                      maxLines: isSmallScreen ? 3 : 5,
                      decoration: InputDecoration(
                        hintText: 'Add optional notes...',
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
                      'Start date',
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
                      title: Text(
                        _startDate != null
                            ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"
                            : "Select Start Date",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(padding),
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
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    _saveGoal();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.upeiRed,
                    minimumSize: Size(double.infinity, size.height * 0.07),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Create Goal',
                    style: TextStyle(
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

class _FrequencyButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _FrequencyButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[50] : Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.upeiRed : Colors.grey[400]!,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.upeiRed : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}