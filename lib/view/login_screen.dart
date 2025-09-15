import 'package:flutter/material.dart';
import 'package:pictionary_ia_ry/view/home_screen.dart';
import 'package:pictionary_ia_ry/service/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final String nickname = _nicknameController.text.trim();
    final String password = _passwordController.text.trim();

    if (nickname.isEmpty) {
      _showErrorSnackBar('Veuillez saisir un pseudo.');
      return;
    }
    if (password.isEmpty) {
      _showErrorSnackBar('Veuillez saisir un mot de passe.');
      return;
    }
    if (password.length < 6) {
      _showErrorSnackBar(
        'Le mot de passe doit contenir au moins 6 caractères.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;

      if (_isLogin) {
        success = await ApiService.login(nickname, password);
        if (success) {
          final userInfo = await ApiService.getMe();
          if (userInfo != null) {
            _navigateToHome(nickname);
          } else {
            _showErrorSnackBar(
              'Erreur lors de la récupération des informations utilisateur.',
            );
          }
        } else {
          _showErrorSnackBar('Nom d\'utilisateur ou mot de passe incorrect.');
        }
      } else {
        final result = await ApiService.createPlayer(nickname, password);
        if (result != null) {
          success = await ApiService.login(nickname, password);
          if (success) {
            await ApiService.getMe();
            _navigateToHome(nickname);
          } else {
            _showErrorSnackBar(
              'Compte créé mais erreur de connexion. Essayez de vous connecter.',
            );
          }
        } else {
          _showErrorSnackBar(
            'Erreur lors de la création du compte. Le pseudo existe peut-être déjà.',
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar(
        'Erreur de connexion au serveur. Vérifiez votre connexion.',
      );
      print('Erreur authentification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToHome(String nickname) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(nickname: nickname)),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C5F66),
      appBar: AppBar(
        title: const Text(
          'Pictionary.IA.RY',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF137C8B),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: const Color(0xFF709CA7),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isLogin ? 'Connexion' : 'Inscription',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nicknameController,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C5F66),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Pseudo',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.white70,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF2C5F66),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Mot de passe',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isLogin)
                    const Text(
                      'Minimum 6 caractères',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137C8B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Se connecter' : 'Créer un compte',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: Colors.white38),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ou',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: Colors.white38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? 'Pas encore de compte ? '
                                : 'Déjà un compte ? ',
                          ),
                          TextSpan(
                            text: _isLogin ? 'S\'inscrire' : 'Se connecter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
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
