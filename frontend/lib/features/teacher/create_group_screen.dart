import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _api = ApiClient();
  int _ageGroup = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _api.createGroup(
        name: _nameController.text.trim(),
        ageGroup: _ageGroup,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Guruh yaratildi!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
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
      appBar: AppBar(
        title: const Text("Yangi guruh"),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
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
                    labelText: "Guruh nomi",
                    hintText: "Masalan: Quyoshcha guruhi",
                    prefixIcon: Icon(Icons.group),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return "Nom kamida 2 ta harf";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _ageGroup,
                  decoration: const InputDecoration(
                    labelText: "Yosh guruhi",
                    prefixIcon: Icon(Icons.cake),
                  ),
                  items: [3, 4, 5, 6, 7]
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text('$y yosh'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _ageGroup = v ?? 5),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Tavsif (ixtiyoriy)",
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text("YARATISH"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
