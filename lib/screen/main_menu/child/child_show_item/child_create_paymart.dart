import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class ChildCreatePaymart extends StatefulWidget {
  final int id;
  const ChildCreatePaymart({super.key, required this.id});

  @override
  State<ChildCreatePaymart> createState() => _ChildCreatePaymartState();
}

class _ChildCreatePaymartState extends State<ChildCreatePaymart> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _aboutController = TextEditingController();

  bool _loading = false;
  bool _fetching = true;
  List<Map<String, dynamic>> _relatives = [];
  int? _selectedRelativeId;
  String? _selectedType;
  final String baseUrl = ApiConst.apiUrl;

  @override
  void initState() {
    super.initState();
    _loadRelatives();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final box = GetStorage();
    final token = box.read('token');
    if (token == null) return null;
    return token.toString();
  }

  Future<void> _loadRelatives() async {
    setState(() {
      _fetching = true;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() => _fetching = false);
      Get.snackbar(
        'Xato',
        'Token topilmadi. Iltimos tizimga kirganingizni tekshiring.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/child-show-qarindosh/${widget.id}');
      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = (body['data'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
            [];

        setState(() {
          _relatives = list;
        });
      } else {
        Get.snackbar(
          'Xato',
          'Qarindoshlarni olishda xatolik: ${res.statusCode}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Tarmoq xatosi: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _fetching = false;
      });
    }
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_selectedRelativeId == null) {
      Get.snackbar(
        'Diqqat',
        'To\'lov qilgan shaxsni tanlang',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (_selectedType == null) {
      Get.snackbar(
        'Diqqat',
        'To\'lov turini tanlang',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final token = await _getToken();
    if (token == null) {
      Get.snackbar(
        'Xato',
        'Token topilmadi. Iltimos qayta kirishingizni tekshiring.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    int amount;
    try {
      amount = int.parse(_amountController.text.trim());
      if (amount <= 0) throw FormatException();
    } catch (_) {
      Get.snackbar(
        'Diqqat',
        'To‘lov summasini to‘g‘ri kiriting (musbat butun son).',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final uri = Uri.parse('$baseUrl/child-create-paymart');
      final body = json.encode({
        'child_id': widget.id,
        'child_relative_id': _selectedRelativeId,
        'amount': amount,
        'type': _selectedType,
        'about': _aboutController.text.trim(),
      });

      final res = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      if (res.statusCode >= 200) {
        Navigator.of(context).pop(true);
        Get.snackbar(
          'Muvaffaqiyat',
          "Yangi to'lov saqlandi",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        String message = 'Server javobi: ${res.statusCode}';
        try {
          final rb = json.decode(res.body);
          if (rb is Map && rb['message'] != null) message = rb['message'].toString();
        } catch (_) {}
        Get.snackbar(
          'Xato',
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'So‘rov yuborishda xatolik: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yangi to'lov qo'shish"),
      ),
      backgroundColor: Colors.white,
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Bolaning to'lov qilgan qarindoshi.",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                decoration: _fieldDecoration('To‘lov qilgan shaxsni tanlang'),
                value: _selectedRelativeId,
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('— Tanlanmagan —'),
                  ),
                  // build items from _relatives
                  ..._relatives.map((r) {
                    final id = r['id'] as int;
                    final name = r['name'] ?? '';
                    final phone = r['phone'] ?? '';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text('$name  $phone'),
                    );
                  }).toList(),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedRelativeId = v;
                  });
                },
                validator: (v) {
                  if (v == null) return 'Iltimos qarindoshni tanlang';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text("To'lov turini tanlang",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                decoration: _fieldDecoration('To‘lov turi'),
                value: _selectedType,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('— Tanlanmagan —')),
                  const DropdownMenuItem<String>(value: 'naqt', child: Text('Naqt to\'lov')),
                  const DropdownMenuItem<String>(value: 'card', child: Text('Karta orqali to\'ov')),
                  const DropdownMenuItem<String>(value: 'shot', child: Text('Shot orqali to\'lov')),
                ],
                onChanged: (v) {
                  setState(() {
                    _selectedType = v;
                  });
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Iltimos to‘lov turini tanlang';
                  return null;
                },
              ),
              Text("Karta orqali to'lov va Hisob raqamga to'lov tasdiqlangandan so'ng bola balansida ko'rinadi. Tasdiqlanmagan to'lovlar kassada saqlanib boradi.",style: TextStyle(color: Colors.red),),
              const SizedBox(height: 12),

              Text("To'lov summasi",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
              const SizedBox(height: 4),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('To‘lov summasi (so\'m)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Iltimos summani kiriting';
                  final parsed = int.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) return 'To‘lov musbat butun son bo‘lishi kerak';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Text("To'lov haqida izoh.",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
              const SizedBox(height: 4),
              TextFormField(
                controller: _aboutController,
                minLines: 3,
                maxLines: 5,
                decoration: _fieldDecoration('To\'lov haqida ma\'lumot'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Iltimos ma\'lumot kiriting';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Save button (full width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    "Saqlash",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
