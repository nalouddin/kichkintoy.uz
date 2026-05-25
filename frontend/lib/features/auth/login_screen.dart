import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../admin/admin_home.dart';
import '../child/child_home.dart';
import '../parent/parent_home.dart';
import '../teacher/teacher_home.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiClient();
  bool _isLoading = false;
  String? _errorText;

  String get _roleLabel {
    switch (widget.role) {
      case 'child': return 'Bola';
      case 'parent': return 'Ota-ona';
      case 'teacher': return 'Pedagog';
      default: return 'Foydalanuvchi';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _api.login(_loginController.text.trim(), _passwordController.text);
      final me = await _api.getMe();

      if (!mounted) return;

      // Rolga qarab tegishli ekranga o'tish
      Widget homeScreen;
      switch (me['role']) {
        case 'child':
          homeScreen = ChildHomeScreen(user: me);
          break;
        case 'parent':
          homeScreen = ParentHomeScreen(user: me);
          break;
        case 'teacher':
          homeScreen = TeacherHomeScreen(user: me);
          break;
        case 'admin':
          homeScreen = AdminHomeScreen(user: me);
          break;
        default:
          homeScreen = const Scaffold(body: Center(child: Text('Noma\'lum rol')));
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => homeScreen),
      );
    } catch (e) {
      String errorText = 'Login yoki parol xato';
      if (e is DioException) {
        if (e.response == null) {
          errorText = 'Server bilan ulanib bo\'lmadi';
        } else if (e.response?.statusCode == 403) {
          errorText = 'Akkaunt faollashtirilmagan';
        }
      }
      setState(() => _errorText = errorText);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_roleLabel kirishi'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Xush kelibsiz! 👋',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _loginController,
                  decoration: InputDecoration(
                    labelText: widget.role == 'child'
                        ? 'Login (ism)'
                        : 'Email yoki telefon',
                    hintText: widget.role == 'child'
                        ? 'Masalan: ali'
                        : null,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Login kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Parol',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 4) {
                      return 'Parol kamida 4 ta belgi';
                    }
                    return null;
                  },
                ),

                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('KIRISH'),
                ),

                const SizedBox(height: 16),
                if (widget.role == 'child')
                  const Text(
                    'Login — ota-ona tomonidan "Bola qo\'shish" orqali beriladi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                else
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(role: widget.role),
                      ),
                    ),
                    child: const Text('Hisobingiz yo\'qmi? Ro\'yxatdan o\'ting'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
