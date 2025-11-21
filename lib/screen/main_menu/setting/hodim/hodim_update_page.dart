// hodim_update_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

final String baseUrl = ApiConst.apiUrl;
const String _localHeaderImage =
    '/mnt/data/dd644a3d-003b-45ef-bad9-988177064ccb.png';

class HodimUpdatePage extends StatefulWidget {
  final int id;

  const HodimUpdatePage({super.key, required this.id});

  @override
  State<HodimUpdatePage> createState() => _HodimUpdatePageState();
}

class _HodimUpdatePageState extends State<HodimUpdatePage> {
  final GetStorage _storage = GetStorage();
  String? _token;

  final _formKey = GlobalKey<FormState>();

  // CONTROLLERS
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _tkunCtrl = TextEditingController();
  final TextEditingController _salaryCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();

  final MaskTextInputFormatter _phoneMask = MaskTextInputFormatter(
    mask: '+998 ## ### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _error = '';
  List<PositionItem> _positions = [];
  int? _selectedPositionId;
  Map<String, String?> _fieldErrors = {};
  Map<String, dynamic>? _initialUser;

  @override
  void initState() {
    super.initState();

    final t = _storage.read('token');
    if (t != null && t is String) _token = t.trim();

    _nameCtrl.addListener(() => _clearFieldError('name'));
    _phoneCtrl.addListener(() => _clearFieldError('phone'));
    _addressCtrl.addListener(() => _clearFieldError('address'));
    _tkunCtrl.addListener(() => _clearFieldError('tkun'));
    _salaryCtrl.addListener(() => _clearFieldError('salary'));
    _aboutCtrl.addListener(() => _clearFieldError('about'));

    _fetchInitial();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _tkunCtrl.dispose();
    _salaryCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() => _fieldErrors[key] = null);
    }
  }

  // ======================= GET DATA ===========================
  Future<void> _fetchInitial() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _fieldErrors.clear();
    });

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = "Token topilmadi";
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/emploes-update-show/${widget.id}');
      final resp = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $_token",
          "Accept": "application/json",
        },
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);

        final user = body["user"];
        final lavozimlar = body["lavozimlar"];

        _positions = lavozimlar
            .map<PositionItem>((e) => PositionItem.fromJson(e))
            .toList();

        _initialUser = Map<String, dynamic>.from(user);

        _nameCtrl.text = user["name"] ?? "";
        _phoneCtrl.text = user["phone"] ?? "";
        _phoneMask.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: _phoneCtrl.text),
        );

        _addressCtrl.text = user["address"] ?? "";
        _tkunCtrl.text = user["tkun"] ?? "";
        _salaryCtrl.text = user["salary"].toString();
        _aboutCtrl.text = user["about"] ?? "";

        _selectedPositionId = user["position_id"];

        setState(() => _isLoading = false);
      } else {
        setState(() {
          _error = "Server xatosi: ${resp.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Xatolik: $e";
        _isLoading = false;
      });
    }
  }

  bool get _hasChanged {
    if (_initialUser == null) return false;

    if (_initialUser!["name"] != _nameCtrl.text.trim()) return true;
    if (_initialUser!["phone"] != _phoneCtrl.text.trim()) return true;
    if (_initialUser!["address"] != _addressCtrl.text.trim()) return true;
    if (_initialUser!["tkun"] != _tkunCtrl.text.trim()) return true;
    if (_initialUser!["salary"].toString() != _salaryCtrl.text.trim())
      return true;
    if (_initialUser!["about"] != _aboutCtrl.text.trim()) return true;
    if (_initialUser!["position_id"].toString() !=
        _selectedPositionId.toString())
      return true;

    return false;
  }

  // ======================== DATE PICK ========================
  Future<void> _pickDate() async {
    DateTime initial = DateTime.tryParse(_tkunCtrl.text) ?? DateTime(1995);

    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (d != null) {
      _tkunCtrl.text =
          "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
  }

  // ====================== APPLY SERVER ERRORS =====================
  void _applyServerErrors(Map<String, dynamic> body) {
    _fieldErrors.clear();
    if (body["errors"] != null) {
      body["errors"].forEach((k, v) {
        _fieldErrors[k] = v[0];
      });
    }
    setState(() {});
  }

  // ========================= SUBMIT ==============================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanged) {
      Get.snackbar("Eslatma", "O'zgarish yo'q");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('$baseUrl/emploes-update');
      final resp = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $_token",
          "Accept": "application/json",
        },
        body: {
          "id": widget.id.toString(),
          "name": _nameCtrl.text.trim(),
          "position_id": _selectedPositionId.toString(),
          "phone": _phoneCtrl.text.trim(),
          "address": _addressCtrl.text.trim(),
          "tkun": _tkunCtrl.text.trim(),
          "salary": _salaryCtrl.text.trim(),
          "about": _aboutCtrl.text.trim(),
        },
      );
      if (resp.statusCode == 200) {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
        Navigator.pop(context, true);
        Get.snackbar(
          "Muvaffaqiyat",
          "Ma'lumot yangilandi",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      if (resp.statusCode == 422) {
        _applyServerErrors(json.decode(resp.body));
      }
    } catch (e) {
      Get.snackbar("Xato", "So'rov xatosi: $e");
    }

    setState(() => _isSubmitting = false);
  }

  // ====================== UI ==============================

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hodimni ma'lumotlarini yangilash"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 4),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          labelText: "Ism Familiya",
                          errorText: _fieldErrors["name"],
                        ),
                        validator: (v) =>
                        v!.trim().isEmpty ? "Ism majburiy" : null,
                      ),
                    ),

                    const SizedBox(height: 12),
                    // LAVOZIM
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _selectedPositionId,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                            labelText: "Lavozim"),
                        items: _positions
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedPositionId = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [_phoneMask],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          labelText: "Telefon",
                          errorText: _fieldErrors["phone"],
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Telefon majburiy";
                          }
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length != 12) {
                            return "To‘liq telefon raqamini kiriting: +998 90 123 4567";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: TextFormField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          labelText: "Manzil",
                          errorText: _fieldErrors["address"],
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? "Manzil majburiy" : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // TKUN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: TextFormField(
                        controller: _tkunCtrl,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          labelText: "Tug'ilgan sana",
                          errorText: _fieldErrors["tkun"],
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? "Sana majburiy" : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // SALARY
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: TextFormField(
                        controller: _salaryCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          labelText: "Ish haqi (UZS)",
                          errorText: _fieldErrors["salary"],
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? "Ish haqi majburiy" : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ABOUT
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: TextFormField(
                        controller: _aboutCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          labelText: "Izoh",
                          errorText: _fieldErrors["about"],
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? "Izoh majburiy" : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (!_hasChanged || _isSubmitting)
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Saqlash",style: TextStyle(color: Colors.white,fontSize: 16),),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class PositionItem {
  final int id;
  final String name;
  final String? category;

  PositionItem({required this.id, required this.name, this.category});

  factory PositionItem.fromJson(Map<String, dynamic> json) {
    return PositionItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'].toString().toUpperCase(),
      category: json['category']?.toString(),
    );
  }
}
