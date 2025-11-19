import 'package:flutter/material.dart';

/// Budget Alert Model for tracking budget status
class BudgetAlert {
  final String title;
  final double percentage;
  final double spent;
  final double budget;
  final IconData icon;

  BudgetAlert({
    required this.title,
    required this.percentage,
    required this.spent,
    required this.budget,
    required this.icon,
  });
}
