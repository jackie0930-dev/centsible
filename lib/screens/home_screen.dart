import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_transaction_dialog.dart';
import 'allowance_dialog.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Centsible' : _currentIndex == 1 ? 'Analytics' : 'Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          AnalyticsScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddTransactionDialog(),
              ),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: Colors.teal.shade100,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

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

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data?.docs ?? [];
        transactions.sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final tb = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });

        double totalIncome = 0;
        double totalExpenses = 0;

        for (var doc in transactions) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] as num).toDouble();
          if (data['type'] == 'Income') {
            totalIncome += amount;
          } else {
            totalExpenses += amount;
          }
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('Users').doc(user.uid).snapshots(),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final allowance = (userData?['allowance'] as num?)?.toDouble() ?? 0;

                  return _SummaryCard(
                    totalIncome: totalIncome,
                    totalExpenses: totalExpenses,
                    allowance: allowance,
                    onSetAllowance: () => showDialog(
                      context: context,
                      builder: (_) => AllowanceDialog(currentAllowance: allowance),
                    ),
                  );
                },
              ),
              transactions.isEmpty
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'No transactions yet.\nTap + to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final data =
                            transactions[index].data() as Map<String, dynamic>;
                        return _TransactionTile(data: data);
                      },
                    ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double allowance;
  final VoidCallback onSetAllowance;

  const _SummaryCard({
    required this.totalIncome,
    required this.totalExpenses,
    required this.allowance,
    required this.onSetAllowance,
  });

  @override
  Widget build(BuildContext context) {
    final remainingBalance = (allowance + totalIncome) - totalExpenses;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Remaining Balance',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _formatAmount(remainingBalance),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryLabel(label: 'Income', amount: totalIncome, color: Colors.greenAccent),
                _SummaryLabel(label: 'Total Spent', amount: totalExpenses, color: Colors.redAccent),
              ],
            ),
            if (allowance > 0) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white30, thickness: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryLabel(label: 'Allowance', amount: allowance, color: Colors.white),
                  Column(
                    children: [
                      const Text(
                        'Budget Left',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(allowance - totalExpenses),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSetAllowance,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(allowance > 0 ? 'Change Allowance' : 'Set Allowance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 0) return '₱${amount.toStringAsFixed(2)}';
    return '-₱${amount.abs().toStringAsFixed(2)}';
  }
}

class _SummaryLabel extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryLabel({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          _formatAmount(amount),
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 0) return '₱${amount.toStringAsFixed(2)}';
    return '-₱${amount.abs().toStringAsFixed(2)}';
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TransactionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final type = data['type'] as String? ?? 'Expense';
    final category = data['category'] as String? ?? '';
    final isIncome = type == 'Income';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(category),
        trailing: Text(
          '${isIncome ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
