import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:adhd_tracker/models/database_helper.dart';
import 'package:adhd_tracker/models/goals.dart';
import 'package:adhd_tracker/ui/home/goals/add_goal.dart';
import 'package:adhd_tracker/utils/color.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
   late Future<List<Goal>> _goalsFuture;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _refreshGoals();
     _scrollController.addListener(_onScrollStopped);
  }
@override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _refreshGoals() {
    setState(() {
      _goalsFuture = DatabaseHelper.instance.getAllGoals();
    });
  }

  void _onScrollStopped() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteGoal(goal.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        _refreshGoals();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete goal: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No goals set yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create a goal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.upeiRed.withOpacity(0.1),
              ),
              child: const Icon(Icons.flag_rounded, color: AppTheme.upeiRed, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Frequency: ${goal.frequency}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Started: ${goal.startDate}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  if (goal.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(goal.notes, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.upeiGreen),
              onPressed: () => _deleteGoal(goal),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Goals',
          style: GoogleFonts.lato(
            textStyle:  TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color,),
          ),
        ),
      ),
      body: FutureBuilder<List<Goal>>(
        future: _goalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading goals: ${snapshot.error}', textAlign: TextAlign.center));
          }
          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return Center(child: Text('No goals set yet. Tap + to add one.'));
          }
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) => _buildGoalCard(goals[index]),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const NewGoalPage()));
              _refreshGoals();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.upeiRed,
              minimumSize: Size(double.infinity, MediaQuery.of(context).size.height * 0.07),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              'Add Goal',
              style: TextStyle(
                fontSize: 18 * MediaQuery.of(context).textScaleFactor,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
