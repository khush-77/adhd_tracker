import 'package:flutter/material.dart';
import 'package:adhd_tracker/helpers/theme.dart';
import 'package:adhd_tracker/providers.dart/users_provider.dart';
import 'package:provider/provider.dart';

class PersonalInformationPage extends StatefulWidget {
  @override
  _PersonalInformationPageState createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  bool _isUpdating = false;

  final List<String> _predefinedStrategies = [
    'Psychology',
    'Occupational therapist',
    'Coaching',
    'Financial coaching',
    'Social Work'
  ];

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

  Future<void> _showMultiSelectDialog(
    BuildContext context,
    String title,
    List<String> currentItems,
    List<String> predefinedItems,
    Future<void> Function(List<String>) onSave,
  ) async {
    final selectedItems = Set<String>.from(currentItems);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => WillPopScope(
          onWillPop: () async => !_isUpdating,
          child: AlertDialog(
            title: Text('Select $title'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUpdating)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...predefinedItems.map(
                      (item) => CheckboxListTile(
                        title: Text(item),
                        value: selectedItems.contains(item),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedItems.add(item);
                            } else {
                              selectedItems.remove(item);
                            }
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isUpdating ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _isUpdating
                    ? null
                    : () async {
                        setState(() => _isUpdating = true);
                        
                        try {
                          await onSave(selectedItems.toList());
                          Navigator.pop(context);
                        } finally {
                          if (mounted) {
                            setState(() => _isUpdating = false);
                          }
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditMedicationsDialog(
    BuildContext context,
    List<String> currentItems,
    Future<void> Function(List<String>) onSave,
  ) async {
    final items = List<String>.from(currentItems);
    final textController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => WillPopScope(
          onWillPop: () async => !_isUpdating,
          child: AlertDialog(
            title: const Text('Edit Medications'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUpdating)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Column(
                      children: [
                        ...items.map(
                          (item) => ListTile(
                            title: Text(item),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  items.remove(item);
                                });
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: textController,
                            decoration: InputDecoration(
                              labelText: 'Add new medication',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  if (textController.text.isNotEmpty) {
                                    setState(() {
                                      items.add(textController.text);
                                      textController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  items.add(value);
                                  textController.clear();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isUpdating ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _isUpdating
                    ? null
                    : () async {
                        setState(() => _isUpdating = true);
                        
                        try {
                          await onSave(items);
                          Navigator.pop(context);
                        } finally {
                          if (mounted) {
                            setState(() => _isUpdating = false);
                          }
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateMedications(BuildContext context, List<String> medications) async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isUpdating = true);
    
    try {
      final success = await provider.updateMedications(medications);
      if (!success && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      } else if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medications updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await provider.fetchProfileData();
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateSymptoms(BuildContext context, List<String> symptoms) async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isUpdating = true);
    
    try {
      final success = await provider.updateSymptoms(symptoms);
      if (!success && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      } else if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptoms updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await provider.fetchProfileData();
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateStrategies(BuildContext context, List<String> strategies) async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isUpdating = true);
    
    try {
      final success = await provider.updateStrategies(strategies);
      if (!success && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      } else if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Strategies updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await provider.fetchProfileData();
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
@override
Widget build(BuildContext context) {
  return Consumer<UserProvider>(
    builder: (context, userProvider, _) {
      final profileData = userProvider.profileData;
      
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Personal Information',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!_isUpdating)
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () => userProvider.fetchProfileData(),
              ),
          ],
        ),
        body: profileData == null && !userProvider.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No profile data available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => userProvider.fetchProfileData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => userProvider.fetchProfileData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profileData != null) ...[
                          _buildSection(
                            title: 'Basic Information',
                            children: [
                              _buildInfoTile(
                                'Name',
                                profileData.name,
                                Icons.person,
                              ),
                              _buildInfoTile(
                                'Email',
                                profileData.emailId,
                                Icons.email,
                              ),
                              _buildInfoTile(
                                'Member ID',
                                profileData.id,
                                Icons.badge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildEditableSection(
                            context: context,
                            title: 'Medications',
                            icon: Icons.medication,
                            items: profileData.medications,
                            onEdit: () => _showEditMedicationsDialog(
                              context,
                              profileData.medications,
                              (items) => _updateMedications(context, items),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildEditableSection(
                            context: context,
                            title: 'Symptoms',
                            icon: Icons.health_and_safety,
                            items: profileData.symptoms,
                            onEdit: () => _showMultiSelectDialog(
                              context,
                              'Symptoms',
                              profileData.symptoms,
                              _predefinedSymptoms,
                              (items) => _updateSymptoms(context, items),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildEditableSection(
                            context: context,
                            title: 'Strategies',
                            icon: Icons.psychology,
                            items: profileData.strategies,
                            onEdit: () => _showMultiSelectDialog(
                              context,
                              'Strategies',
                              profileData.strategies,
                              _predefinedStrategies,
                              (items) => _updateStrategies(context, items),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (userProvider.isLoading || _isUpdating)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
      );
    },
  );
}

Widget _buildSection({
  required String title,
  required List<Widget> children,
}) {
  return Card(
    elevation: 2,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

Widget _buildInfoTile(String label, String value, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildEditableSection({
  required BuildContext context,
  required String title,
  required IconData icon,
  required List<String> items,
  required VoidCallback onEdit,
}) {
  return Card(
    elevation: 2,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: !_isUpdating ? onEdit : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'No ${title.toLowerCase()} added yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        items[index],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}