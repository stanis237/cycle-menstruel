import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  Future<void> _handleSubmit() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty || (!_isLogin && email.isEmpty)) {
      setState(() {
        _errorMessage = "Veuillez remplir tous les champs.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success;
    if (_isLogin) {
      success = await _authService.login(username, password);
    } else {
      success = await _authService.register(username, email, password);
    }

    if (success) {
      if (!mounted) return;
      
      // If it's a new registration, go straight to Onboarding
      if (!_isLogin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        return;
      }

      // If it's a login, check if they have cycles (completed onboarding)
      final cycles = await _apiService.getCycles();
      
      if (!mounted) return;
      
      if (cycles == null || cycles.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = _isLogin 
            ? "Identifiants incorrects. Veuillez réessayer." 
            : "Erreur lors de l'inscription. L'utilisateur existe peut-être déjà.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF3E5F5), // Light Purple
              const Color(0xFFFCE4EC), // Light Pink
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon area
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E24AA).withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      size: 50,
                      color: Color(0xFFE91E63), // Pink
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // App Name & Tagline
                  const Text(
                    "CYCLIA",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                      color: Color(0xFF4A148C), // Dark Purple
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Votre cycle, compris et harmonisé",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form Container
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLogin ? "Connexion" : "Inscription",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A148C),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          
                          // Username field
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: "Nom d'utilisatrice",
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email field (Only for signup)
                          if (!_isLogin) ...[
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Adresse e-mail",
                                prefixIcon: const Icon(Icons.mail_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Password field
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Mot de passe",
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E24AA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? "Se connecter" : "S'inscrire",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Toggle Button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLogin 
                          ? "Pas encore de compte ? S'inscrire" 
                          : "Déjà un compte ? Se connecter",
                      style: const TextStyle(
                        color: Color(0xFF4A148C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
