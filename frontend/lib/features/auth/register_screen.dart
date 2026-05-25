import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../child/child_home.dart';
import '../parent/parent_home.dart';
import '../teacher/teacher_home.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiClient();
  bool _isLoading = false;
  bool _usePhone = true;

  String get _roleLabel {
    switch (widget.role) {
      case 'child':
        return 'Bola';
      case 'parent':
        return 'Ota-ona';
      case 'teacher':
        return 'Pedagog';
      default:
        return 'Foydalanuvchi';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final loginValue = _loginController.text.trim();
      await _api.register(
        email: _usePhone ? null : loginValue,
        phone: _usePhone ? loginValue : null,
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: widget.role,
      );

      // Avtomatik login
      await _api.login(loginValue, _passwordController.text);
      final me = await _api.getMe();

      if (!mounted) return;

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
        default:
          homeScreen = const Scaffold(
              body: Center(child: Text("Noma'lum rol")));
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => homeScreen),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_parseError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('allaqachon')) {
      return 'Bu telefon yoki email allaqachon ro\'yxatdan o\'tgan';
    }
    if (error.contains('400')) {
      return 'Ma\'lumotlar noto\'g\'ri. Qayta tekshiring';
    }
    return 'Xato yuz berdi. Qayta urinib ko\'ring';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_roleLabel ro\'yxatdan o\'tish'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Yangi hisob yaratish',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'To\'liq ism',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Ism kamida 2 ta harf';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telefon / Email tanlash
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _usePhone = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _usePhone
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade200,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12)),
                          ),
                          child: Text(
                            'Telefon',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  _usePhone ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _usePhone = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_usePhone
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade200,
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(12)),
                          ),
                          child: Text(
                            'Email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  !_usePhone ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _loginController,
                  keyboardType: _usePhone
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText:
                        _usePhone ? 'Telefon raqam' : 'Email manzil',
                    prefixIcon: Icon(
                        _usePhone ? Icons.phone : Icons.email),
                    hintText: _usePhone ? '+998901234567' : 'example@mail.com',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return _usePhone
                          ? 'Telefon raqam kiriting'
                          : 'Email kiriting';
                    }
                    if (!_usePhone && !v.contains('@')) {
                      return 'To\'g\'ri email kiriting';
                    }
                    if (_usePhone && v.trim().length < 9) {
                      return 'To\'g\'ri telefon raqam kiriting';
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
                    helperText: 'Kamida 6 ta belgi',
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Parol kamida 6 ta belgi bo\'lishi kerak';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white),
                        )
                      : const Text("RO'YXATDAN O'TISH"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hisobim bor? Kirish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
