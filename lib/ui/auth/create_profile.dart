import 'dart:convert';
import 'dart:io';

import 'package:adhd_tracker/helpers/theme.dart';
import 'package:adhd_tracker/ui/auth/login.dart';
import 'package:adhd_tracker/ui/auth/signin.dart';
import 'package:adhd_tracker/ui/home/home.dart';
import 'package:adhd_tracker/ui/home/mood.dart';
import 'package:http/http.dart' as http;

import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:adhd_tracker/providers.dart/profile_provider.dart';

import 'package:adhd_tracker/utils/color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCreationPage extends StatefulWidget {
  const ProfileCreationPage({Key? key}) : super(key: key);

  @override
  _ProfileCreationPageState createState() => _ProfileCreationPageState();
}

class _ProfileCreationPageState extends State<ProfileCreationPage> {
  final String defaultProfilePicUrl =
      'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
  bool hasSelectedOption = false;
  // Predefined lists remain the same
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


  final List<String> _predefinedStrategies = [
    'Psychology',
    'Occupational therapist',
    'Coaching',
    'Financial coaching',
    'Social Work'
  ];

  // State variables
  int _currentStep = 0;
  String? _defaultImageBase64;
  bool _isSkipped = false;
  bool _isLoading = false;
  File? _profileImage;
  String? _base64Image;
  OverlayEntry? _tooltipOverlay;
  bool _hasShownTooltip = false;
  final List<String> _currentMedications = [];
  final List<String> _selectedSymptoms = [];
  final List<String> _selectedStrategies = [];
  bool _hasShownSymptomsTooltip = false;
  OverlayEntry? _symptomsTooltipOverlay;
  bool _isCheckingProfile = true;

  // Controllers
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _customSymptomController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultImage();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      await provider.init();
      _checkProfileStatus();
    });
  }

  @override
  void dispose() {
    _removeTooltip();
    _removeSymptomsTooltip();
    _medicationController.dispose();
    _customSymptomController.dispose();
    super.dispose();
  }

  void _removeSymptomsTooltip() {
    _symptomsTooltipOverlay?.remove();
    _symptomsTooltipOverlay = null;
  }

  void _showTooltip(BuildContext context, GlobalKey key) {
    if (_hasShownTooltip) return;

    // Remove existing tooltip if any
    _removeTooltip();

    // Get the position of the + button
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Calculate screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate tooltip dimensions
    final tooltipWidth = 180.0;
    final tooltipHeight = 60.0;

    // Center the tooltip below the button
    double leftPosition = position.dx + (size.width / 2) - (tooltipWidth / 2);

    // Ensure tooltip doesn't go off screen
    leftPosition = leftPosition.clamp(16.0, screenWidth - tooltipWidth - 16.0);

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition,
        // Position tooltip below the button with some padding
        top: position.dy + size.height + 8,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arrow pointing up (now at the top)
              CustomPaint(
                size: const Size(16, 8),
                painter: TooltipArrowPainter(Colors.black.withOpacity(0.8),
                    isPointingUp: true),
              ),
              // Tooltip content
              Container(
                width: tooltipWidth,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Click + to add medication',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  Future<void> _loadDefaultImage() async {
    try {
      final ByteData bytes = await rootBundle.load('assets/images/default.png');
      final Uint8List list = bytes.buffer.asUint8List();
      _defaultImageBase64 = base64Encode(list);
    } catch (e) {
      print('Error loading default image: $e');
      _showError('Error loading default profile picture');
    }
  }

 Future<void> _checkProfileStatus() async {
  print('Starting profile status check...'); 
  setState(() => _isCheckingProfile = true);
  try {
    // First check if we have a locally saved profile completion status
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedProfile = prefs.getBool('has_completed_profile') ?? false;
    
    if (hasCompletedProfile) {
      print('Local storage indicates profile is complete');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MoodPage()),
      );
      return;
    }
    
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');

    if (token == null) {
      print('No auth token found');
      _redirectToLogin();
      return;
    }
    
    print('Making API request to check profile status...');
    final response = await http.get(
      Uri.parse('https://freelance-backend-xx6e.onrender.com/api/v1/users/getuserdetails'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    print('API Response status code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      print('Profile data received: $data');
      
      // Check if profile is complete
      if (data['isProfilePictureSet'] &&
          data['addMedication'] &&
          data['addSymptoms'] &&
          data['addStrategies']) {
        print('All profile steps completed, navigating to MoodPage...');
        
        // Save to local storage to avoid API calls next time
        await prefs.setBool('has_completed_profile', true);
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MoodPage()),
        );
        return;
      }

      setState(() {
        if (!data['isProfilePictureSet']) {
          print('Profile picture not set, setting step to 0');
          _currentStep = 0;
        } else if (!data['addMedication']) {
          print('Medications not added, setting step to 1');
          _currentStep = 1;
        } else if (!data['addSymptoms']) {
          print('Symptoms not added, setting step to 2');
          _currentStep = 2;
        } else if (!data['addStrategies']) {
          print('Strategies not added, setting step to 3');
          _currentStep = 3;
        }

        if (data['isProfilePictureSet']) {
          print('Profile picture is set, updating UI state');
          _isSkipped = true;
          hasSelectedOption = true;
          _base64Image = data['profilePicture'] ?? defaultProfilePicUrl;
        }
      });
    } else if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 404) {
      // Session expired or invalid token - redirect to login
      print('Authentication error or endpoint not found: ${response.statusCode}');
      _showError('Session expired. Please login again.');
      _redirectToLogin();
    } else {
      print('Unknown error: ${response.statusCode}');
      _showError('Failed to retrieve profile. Please try again.');
      // Let the user continue with profile creation in case of other errors
    }
  } catch (e) {
    print('Error checking profile status: $e');
    _showError('Failed to check profile status');
  } finally {
    if (mounted) {
      setState(() => _isCheckingProfile = false);
    }
  }
}


