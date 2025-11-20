import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../const/api_const.dart';

class PasswordUpdate extends StatefulWidget {
  final int id;
  final String name;
  const PasswordUpdate({super.key, required this.id, required this.name});

  @override
  State<PasswordUpdate> createState() => _PasswordUpdateState();
}

class _PasswordUpdateState extends State<PasswordUpdate>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  final box = GetStorage();
  final String baseUrl = ApiConst.apiUrl;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }
  @override
  void dispose() {
    _controller.dispose();
    _currentCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
  String? _validateCurrent(String? v) {
    if (v == null || v.trim().isEmpty) return 'Joriy parolni kiriting';
    if (v.trim().length < 8) return 'Parol kamida 8 belgidan iborat bo\'lishi kerak';
    return null;
  }
  String? _validateNew(String? v) {
    if (v == null || v.trim().isEmpty) return 'Yangi parolni kiriting';
    if (v.trim().length < 8) return 'Yangi parol kamida 8 belgidan iborat bo\'lishi kerak';
    return null;
  }
  String? _validateConfirm(String? v) {
    if (v == null || v.trim().isEmpty) return 'Parolni takrorlang';
    if (v != _passwordCtrl.text) return 'Parollar mos emas';
    return null;
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final String current = _currentCtrl.text.trim();
    final String password = _passwordCtrl.text.trim();
    final String passwordConfirmation = _confirmCtrl.text.trim();
    final String? token = box.read<String>('token');
    final Uri uri = Uri.parse('$baseUrl/change-password');
    try {
      final response = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': current,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      ).timeout(const Duration(seconds: 12));
      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        if (!mounted) return;
        Get.rawSnackbar(
          message: "Parol yangilandi.",
          backgroundColor: Colors.green,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
        );
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }else{
        setState(() => _isLoading = false);
        Get.rawSnackbar(
          message: "Joriy parol xato qaytadan urinib ko'ring.",
          backgroundColor: Colors.red,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
        );
      }
    } on TimeoutException catch (_) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      Get.rawSnackbar(
        message: "So‘rov vaqti tugadi. Internet aloqasini tekshiring",
        backgroundColor: Colors.red,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      Get.rawSnackbar(
        message: "Server bilan bog'lanib bo'lmadi.",
        backgroundColor: Colors.red,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parolni yangilash'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_reset, size: 36, color: Colors.blue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      const Text('Shaxsiy parolni yangilash', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscureCurrent,
                validator: _validateCurrent,
                decoration: InputDecoration(
                  labelText: 'Joriy parol',
                  hintText: 'Joriy parolingizni kiriting',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue,width: 0.5)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscureNew,
                validator: _validateNew,
                decoration: InputDecoration(
                  labelText: 'Yangi parol',
                  hintText: 'Yangi parolni kiriting',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.blue,width: 0.5)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                validator: _validateConfirm,
                decoration: InputDecoration(
                  labelText: 'Parolni takrorlang',
                  hintText: 'Yangi parolni qayta kiriting',
                  filled: true,
                  fillColor: Colors.grey[100],
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.blue,width: 0.5)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                      : Text('Yangilash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
