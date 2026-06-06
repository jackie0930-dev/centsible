import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('Users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final username = data?['username'] as String? ?? 'Student';
        final allowance = (data?['allowance'] as num?)?.toDouble() ?? 0;

        return SingleChildScrollView(
          child: Column(
            children: [
              _ProfileHeader(username: username, email: user.email ?? ''),
              const SizedBox(height: 8),
              _BudgetStatsCard(uid: user.uid, allowance: allowance),
              const SizedBox(height: 16),
              _ProfileMenuCard(uid: user.uid),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Log Out', style: TextStyle(color: Colors.red, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String username;
  final String email;

  const _ProfileHeader({required this.username, required this.email});

  @override
  Widget build(BuildContext context) {
    final initials = username.isNotEmpty
        ? username[0].toUpperCase()
        : 'S';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF26A69A), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'STUDENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            username,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetStatsCard extends StatelessWidget {
  final String uid;
  final double allowance;

  const _BudgetStatsCard({required this.uid, required this.allowance});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        double totalExpenses = 0;
        double totalIncome = 0;

        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final amount = (d['amount'] as num).toDouble();
          if (d['type'] == 'Expense') {
            totalExpenses += amount;
          } else {
            totalIncome += amount;
          }
        }

        final remaining = allowance - totalExpenses;
        final savings = totalIncome - totalExpenses;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget Stats',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _StatRow(
                    icon: Icons.account_balance_wallet,
                    label: 'Allowance',
                    value: allowance > 0 ? '₱${allowance.toStringAsFixed(2)}' : 'Not set',
                    valueColor: Colors.teal,
                  ),
                  const Divider(height: 20),
                  _StatRow(
                    icon: Icons.trending_down,
                    label: 'Spent',
                    value: '₱${totalExpenses.toStringAsFixed(2)}',
                    valueColor: Colors.red,
                  ),
                  if (allowance > 0) ...[
                    const Divider(height: 20),
                    _StatRow(
                      icon: Icons.balance,
                      label: 'Remaining',
                      value: '₱${remaining.toStringAsFixed(2)}',
                      valueColor: remaining >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                  const Divider(height: 20),
                  _StatRow(
                    icon: Icons.savings,
                    label: 'Net Savings',
                    value: '₱${savings.toStringAsFixed(2)}',
                    valueColor: savings >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 15)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuCard extends StatefulWidget {
  final String uid;

  const _ProfileMenuCard({required this.uid});

  @override
  State<_ProfileMenuCard> createState() => _ProfileMenuCardState();
}

class _ProfileMenuCardState extends State<_ProfileMenuCard> {
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('Users').doc(widget.uid).set(
        {'username': name},
        SetOptions(merge: true),
      );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated!'), backgroundColor: Colors.teal),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating username.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.teal),
                  const SizedBox(width: 10),
                  const Text(
                    'Account Info',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                        if (_isEditing) {
                          _usernameController.text = '';
                        }
                      });
                    },
                    icon: Icon(_isEditing ? Icons.close : Icons.edit, size: 16),
                    label: Text(_isEditing ? 'Cancel' : 'Edit'),
                  ),
                ],
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'New username',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUsername,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
