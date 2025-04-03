import 'package:adhd_tracker/providers.dart/symptom_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhd_tracker/providers.dart/medication_provider.dart';
import 'package:adhd_tracker/utils/color.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MedicationLoggingPage extends StatefulWidget {
  const MedicationLoggingPage({Key? key}) : super(key: key);

  @override
  State<MedicationLoggingPage> createState() => _MedicationLoggingPageState();
}

class _MedicationLoggingPageState extends State<MedicationLoggingPage> {
  late TextEditingController medicationController;
  late TextEditingController dosageController;
  late TextEditingController timeController;
  late TextEditingController effectsController;
  late TextEditingController dateController;
  
  // Flag to prevent multiple submissions
  bool _isSubmitting = false;
  
  // Predefined list of common ADHD medications
  final List<String> _predefinedMedications = [
    'Adderall XR',
    'Foquest',
    'Concerta',
    'Vyvanse',
    'Strattera',
    'Focalin',
    'Dexedrine',
    'Intuniv',
    'Quillivant XR',
    'Daytrana',
    'Jornay PM',
    'Qelbree'
  ];
  
  // Track if a predefined medication is selected
  String? _selectedMedication;

  @override
  void initState() {
    super.initState();
    medicationController = TextEditingController();
    dosageController = TextEditingController();
    timeController = TextEditingController();
    effectsController = TextEditingController();
    dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now())
    );

    // Initialize the provider with the current date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      provider.updateDate(dateController.text);
    });
  }

  @override
  void dispose() {
    medicationController.dispose();
    dosageController.dispose();
    timeController.dispose();
    effectsController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, MedicationProvider provider) async {
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

  void _skipMedicationLogging() {
    // Prevent multiple taps
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    // Check if symptoms have been submitted
    final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);
    if (symptomProvider.hasSubmittedSymptoms) {
      // If symptoms have been submitted, navigate to home page
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      // If symptoms haven't been submitted, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please submit symptoms before continuing')),
      );
      // Navigate back to the symptoms screen
      Navigator.pop(context);
    }
    
    // Reset the submission flag if we didn't navigate away
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Method to select a predefined medication
  void _selectPredefinedMedication(String medication) {
    setState(() {
      _selectedMedication = medication;
      medicationController.text = medication;
    });
    // Update the provider
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    provider.updateMedicationName(medication);
  }
  
  // Method to handle medication submission with debounce
  Future<void> _handleSubmitMedication(MedicationProvider provider) async {
    // Prevent multiple submissions
    if (_isSubmitting || provider.isLoading) return;
    
    // Validate all fields
    if (medicationController.text.isEmpty ||
        dosageController.text.isEmpty ||
        timeController.text.isEmpty ||
        effectsController.text.isEmpty ||
        dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Set the submission flag
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Submit medication data
      await provider.submitMedication(context);
      
      // We don't need to reset _isSubmitting here since we either navigate away
      // or the provider will reset its own loading state
    } catch (e) {
      // Show error message if submission fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Reset the submission flag
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontScale = size.width / 375.0;
    final darkPurple = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Medication',
          style: GoogleFonts.lato(
            fontSize: 20 * fontScale,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedicationSection(provider),
                const SizedBox(height: 16),
                _buildDateField(
                  context: context,
                  provider: provider,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  title: 'Dosage',
                  icon: Icons.scale,
                  controller: dosageController,
                  onChanged: provider.updateDosage,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  title: 'Time of Day',
                  icon: Icons.access_time,
                  controller: timeController,
                  onChanged: provider.updateTimeOfDay,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  title: 'Effects (comma-separated)',
                  icon: Icons.psychology,
                  controller: effectsController,
                  onChanged: provider.updateEffects,
                ),
                const SizedBox(height: 54),
                if (provider.error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      provider.error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                // Row for Submit and Skip buttons
                Row(
                  children: [
                    // Submit Button (expanded to take available space)
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: provider.isLoading || _isSubmitting 
                            ? null 
                            : () => _handleSubmitMedication(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.upeiRed,
                          minimumSize: Size(0, size.height * 0.07),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: provider.isLoading || _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 18 * fontScale,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Skip Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || provider.isLoading 
                            ? null 
                            : _skipMedicationLogging,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          minimumSize: Size(0, size.height * 0.07),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 18 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // New widget for handling medication selection
  Widget _buildMedicationSection(MedicationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medication Name',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        // Custom medication field
        TextField(
          style: TextStyle(color: Colors.black),
          controller: medicationController,
          onChanged: (value) {
            provider.updateMedicationName(value);
            // Clear selected medication if text is changed manually
            if (_selectedMedication != null && value != _selectedMedication) {
              setState(() {
                _selectedMedication = null;
              });
            }
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.medication),
            hintText: 'Enter medication name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        const SizedBox(height: 12),
        // Section title for predefined medications
        Text(
          'Common ADHD Medications',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        // Predefined medications chip list
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedMedications.map((medication) {
            final isSelected = medication == _selectedMedication;
            return ChoiceChip(
              label: Text(medication),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _selectPredefinedMedication(medication);
                } else if (isSelected) {
                  // Deselect medication
                  setState(() {
                    _selectedMedication = null;
                    medicationController.clear();
                  });
                  provider.updateMedicationName('');
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppTheme.upeiRed.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.upeiRed : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: TextStyle(color: Colors.black),
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
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

  Widget _buildDateField({
    required BuildContext context,
    required MedicationProvider provider,
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