void _redirectToLogin() {
  const FlutterSecureStorage().delete(key: 'auth_token');
  
  if (!mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
  );
}
  Future<void> _handleStepSubmission() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    bool success = false;

    try {
      switch (_currentStep) {
        case 0:
          if (_profileImage == null && !_isSkipped) {
            setState(() => _isLoading = false);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Profile Picture'),
                content: const Text(
                    'Would you like to add a profile picture or use the default one?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickProfileImage();
                    },
                    child: const Text('Add Picture'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isSkipped = true;
                        _profileImage = null;
                        _base64Image = defaultProfilePicUrl;
                        hasSelectedOption = true;
                      });
                      _handleStepSubmission();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.upeiRed,
                    ),
                    child: const Text('Use Default'),
                  ),
                ],
              ),
            );
            return;
          }

          String imageToUpload =
              _isSkipped ? defaultProfilePicUrl : _base64Image!;
          success = await provider.uploadProfilePicture(imageToUpload);

          if (success) {
            // After successful profile picture upload, check if medications are added
            final token =
                await const FlutterSecureStorage().read(key: 'auth_token');
            final response = await http.get(
              Uri.parse(
                  'https://freelance-backend-xx6e.onrender.com/api/v1/users/getuserdetails'),
              headers: {
                'Authorization': 'Bearer $token',
              },
            );

            if (response.statusCode == 200) {
              final data = json.decode(response.body)['data'];
              if (!data['addMedication']) {
                // If medications are not added, go to medications step
                setState(() => _currentStep = 1);
              } else if (!data['addSymptoms']) {
                // If medications are added but symptoms aren't, go to symptoms step
                setState(() => _currentStep = 2);
              } else if (!data['addStrategies']) {
                // If medications and symptoms are added but strategies aren't, go to strategies step
                setState(() => _currentStep = 3);
              }
            } else {
              // If API call fails, default to next step
              setState(() => _currentStep++);
            }
          }
          break;

        // Rest of the cases remain the same
        case 1:
          if (_currentMedications.isNotEmpty) {
            success = await provider.addMedications(_currentMedications);
          } else {
            // If no medications, still consider it a success
            success = true;
          }
          if (success) setState(() => _currentStep++);
          break;

        case 2:
          if (_selectedSymptoms.isEmpty) {
            _showError('Please select at least one symptom');
            setState(() => _isLoading = false);
            return;
          }
          success = await provider.addSymptoms(_selectedSymptoms);
          if (success) setState(() => _currentStep++);
          break;

        case 3:
                  if (_selectedStrategies.isEmpty) {
          _showError('Please select a support strategy');
          setState(() => _isLoading = false);
          return;
        }
        success = await provider.addStrategy(_selectedStrategies.first);
        if (success) {
          // Save profile completion status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_completed_profile', true);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
        break;
    }

    if (!success) {
      _showError(provider.error ?? 'Failed to save data');
    }
  } catch (e) {
    _showError('An unexpected error occurred');
    print('Error in step submission: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


// New helper method to validate current step
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (!hasSelectedOption) {
          _showError('Please either add a profile picture or skip');
          return false;
        }
        return true;
      case 1:
        return true;
      case 2:
        if (_selectedSymptoms.isEmpty) {
          _showError('Please select at least one symptom');
          return false;
        }
        return true;
      case 3:
        if (_selectedStrategies.isEmpty) {
          _showError('Please select a support strategy');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Profile Picture'),
        content: const Text(
            'Would you like to skip adding a profile picture? A default picture will be used.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isSkipped = true);
              Navigator.pop(context);
              _handleStepSubmission();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _getInputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600]),
      fillColor: Colors.grey[200],
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix,
    );
  }

  Future<void> _handleSkip() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Skip Profile Picture'),
        content: const Text(
            'Are you sure you want to skip adding a profile picture? A default picture will be used.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _profileImage = null;
                _base64Image = defaultProfilePicUrl;
                hasSelectedOption = true;
                _isSkipped = true;
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.upeiRed,
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image
        maxWidth: 800, // Limit width
        maxHeight: 800, // Limit height
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          hasSelectedOption = true;
          _isSkipped = false;
        });

        // Convert to base64
        final bytes = await _profileImage!.readAsBytes();
        _base64Image = base64Encode(bytes);
      }
    } catch (e) {
      _showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_profileImage == null) return null;

    try {
      List<int> imageBytes = await _profileImage!.readAsBytes();
      String base64String = base64Encode(imageBytes);
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  Widget _buildProfileImage() {
    if (_profileImage != null) {
      return CircleAvatar(
        radius: 100,
        backgroundImage: FileImage(_profileImage!),
        onBackgroundImageError: (e, stackTrace) {
          print('Error loading image: $e');
          setState(() {
            _profileImage = null;
            _base64Image = null;
          });
        },
      );
    } else {
      return const CircleAvatar(
        radius: 100,
        child: Icon(Icons.person, size: 100),
      );
    }
  }

  void _addMedication() {
    final medication = _medicationController.text.trim();
    if (medication.isEmpty) return;

    setState(() {
      _currentMedications.add(medication);
      _medicationController.clear();
      _hasShownTooltip = true; // Mark tooltip as shown after first use
    });
    _removeTooltip(); // Remove the tooltip
  }

  void _removeMedication(int index) {
    setState(() => _currentMedications.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final darkPurple = Theme.of(context).textTheme.titleLarge?.color;
    // Calculate responsive values
    final double paddingScale = size.width / 375.0;
    final double fontScale = size.width < 600 ? size.width / 375.0 : 1.5;
    if (_isCheckingProfile) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.upeiRed),
              ),
              const SizedBox(height: 24),
              Text(
                'Checking Profile Status...',
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20 * fontScale,
          ),
        ),
        actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () {
            _redirectToLogin();
          },
          tooltip: 'Logout',
        ),
      ],
    
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          _buildStepIndicators(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              _getStepTitle(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: _buildStepContent(),
          ),
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: _buildNavigationButton(fontScale),
          ),
          SizedBox(
            height: 24,
          )
        ],
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentStep == index
                ? AppTheme.upeiGreen
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  String _getStepTitle() {
    const titles = [
      'Profile Photo',
      'Current Medications',
      'ADHD Symptoms',
      'Support Strategies'
    ];
    return titles[_currentStep];
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildProfilePhotoStep();
      case 1:
        return _buildCurrentMedicationsStep();
      case 2:
        return _buildADHDSymptomsStep();
      case 3:
        return _buildStrategiesStep();
      default:
        return Container();
    }
  }

  Widget _buildNavigationButton(double fontScale) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleStepSubmission,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppTheme.upeiRed,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                _currentStep == 3 ? 'Submit' : 'Next',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * fontScale,
                ),
              ),
      ),
    );
  }

  void _goToNextStep() {
    setState(() {
      _currentStep = (_currentStep + 1) % 4;
    });
  }

  Widget _buildProfilePhotoStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfilePreview(),
          const SizedBox(height: 32),
          if (!hasSelectedOption) ...[
            Text(
              'Choose an option to continue',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickProfileImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.upeiRed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Profile Picture',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _handleSkip,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppTheme.upeiRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (hasSelectedOption)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _isSkipped
                    ? 'Using default profile picture'
                    : 'Profile picture selected',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePreview() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 80,
        backgroundColor: Colors.grey[200],
        child: _profileImage != null
            ? ClipOval(
                child: Image.file(
                  _profileImage!,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.person, size: 80, color: Colors.grey),
      ),
    );
  }

 Widget _buildCurrentMedicationsStep() {
  // Create a GlobalKey for the add button
  final addButtonKey = GlobalKey();

  // Show tooltip when step is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_currentStep == 1 && !_hasShownTooltip) {
      _showTooltip(context, addButtonKey);
    }
  });

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        Text(
          'Optional: Add Current Medications',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _medicationController,
          onSubmitted: (_) {
            _addMedication();
            _removeTooltip();
            setState(() => _hasShownTooltip = true);
          },
          decoration: InputDecoration(
            labelText: 'Enter Medication (Optional)',
            suffixIcon: IconButton(
              key: addButtonKey, // Add the key to the add button
              icon: const Icon(Icons.add),
              onPressed: () {
                _addMedication();
                _removeTooltip();
                setState(() => _hasShownTooltip = true);
              },
            ),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Wrap the Expanded with Flexible to handle keyboard resizing
        Flexible(
          child: _currentMedications.isEmpty && _predefinedMedications.isEmpty
              ? SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'No medications added yet\nUse the + button to add medications or skip this step',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _removeTooltip();
                            setState(() {
                              _currentStep++;
                              _hasShownTooltip = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.upeiRed,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Skip Medications',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  // Adding physics to ensure good scrolling behavior
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Add padding to ensure content doesn't get cut off at bottom
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    // Display custom added medications
                    if (_currentMedications.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Your Medications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ..._currentMedications.map((medication) => ListTile(
                          title: Text(medication),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeMedication(_currentMedications.indexOf(medication)),
                          ),
                          dense: true, // Make list items more compact
                        )),
                    
                    // Display predefined medications with checkboxes
                    if (_predefinedMedications.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'Common ADHD Medications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ..._predefinedMedications.map((medication) => CheckboxListTile(
                          title: Text(medication),
                          value: _currentMedications.contains(medication),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _currentMedications.add(medication);
                              } else {
                                _currentMedications.remove(medication);
                              }
                            });
                          },
                          dense: true, // Make list items more compact
                          controlAffinity: ListTileControlAffinity.leading,
                        )),
                  ],
                ),
        ),
        // Add a skip button when medications are added
        if (_currentMedications.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () {
                setState(() => _currentStep++);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Skip Remaining Medications',
                style: TextStyle(
                  color: AppTheme.upeiRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
  Widget _buildADHDSymptomsStep() {
    final addSymptomButtonKey = GlobalKey();

    // Show tooltip when step is built

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _customSymptomController,
            decoration: _getInputDecoration(
              'Type symptom and tap + to add',
              suffix: IconButton(
                key: addSymptomButtonKey, // Add the key to the add button
                icon: const Icon(Icons.add),
                onPressed: () {
                  final customSymptom = _customSymptomController.text.trim();
                  if (customSymptom.isNotEmpty) {
                    setState(() {
                      _selectedSymptoms.add(customSymptom);
                      _customSymptomController.clear();
                      _hasShownSymptomsTooltip = true;
                    });
                    _removeSymptomsTooltip();
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ..._predefinedSymptoms.map((symptom) => CheckboxListTile(
                      title: Text(symptom),
                      value: _selectedSymptoms.contains(symptom),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedSymptoms.add(symptom);
                          } else {
                            _selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                    )),
                ..._selectedSymptoms
                    .where((symptom) => !_predefinedSymptoms.contains(symptom))
                    .map((customSymptom) => ListTile(
                          title: Text(customSymptom),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _selectedSymptoms.remove(customSymptom);
                              });
                            },
                          ),
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategiesStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _predefinedStrategies.length,
        itemBuilder: (context, index) {
          final strategy = _predefinedStrategies[index];
          return RadioListTile<String>(
            title: Text(strategy),
            value: strategy,
            groupValue:
                _selectedStrategies.isEmpty ? null : _selectedStrategies.first,
            onChanged: (String? value) {
              setState(() {
                _selectedStrategies.clear();
                if (value != null) {
                  _selectedStrategies.add(value);
                }
              });
            },
          );
        },
      ),
    );
  }
}

class TooltipArrowPainter extends CustomPainter {
  final Color color;
  final bool isPointingUp;

  TooltipArrowPainter(this.color, {this.isPointingUp = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isPointingUp) {
      // Draw arrow pointing up
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      // Draw arrow pointing down (original behavior)
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
