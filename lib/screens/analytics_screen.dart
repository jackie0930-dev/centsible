import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        Map<String, double> categoryTotals = {};
        double totalExpenses = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['type'] == 'Expense') {
            final category = data['category'] as String? ?? 'Others';
            final amount = (data['amount'] as num).toDouble();
            categoryTotals.update(category, (v) => v + amount, ifAbsent: () => amount);
            totalExpenses += amount;
          }
        }

        if (totalExpenses == 0) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'No expenses to analyze yet.\nAdd some transactions to see your spending breakdown.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final categoryColors = {
          'Food': Colors.orange,
          'Transport': Colors.blue,
          'Academics': Colors.purple,
          'Others': Colors.grey,
        };
        final categoryIcons = {
          'Food': Icons.restaurant,
          'Transport': Icons.directions_bus,
          'Academics': Icons.school,
          'Others': Icons.more_horiz,
        };

        final sections = categoryTotals.entries.map((e) {
          final pct = (e.value / totalExpenses * 100).toStringAsFixed(0);
          return PieChartSectionData(
            value: e.value,
            color: categoryColors[e.key] ?? Colors.grey,
            title: '$pct%',
            radius: 48,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Spending Breakdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${totalExpenses.toStringAsFixed(2)} total',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...categoryTotals.entries.map((e) {
                final pct = (e.value / totalExpenses * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        categoryIcons[e.key] ?? Icons.more_horiz,
                        color: categoryColors[e.key] ?? Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(e.key, style: const TextStyle(fontSize: 15)),
                      const Spacer(),
                      Text(
                        '₱${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${pct.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
