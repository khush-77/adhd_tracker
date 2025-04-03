import 'package:adhd_tracker/helpers/theme.dart';
import 'package:adhd_tracker/ui/home/record/medication.dart';
import 'package:adhd_tracker/ui/home/record/symptom.dart';
import 'package:adhd_tracker/ui/representation/mood/mood_analytics.dart';
import 'package:adhd_tracker/ui/settings/resources.dart';
import 'package:flutter/material.dart';
import 'package:adhd_tracker/helpers/curved_navbar.dart';
import 'package:adhd_tracker/providers.dart/home_provider.dart';
import 'package:adhd_tracker/ui/home/goals/goals.dart';
import 'package:adhd_tracker/ui/home/reminder/show_reminder.dart';
import 'package:adhd_tracker/ui/settings/settings.dart';
import 'package:adhd_tracker/utils/color.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:adhd_tracker/providers.dart/login_provider.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const GoalsPage(),
    const ReminderListPage(),
    SettingsPage()
  ];

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, int> _moodData = {};
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredPages = [];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _allPages = [];
  void _showDateSelectionDialog(BuildContext context, DateTime selectedDate) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Log Health Data'),
        content: const Text('What would you like to log for this date?'),
        actions: <Widget>[
            TextButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag),
                  SizedBox(width: 8),
                  Text('Add Goal'),
                ],
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => GoalsPage()),
                );
              },
            ),
            TextButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications),
                  SizedBox(width: 8),
                  Text('Set Reminder'),
                ],
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ReminderListPage()),
                );
              },
            ),
          
          TextButton(
            child: const Text('Log Symptoms'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SymptomLogging(selectedDate: selectedDate),
                ),
              );
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  }
  void _createOverlay() {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: _layerLink.leaderSize?.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset:
                const Offset(0, 55), // Adjust this to control dropdown position
            child: Material(
              color: Theme.of(context).textTheme.titleLarge?.color,
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _filteredPages.isEmpty
                      ? _navigationOptions
                          .expand<String>(
                              (option) => option['pages'] as List<String>)
                          .length
                      : _filteredPages.length,
                  itemBuilder: (context, index) {
                    final pages = _filteredPages.isEmpty
                        ? _navigationOptions
                            .expand<String>(
                                (option) => option['pages'] as List<String>)
                            .toList()
                        : _filteredPages;
                    final page = pages[index];

                    String section = '';
                    for (var option in _navigationOptions) {
                      if ((option['pages'] as List<String>).contains(page)) {
                        section = option['label'] as String;
                        break;
                      }
                    }

                    return ListTile(
                      textColor: Theme.of(context).textTheme.titleLarge?.color,
                      leading: Icon(_getIconForSection(section)),
                      title: Text(page, style: TextStyle(color:Colors.black ),),
                      subtitle: Text(section, style: TextStyle(color:Colors.black,),),
                      onTap: () {
                        for (var option in _navigationOptions) {
                          if ((option['pages'] as List<String>)
                              .contains(page)) {
                            _removeOverlay();
                            _navigateToPage(context, option['route']);
                            setState(() {
                              _searchController.clear();
                            });
                            break;
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
  }


   final List<Map<String, dynamic>> _navigationOptions = [
    {
      'label': 'Goals',
      'route': const GoalsPage(),
      'pages': ['Goals Dashboard', 'Goal Setting'],
    },
    {
      'label': 'Reminder',
      'route': const ReminderListPage(),
      'pages': ['Reminders List', 'Set Reminder', 'Reminder History'],
    },
    {
      'label': 'Profile',
      'route': SettingsPage(),
      'pages': ['Profile Settings', 'Account Details'],
    },
    {
      'label': 'Resources',
      'route': ResourcesPage(),
      'pages': ['ADHD Resources', 'Articles'],
    },
    {
      'label': 'Reports',
      'route': AnalyticsPage(),
      'pages': ['Analytics Dashboard', 'Monthly Report'],
    },
    {
      'label': 'Record',
      'route': const SymptomLogging(),
      'pages': ['Symptom Logger', 'Daily Record'],
    }
  ];

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }

  Color getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return const Color(0xFF4CAF50); // Green for Mild
      case 2:
        return const Color(0xFFFFA726); // Orange for Moderate
      case 3:
        return const Color(0xFFE53935); // Red for Severe
      default:
        return Colors.grey;
    }
  }

  String getMoodText(int mood) {
    switch (mood) {
      case 1:
        return "Mild";
      case 2:
        return "Moderate";
      case 3:
        return "Severe";
      default:
        return "Unknown";
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Refresh data when the page gains focus
  _fetchAllData();
}

// Add to dispose method
  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  Future<void> _fetchMoods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final token = loginProvider.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Calculate date range for current month view
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final url = Uri.parse(
          'https://freelance-backend-xx6e.onrender.com/api/v1/mood/mood?startDate=${startDate.toIso8601String().split('T')[0]}&endDate=${endDate.toIso8601String().split('T')[0]}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          Map<DateTime, int> newMoodData = {};

          for (var item in responseData['data']) {
            final date = DateTime.parse(item['date']);
            final normalizedDate = _normalizeDate(date);
            newMoodData[normalizedDate] = item['mood'];
          }

          setState(() {
            _moodData = newMoodData;
          });
        }
      } else {
        throw Exception('Failed to fetch moods');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching mood data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final healthProvider =
          Provider.of<HealthDataProvider>(context, listen: false);

      await Future.wait([
        _fetchMoods(),
        healthProvider.fetchSymptoms(_selectedDate),
        healthProvider.fetchMedications(_selectedDate),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePages();
    _fetchMoods();
    _fetchAllData();
  }
  void _initializePages() {
   _allPages = _navigationOptions
        .expand<String>((option) => (option['pages'] as List<String>? ?? []))
        .toList();
    _filteredPages = List.from(_allPages);
  }

// In your HomePage class, replace _buildDailySummary() with:
  Widget _buildDailySummary() {
    return DayRecordTile(
      selectedDate: _selectedDate,
      moodData: _moodData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 600;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return GestureDetector(
      onTap: () {
        _removeOverlay();
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar:
            Provider.of<LoginProvider>(context, listen: false).isLoggedIn
                ? CustomCurvedNavigationBar(
                    items: [
                      CurvedNavigationBarItem(
                        iconData: Icons.home,
                        selectedIconData: Icons.home,
                      ),
                      CurvedNavigationBarItem(
                        iconData: Icons.flag,
                        selectedIconData: Icons.flag,
                      ),
                      CurvedNavigationBarItem(
                        iconData: Icons.notifications,
                        selectedIconData: Icons.notifications,
                      ),
                      CurvedNavigationBarItem(
                        iconData: Icons.settings,
                        selectedIconData: Icons.settings,
                      ),
                    ],
                    onTap: (index) {
                      if (index == 0) {
                        setState(() {
                          _currentIndex = 0;
                        });
                      } else {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => _pages[index - 1]));
                      }
                    },
                    selectedColor: AppTheme.upeiRed,
                    unselectedColor: Colors.black,
                    currentIndex: _currentIndex,
                  )
                : null,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isLandscape ? 8 : 20,
                      bottom: 16 + bottomPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Replace the Row widget containing the search and dropdown with this:
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration:  BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.asset(
                                      'assets/images/logo.png', // Make sure to add your logo image to assets
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Search Bar with CompositedTransformTarget
                              Expanded(
                                child: CompositedTransformTarget(
                                  link: _layerLink,
                                  child: TextField(
                                    style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color,),
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      hintText: 'Search pages...',
                                      prefixIcon: const Icon(Icons.search),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value.isEmpty) {
                                          _removeOverlay();
                                          _filteredPages = [];
                                        } else {
                                          _filteredPages = _navigationOptions
                                              .expand<String>((option) =>
                                                  option['pages']
                                                      as List<String>)
                                              .where((page) => page
                                                  .toLowerCase()
                                                  .contains(
                                                      value.toLowerCase()))
                                              .toList();
                                          _createOverlay();
                                        }
                                      });
                                    },
                                    onTap: () {
                                      if (_searchController.text.isNotEmpty) {
                                        _createOverlay();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TableCalendar(
                            locale: "en_US",
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                            ),
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDate, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDate = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              final healthProvider =
                                  Provider.of<HealthDataProvider>(context,
                                      listen: false);
                              healthProvider.fetchSymptoms(selectedDay);
                              healthProvider.fetchMedications(selectedDay);
                                _showDateSelectionDialog(context, selectedDay);
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                              _fetchMoods(); // Fetch moods when month changes
                            },
                            calendarBuilders: CalendarBuilders(
                              defaultBuilder: (context, date, events) {
                                final normalizedDate = _normalizeDate(date);
                                final mood = _moodData[normalizedDate];

                                if (mood != null) {
                                  return Container(
                                    margin: const EdgeInsets.all(4.0),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: getMoodColor(mood),
                                    ),
                                    child: Text(
                                      '${date.day}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                              selectedBuilder: (context, date, events) {
                                final normalizedDate = _normalizeDate(date);
                                final mood = _moodData[normalizedDate];

                                return Container(
                                  margin: const EdgeInsets.all(4.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: mood != null
                                        ? getMoodColor(mood)
                                        : const Color(0xFF8D5BFF),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${date.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                              todayBuilder: (context, date, events) {
                                final normalizedDate = _normalizeDate(date);
                                final mood = _moodData[normalizedDate];

                                return Container(
                                  margin: const EdgeInsets.all(4.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: mood != null
                                        ? getMoodColor(mood)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: const Color(0xFF8D5BFF),
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: mood != null
                                          ? Colors.white
                                          : const Color(0xFF8D5BFF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            daysOfWeekHeight: isSmallScreen ? 16 : 20,
                            rowHeight: isSmallScreen ? 42 : 52,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 40),
                        _buildDailySummary(),
                        SizedBox(height: 80 + bottomPadding),

                        SizedBox(height: isSmallScreen ? 16 : 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: _moodData[_selectedDate] == null
                              ? const Text(
                                  '',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                )
                              : Text(
                                  'Mood: ${getMoodText(_moodData[_selectedDate]!)}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                        ),
                        // Add extra padding at bottom to prevent content from being hidden behind navbar
                        SizedBox(height: 80 + bottomPadding),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class DayRecordTile extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, int> moodData;

  const DayRecordTile({
    Key? key,
    required this.selectedDate,
    required this.moodData,
  }) : super(key: key);

  @override
  _DayRecordTileState createState() => _DayRecordTileState();
}

class _DayRecordTileState extends State<DayRecordTile> {
  bool isExpanded = false;

  String getMoodText(int mood) {
    switch (mood) {
      case 1:
        return "Mild";
      case 2:
        return "Moderate";
      case 3:
        return "Severe";
      default:
        return "Unknown";
    }
  }

  String getSymptomsList(dynamic symptoms) {
    if (symptoms == null) return 'None';
    if (symptoms is List) {
      return symptoms.join(", ");
    }
    return symptoms.toString();
  }

  String getEffectsList(dynamic effects) {
    if (effects == null) return 'None';
    if (effects is List) {
      return effects.join(", ");
    }
    return effects.toString();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Consumer<HealthDataProvider>(
      builder: (context, healthProvider, child) {
        final symptoms = healthProvider.symptoms;
        final medications = healthProvider.medications;
        final normalizedDate = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
        );
        final mood = widget.moodData[normalizedDate];

        return Card(
          margin: const EdgeInsets.all(16.0),
          elevation: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Record',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                ),
                trailing: IconButton(
                  icon:
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
              ),
              if (isExpanded)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                   color: themeProvider.isDarkMode 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood Section
                      if (mood != null) ...[
                        const Text(
                          'Mood',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(getMoodText(mood)),
                        ),
                        const Divider(),
                      ],

                      // Symptoms Section
                      if (symptoms.isNotEmpty) ...[
                        const Text(
                          'Symptoms',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: symptoms.length,
                          itemBuilder: (context, index) {
                            final symptom = symptoms[index];
                            return Card(
                              color: themeProvider.isDarkMode 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Time: ${symptom['timeOfDay'] ?? 'Not specified'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                        'Severity: ${symptom['severity'] ?? 'Not specified'}'),
                                    Text(
                                        'Symptoms: ${getSymptomsList(symptom['symptoms'])}'),
                                    if (symptom['notes'] != null &&
                                        symptom['notes'].toString().isNotEmpty)
                                      Text('Notes: ${symptom['notes']}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                      ],

                      // Medications Section
                      if (medications.isNotEmpty) ...[
                        const Text(
                          'Medications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: medications.length,
                          itemBuilder: (context, index) {
                            final medication = medications[index];
                            return Card(
                              color: themeProvider.isDarkMode 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${medication['medicationName'] ?? 'Unknown'} - ${medication['dosage'] ?? 'Not specified'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                        'Time: ${medication['timeOfTheDay'] ?? 'Not specified'}'),
                                    Text(
                                        'Effects: ${getEffectsList(medication['effects'])}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      if (mood == null &&
                          symptoms.isEmpty &&
                          medications.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(Icons.note_alt_outlined,
                                    size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No records for this date',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

IconData _getIconForSection(String section) {
  switch (section) {
    case 'Home':
      return Icons.home;
    case 'Goals':
      return Icons.flag;
    case 'Reminders':
      return Icons.notifications;
    case 'Settings':
      return Icons.settings;
    default:
      return Icons.navigate_next;
  }
}
