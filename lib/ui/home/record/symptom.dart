import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhd_tracker/providers.dart/symptom_provider.dart';
import 'package:adhd_tracker/utils/color.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:adhd_tracker/ui/home/record/medication.dart';

class SymptomLogging extends StatefulWidget {
  final DateTime? selectedDate;
  const SymptomLogging({Key? key, this.selectedDate}) : super(key: key);
  @override
  State<SymptomLogging> createState() => _SymptomLoggingState();
}

class _SymptomLoggingState extends State<SymptomLogging> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? selectedFrequency;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customSymptomController = TextEditingController();
  late TextEditingController dateController;
  Timer? _debounce;
  
  // Add this flag to prevent multiple submissions when tapping rapidly
  bool _isSubmitting = false;
  
  Future<void>? _loadingFuture;

  // Predefined symptoms list
  final List<String> _predefinedSymptoms = [
    'Careless mistakes',
    'Difficulty focusing',
    'Trouble listening',
    'Difficulty following instructions',
    'Difficulty organizing',
    'Avoiding tough mental activities',
    'Losing items',
    'Distracted by surroundings',
    'Forgetful during daily activities',
    'Fidgeting',
    'Leaving seat',
    'Moving excessively',
    'Trouble doing something quietly',
    'Always on the go',
    'Talking excessively',
    'Blurting out answers',
    'Trouble waiting turn',
    'Interrupting'
  ];
  
  // List to store custom symptoms added by the user
  final List<String> _customSymptoms = [];

  final _frequencyOptions = [
    'Morning',
    'Mid Day',
    'Afternoon',
    'Evening',
    'Night',
    'Mid Night',
  ];
  int _selectedFrequencyIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollStopped);
    
    // Use the passed date or default to today
    final selectedDate = widget.selectedDate ?? DateTime.now();
    dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(selectedDate));

    // Initialize the provider with the selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SymptomProvider>(context, listen: false);
      provider.updateDate(dateController.text);
    });
    
    // Initialize the symptom provider with predefined symptoms
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final symptomProvider =
          Provider.of<SymptomProvider>(context, listen: false);

      if (!symptomProvider.isInitialized) {
        // Initialize with predefined symptoms
        symptomProvider.initializeWithPredefinedSymptoms(_predefinedSymptoms);
      }
    });
  }

  Future<void> _selectDate(
      BuildContext context, SymptomProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        dateController.text = formattedDate;
      });
      provider.updateDate(formattedDate);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollStopped);
    _debounce?.cancel();
    _scrollController.dispose();
    _notesController.dispose();
    _customSymptomController.dispose();
    super.dispose();
  }

  void _onScrollStopped() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      final offset = _scrollController.offset;
      final itemHeight = 56.0;
      final index = (offset / itemHeight).round();
      setState(() => _selectedFrequencyIndex = index);
    });
  }

  void _selectFrequency(int index) {
    setState(() => _selectedFrequencyIndex = index);
  }
  
  void _addCustomSymptom() {
    final symptomText = _customSymptomController.text.trim();
    if (symptomText.isNotEmpty) {
      setState(() {
        _customSymptoms.add(symptomText);
        _customSymptomController.clear();
      });
      
      // Add the custom symptom to the provider
      final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
      symptomProvider.addCustomSymptom(symptomText);
    }
  }

  // Updated _handleSubmit method to prevent multiple submissions when tapping rapidly
  Future<void> _handleSubmit() async {
    // Check if we're already submitting to prevent multiple taps
    if (_isSubmitting) {
      return;
    }
    
    final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
    final selectedSymptoms = symptomProvider.symptomSelection.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedSymptoms.isEmpty || selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select symptoms and severity')),
      );
      return;
    }

    // Set the submitting flag to true
    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await symptomProvider.logSymptoms(
        symptoms: selectedSymptoms,
        severity: selectedFrequency!,
        timeOfDay: _frequencyOptions[_selectedFrequencyIndex],
        notes: _notesController.text,
      );

      if (success && mounted) {
        symptomProvider.clearSymptomSelections();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MedicationLoggingPage()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(symptomProvider.error ?? 'Failed to submit symptoms')),
        );
        // Reset the submission flag if there was an error
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      // Handle any exceptions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
    // Note: We don't reset _isSubmitting on success because we're navigating away
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontScale = size.width < 360 ? 0.8 : size.width / 375.0;
    final padding = size.width * 0.04;
    final isSmallScreen = size.height < 600;

    final grey = const Color(0xFFF5F5F5);
    final darkPurple = Theme.of(context).textTheme.titleLarge?.color;

    Widget _buildTitle(String title) {
      return Text(
        title,
        style: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.bold,
            color: darkPurple,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

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
          'Log Symptoms',
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
      body: Consumer<SymptomProvider>(
        builder: (context, symptomProvider, child) {
          if (symptomProvider.error != null) {
            return Center(child: Text(symptomProvider.error!));
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle('Symptoms'),
                        SizedBox(height: padding / 2),
                        
                        // Custom symptom input field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customSymptomController,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'Add a custom symptom',
                                  fillColor: Colors.grey[200],
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addCustomSymptom,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.upeiRed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                        SizedBox(height: padding),
                        
                        // Scrollable list of symptom checkboxes
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: size.height * 0.3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.all(padding / 2),
                            children: symptomProvider.symptomSelection.keys
                                .map((symptom) {
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        symptom,
                                        style: GoogleFonts.lato(
                                          textStyle: TextStyle(
                                            fontSize: 14 * fontScale,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: fontScale,
                                      child: Checkbox(
                                        value: symptomProvider
                                            .symptomSelection[symptom],
                                        onChanged: (bool? value) {
                                          symptomProvider.updateSymptomSelection(
                                            symptom,
                                            value ?? false,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        SizedBox(height: padding * 1.5),
                        _buildTitle('Severity'),
                        SizedBox(height: padding),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _FrequencyButton(
                                label: 'Not at all',
                                isSelected:
                                    selectedFrequency == 'Not at all',
                                onPressed: () => setState(
                                    () => selectedFrequency = 'Not at all'),
                              ),
                              SizedBox(width: padding / 2),
                              _FrequencyButton(
                                label: 'Mild',
                                isSelected: selectedFrequency == 'Mild',
                                onPressed: () => setState(
                                    () => selectedFrequency = 'Mild'),
                              ),
                              SizedBox(width: padding / 2),
                              _FrequencyButton(
                                label: 'Moderate',
                                isSelected: selectedFrequency == 'Moderate',
                                onPressed: () => setState(
                                    () => selectedFrequency = 'Moderate'),
                              ),
                              SizedBox(width: padding / 2),
                              _FrequencyButton(
                                label: 'Severe',
                                isSelected: selectedFrequency == 'Severe',
                                onPressed: () => setState(
                                    () => selectedFrequency = 'Severe'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(
                          context: context,
                          provider: symptomProvider,
                        ),
                        SizedBox(height: padding * 1.5),
                        _buildTitle('Time of day'),
                        SizedBox(height: padding),
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
                                      vertical: padding / 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: padding,
                                    vertical: isSmallScreen ? 8 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedFrequencyIndex == index
                                        ? grey
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: _selectedFrequencyIndex == index
                                        ? Border.all(
                                            color: grey, width: 1.5)
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
                        SizedBox(height: padding * 1.5),
                        _buildTitle('Notes'),
                        SizedBox(height: padding),
                        TextField(
                          style: const TextStyle(color: Colors.black),
                          controller: _notesController,
                          maxLines: isSmallScreen ? 3 : 5,
                          decoration: InputDecoration(
                            hintText: 'Add a note',
                            fillColor: Colors.grey[200],
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        SizedBox(height: padding * 2),
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
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.upeiRed,
                        minimumSize:
                            Size(double.infinity, size.height * 0.07),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Next',
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
          );
        },
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required SymptomProvider provider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: TextStyle(color: Colors.black),
          controller: dateController,
          readOnly: true,
          onTap: () => _selectDate(context, provider),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      ],
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
    final size = MediaQuery.of(context).size;
    final fontScale = size.width < 360 ? 0.8 : size.width / 375.0;

    return SizedBox(
      width: 85 * fontScale,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue[50] : Colors.white,
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
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
            color: isSelected ? Colors.blue : Colors.black,
            fontSize: 14 * fontScale,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}