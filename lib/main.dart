import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensures the Flutter engine is fully loaded before Firebase launches
  WidgetsFlutterBinding.ensureInitialized();

  // Fully connected to your live Centsible web app configuration dashboard!
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBiIjvXlQpmnMVhWE9eojZrXvtEhxpH_cU",
      appId: "1:205667931564:web:f306451a43bb6eb0375609",
      messagingSenderId: "205667931564",
      projectId: "centsible-d74b2",
      storageBucket: "centsible-d74b2.firebasestorage.app",
    ),
  );

  runApp(const CentsibleApp());
}

class CentsibleApp extends StatelessWidget {
  const CentsibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Centsible',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLogin = true; // Switches between Login mode and Registration mode
  bool _isLoading = false;

  // Handles Form Submission
  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && username.isEmpty)) {
      _showSnackbar('Please fill in all fields.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // --- LOGIN LOGIC ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        _showSnackbar('Welcome back to Centsible!', Colors.teal);
      } else {
        // --- REGISTRATION LOGIC ---
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        final uid = userCredential.user?.uid;
        if (uid != null) {
          // Creates a matching document in your Cloud Firestore Database
          await FirebaseFirestore.instance.collection('Users').doc(uid).set({
            'username': username,
            'email': email,
            'currency': 'USD',
            'accountCreated': FieldValue.serverTimestamp(),
          });
        }
        _showSnackbar('Account created successfully!', Colors.teal);
        setState(() => _isLogin = true);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? 'An authentication error occurred.', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.teal),
              const SizedBox(height: 12),
              Text(
                _isLogin ? 'Centsible Login' : 'Create Centsible Account',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 32),

              if (!_isLogin) ...[
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder()
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 24),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin
                    ? "Don't have an account? Register here"
                    : 'Already have an account? Sign in here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}