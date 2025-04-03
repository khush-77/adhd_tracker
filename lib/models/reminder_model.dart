
import 'package:flutter/material.dart';

class Reminder {
  final int? id;
  final String name;
  final String frequency;
  final DateTime startDate;
  final String notes;
  final bool isCompleted;
  final TimeOfDay scheduledTime;
  final String? sound;

  Reminder({
    this.id,
    required this.name,
    required this.frequency,
    required this.startDate,
    required this.notes,
    this.isCompleted = false,
    required this.scheduledTime,
    this.sound,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'notes': notes,
      'isCompleted': isCompleted ? 1 : 0,
      'scheduledTime': '${scheduledTime.hour}:${scheduledTime.minute}',
      'sound': sound,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    final timeStr = map['scheduledTime'].split(':');
    return Reminder(
      id: map['id'],
      name: map['name'],
      frequency: map['frequency'],
      startDate: DateTime.parse(map['startDate']),
      notes: map['notes'],
      isCompleted: map['isCompleted'] == 1,
      scheduledTime: TimeOfDay(
        hour: int.parse(timeStr[0]),
        minute: int.parse(timeStr[1]),
      ),
      sound: map['sound'],
    );
  }
}