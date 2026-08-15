import 'package:flutter/material.dart';
import '../models/saved_password.dart';
import '../services/password_service.dart';

class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({super.key});
  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  List<SavedPassword> _passwords = [];
  final Set<int> _visible = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await PasswordService.getAll();
    if (mounted) setState(() => _passwords = list);
  }

  Future<void> _addDialog() async {
    final siteCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: siteCtrl,
              decoration: const InputDecoration(labelText: "Site"),
            ),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (saved == true && siteCtrl.text.trim().isNotEmpty) {
      await PasswordService.add(SavedPassword(
        site: siteCtrl.text.trim(),
        username: userCtrl.text.trim(),
        password: passCtrl.text,
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Password Manager"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addDialog),
        ],
      ),
      body: _passwords.isEmpty
          ? const Center(
              child: Text(
                "No saved passwords yet",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _passwords.length,
              itemBuilder: (context, index) {
                final p = _passwords[index];
                final visible = _visible.contains(p.id);
                return ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(p.site),
                  subtitle: Text(
                    "${p.username}  •  ${visible ? p.password : '•' * p.password.length}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() {
                          if (visible) {
                            _visible.remove(p.id);
                          } else {
                            _visible.add(p.id!);
                          }
                        }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await PasswordService.delete(p.id!);
                          _load();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}