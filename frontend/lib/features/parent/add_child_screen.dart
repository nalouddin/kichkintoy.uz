import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiClient();
  DateTime? _birthDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 4, now.month, now.day),
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year - 2),
      helpText: "Bolaning tug'ilgan kuni",
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tug'ilgan sanani tanlang")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _api.addChild(
        fullName: _nameController.text.trim(),
        birthDate: DateFormat('yyyy-MM-dd').format(_birthDate!),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Bola login ma'lumotini ko'rsatish
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("✅ Bola qo'shildi!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Bolangiz uchun login ma'lumotlari:"),
              const SizedBox(height: 12),
              SelectableText(
                "Login: ${result['login']}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SelectableText(
                "Parol: ${_passwordController.text}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                "⚠️ Ushbu ma'lumotlarni saqlab qo'ying!",
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tushundim"),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xato: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bola qo'shish")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Bola ismi",
                    prefixIcon: Icon(Icons.child_care),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return "Ism kamida 2 ta harf bo'lishi kerak";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Tug'ilgan sana",
                      prefixIcon: Icon(Icons.cake),
                    ),
                    child: Text(
                      _birthDate == null
                          ? "Sanani tanlang"
                          : DateFormat('dd.MM.yyyy').format(_birthDate!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _birthDate == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Bola uchun parol",
                    helperText: "Bola ushbu parol bilan ilovaga kiradi",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 4) {
                      return "Parol kamida 4 ta belgi";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white))
                      : const Text("QO'SHISH"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
