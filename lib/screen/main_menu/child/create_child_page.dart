import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../../const/api_const.dart';

final String baseUrl = ApiConst.apiUrl;
class CreateChildPage extends StatefulWidget {
  const CreateChildPage({super.key});
  @override
  State<CreateChildPage> createState() => _CreateChildPageState();
}

class _CreateChildPageState extends State<CreateChildPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _seriaController = TextEditingController();
  final _tkunController = TextEditingController(); // display string for date
  final GetStorage _storage = GetStorage();

  bool _isSubmitting = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = _storage.read('token') as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seriaController.dispose();
    _tkunController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    try {
      if (_tkunController.text.isNotEmpty) {
        initial = DateTime.parse(_tkunController.text);
      }
    } catch (_) {}
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      final formatted = "${picked.year.toString().padLeft(4,'0')}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
      _tkunController.text = formatted;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_token == null || _token!.isEmpty) {
      Get.snackbar('Xato', 'Token topilmadi, iltimos qayta login qiling.',
          backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
      return;
    }

    final name = _nameController.text.trim();
    final seria = _seriaController.text.trim();
    final tkun = _tkunController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('$baseUrl/child-create');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': name,
          'seria': seria,
          'tkun': tkun,
        },
      );

      if (response.statusCode == 200) {
        String message = 'Saqlash muvaffaqiyatli.';
        if (mounted) {
          Navigator.of(context).pop(true);
          Future.delayed(Duration(milliseconds: 50), () {
            Get.snackbar(
              "Muvaffaqiyat",
              message,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          });
        }
      } else {
        if (mounted) {
          Get.snackbar('Xato', "Guvohnoma raqami oldin ro'yhatga olingan.",backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Xato', 'Internet aloqasini teksiring.',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTopCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.person_add, size: 36, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Yangi bola qo\'shish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Ism, guvohnoma raqami va tug\'ilgan sana kiritib saqlang', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bola qo\'shish'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              _buildTopCard(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person),
                          labelText: 'Ismi',
                          hintText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Ism kiritilishi majburiy";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _seriaController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.confirmation_number),
                          labelText: 'Seria / Guvohnoma raqami',
                          hintText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Seria kiritilishi majburiy";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tkunController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calendar_today),
                          labelText: 'Tug\'ilgan sana',
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: _pickDate,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Tug'ilgan sana kiritilishi majburiy";
                          try {
                            DateTime.parse(v.trim());
                          } catch (_) {
                            return "Sana noto'g'ri formatda";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isSubmitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save,color: Colors.white,),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            child: Text(_isSubmitting ? 'Saqlanmoqda...' : 'Saqlash', style: TextStyle(fontSize: 16,color: Colors.white)),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: Colors.blue
                          ),
                          onPressed: _isSubmitting ? null : _submit,
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
    );
  }
}
