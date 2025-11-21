// create_hodim_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

final String baseUrl = ApiConst.apiUrl;
// optional local preview images (if exist in your environment)
const String _preview1 = '/mnt/data/b64ad2b5-4e24-4704-908f-2876e3b5041e.png';
const String _preview2 = '/mnt/data/ec7cd8f8-899b-4992-a77d-cd8db81fd99e.png';

/// Auto-uppercase formatter
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final upper = newValue.text.toUpperCase();
    final selection = newValue.selection;
    return TextEditingValue(text: upper, selection: selection);
  }
}

class CreateHodimPage extends StatefulWidget {
  const CreateHodimPage({super.key});

  @override
  State<CreateHodimPage> createState() => _CreateHodimPageState();
}

class _CreateHodimPageState extends State<CreateHodimPage> {
  final _formKey = GlobalKey<FormState>();
  final GetStorage _storage = GetStorage();

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _tkunCtrl = TextEditingController();
  final TextEditingController _seriaCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _salaryCtrl = TextEditingController();

  // phone mask: +998 90 123 4567
  final MaskTextInputFormatter _phoneMask = MaskTextInputFormatter(
    mask: '+998 ## ### ####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // seria mask: AA1234567 (2 letters then 7 digits)
  final MaskTextInputFormatter _seriaMask = MaskTextInputFormatter(
    mask: 'AA#######',
    filter: {
      'A': RegExp(r'[A-Za-z]'),
      '#': RegExp(r'[0-9]'),
    },
    type: MaskAutoCompletionType.lazy,
  );

  String? _token;
  bool _isSubmitting = false;
  bool _isLoadingPositions = false;
  String _error = '';

  List<PositionItem> _positions = [];
  int? _selectedPositionId;

  /// Field-level server errors (key -> message)
  final Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();

    final t = _storage.read('token');
    if (t != null && t is String && t.trim().isNotEmpty) {
      _token = t.trim();
    } else {
      _token = null;
    }

    // clear server error for field when user edits it
    _nameCtrl.addListener(() => _clearFieldError('name'));
    _phoneCtrl.addListener(() => _clearFieldError('phone'));
    _addressCtrl.addListener(() => _clearFieldError('address'));
    _tkunCtrl.addListener(() => _clearFieldError('tkun'));
    _seriaCtrl.addListener(() {
      _clearFieldError('seriya');
      _clearFieldError('seria');
    });
    _aboutCtrl.addListener(() => _clearFieldError('about'));
    _salaryCtrl.addListener(() => _clearFieldError('salary'));

    _fetchPositions();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _tkunCtrl.dispose();
    _seriaCtrl.dispose();
    _aboutCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key) && _fieldErrors[key] != null && _fieldErrors[key]!.isNotEmpty) {
      setState(() => _fieldErrors[key] = null);
    }
  }

  Future<void> _fetchPositions() async {
    setState(() {
      _isLoadingPositions = true;
      _error = '';
    });

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = 'Token topilmadi. Iltimos qayta login qiling.';
        _isLoadingPositions = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/get-position');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      });

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final List<dynamic> pos = body['position'] ?? body['positions'] ?? [];
        final list = pos.map((e) {
          if (e is Map<String, dynamic>) return PositionItem.fromJson(e);
          return PositionItem.fromJson(Map<String, dynamic>.from(e));
        }).toList();

        setState(() {
          _positions = List<PositionItem>.from(list);
          if (_positions.isNotEmpty && _selectedPositionId == null) _selectedPositionId = _positions.first.id;
          _isLoadingPositions = false;
        });
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final b = json.decode(resp.body);
          if (b is Map && b.containsKey('message')) msg = b['message'].toString();
        } catch (_) {}
        setState(() {
          _error = msg;
          _isLoadingPositions = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'So‘rovda xatolik: $e';
        _isLoadingPositions = false;
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime(1990, 1, 1);
    try {
      if (_tkunCtrl.text.isNotEmpty) initial = DateTime.parse(_tkunCtrl.text);
    } catch (_) {}
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.blue.shade700,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      _tkunCtrl.text =
      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  /// Apply server validation errors (422 response) into _fieldErrors map
  void _applyServerErrors(Map<String, dynamic> body) {
    _fieldErrors.clear();
    if (body.containsKey('errors') && body['errors'] is Map<String, dynamic>) {
      final Map<String, dynamic> errors = body['errors'];
      errors.forEach((key, val) {
        if (val is List && val.isNotEmpty) {
          _fieldErrors[key] = val.map((e) => e.toString()).join(' ');
        } else {
          _fieldErrors[key] = val?.toString();
        }
      });
    } else if (body.containsKey('message')) {
      _fieldErrors['__general__'] = body['message']?.toString();
    }
    setState(() {});
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors.clear());
    if (!_formKey.currentState!.validate()) return;
    if (_token == null || _token!.isEmpty) {
      Get.snackbar('Xato', 'Token topilmadi. Iltimos qayta login qiling.',
          backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
      return;
    }
    if (_selectedPositionId == null) {
      setState(() => _fieldErrors['position_id'] = 'Lavozimni tanlang.');
      return;
    }
    setState(() => _isSubmitting = true);
    final uri = Uri.parse('$baseUrl/emploes-create');
    try {
      final phoneValue = _phoneCtrl.text.trim();
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
        body: {
          'position_id': _selectedPositionId.toString(),
          'name': _nameCtrl.text.trim(),
          'phone': phoneValue,
          'address': _addressCtrl.text.trim(),
          'tkun': _tkunCtrl.text.trim(),
          'seriya': _seriaCtrl.text.trim(),
          'about': _aboutCtrl.text.trim(),
          'salary': _salaryCtrl.text.trim(),
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        String message = 'Hodim muvaffaqiyatli yaratildi';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) message = b['message'].toString();
        } catch (_) {}
        if (mounted) {
          Navigator.of(context).pop(true);
          Future.delayed(Duration(milliseconds: 50), () {
            Get.snackbar(
                'Muvaffaqiyat',
                message,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP
            );
          });
        }
      } else if (resp.statusCode == 422) {
        try {
          final Map<String, dynamic> body = json.decode(resp.body);
          _applyServerErrors(body);
          if (_fieldErrors.containsKey('__general__')) {
            Get.snackbar('Xato', _fieldErrors['__general__']!,
                backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
          }
        } catch (e) {
          Get.snackbar('Xato', 'Ma\'lumot tekshirilayotganda xatolik: $e',
              backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
        }
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) msg = b['message'].toString();
        } catch (_) {}
        if (mounted) {
          Get.snackbar('Xato', msg,
              backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700, snackPosition: SnackPosition.TOP);
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Xato', 'So‘rov xatosi: $e', backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Client validators
  String? _requiredValidator(String? v, {String? message}) {
    if (v == null || v.trim().isEmpty) return message ?? 'Bu maydon to\'ldirilishi shart';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Telefon kiritilishi majburiy';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12) return 'To\'liq telefon formatida kiriting (+998 90 123 4567)';
    return null;
  }

  // seria validator (two letters + seven digits)
  String? _seriaValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Seriya kiritilishi majburiy';
    final pattern = RegExp(r'^[A-Z]{2}\d{7}$');
    if (!pattern.hasMatch(v.trim())) return 'Format: AA1234567 (2 harf va 7 raqam)';
    return null;
  }

  String? _salaryValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Oylik kiritilishi majburiy';
    final n = num.tryParse(v.replaceAll(',', ''));
    if (n == null) return 'To\'g\'ri son kiriting';
    if (n < 0) return 'Musbat son kiriting';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi hodim qo\'shish'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      _isLoadingPositions
                          ? LinearProgressIndicator(color: primary)
                          : _positions.isEmpty
                          ? Row(
                        children: [
                          Expanded(child: Text('Lavozimlar topilmadi', style: TextStyle(color: Colors.grey.shade600))),
                          TextButton.icon(onPressed: _fetchPositions, icon: const Icon(Icons.refresh), label: const Text('Qayta yuklash')),
                        ],
                      ): Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue,width: 1.5),
                              color: Colors.white,
                            ),
                            child: DropdownButton<int>(
                              value: _selectedPositionId,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: _positions.map((p) {
                                return DropdownMenuItem<int>(
                                  value: p.id,
                                  child: Text(p.name),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedPositionId = v;
                                  _clearFieldError('position_id');
                                });
                              },
                            ),
                          ),
                          if (_fieldErrors['position_id'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0, left: 6.0),
                              child: Text(_fieldErrors['position_id']!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                            ),
                        ],
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
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: const Icon(Icons.person, color: Colors.blue),
                            labelText: "Ism",
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                            errorText: _fieldErrors['name'],
                          ),
                          validator: (v) => _requiredValidator(v, message: 'Ism kiritilishi majburiy'),
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
                              prefixIcon: const Icon(Icons.phone,color: Colors.blue,),
                              labelText: 'Telefon',
                              labelStyle: TextStyle(color: Colors.blue.shade700),
                              errorText: _fieldErrors['phone']
                          ),
                          validator: _phoneValidator,
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
                              prefixIcon: const Icon(Icons.location_on,color: Colors.blue,),
                              labelText: 'Manzil',
                              labelStyle: TextStyle(color: Colors.blue.shade700),
                              errorText: _fieldErrors['address']
                          ),
                          validator: (v) => _requiredValidator(v, message: 'Manzil kiritilishi majburiy'),
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
                          controller: _tkunCtrl,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                            prefixIcon: const Icon(Icons.calendar_today,color: Colors.blue,),
                            labelText: 'Tug\'ilgan sana',
                            suffixIcon: IconButton(onPressed: _pickDate, icon: const Icon(Icons.date_range)),
                            errorText: _fieldErrors['tkun'],
                          ),
                          validator: (v) => _requiredValidator(v, message: 'Tug\'ilgan sana kiritilishi majburiy'),
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
                          controller: _seriaCtrl,
                          inputFormatters: [UpperCaseTextFormatter(),_seriaMask,],
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              prefixIcon: const Icon(Icons.badge,color: Colors.blue,),
                              labelText: 'Pasport seriya raqam',
                              labelStyle: TextStyle(color: Colors.blue.shade700),
                              errorText: _fieldErrors['seriya'] ?? _fieldErrors['seria']
                          ),
                          validator: _seriaValidator,
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
                          controller: _aboutCtrl,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              prefixIcon: const Icon(Icons.note,color: Colors.blue,),
                              labelText: 'Hodim haqida',
                              labelStyle: TextStyle(color: Colors.blue.shade700),
                              errorText: _fieldErrors['about']
                          ),
                          validator: (v) => _requiredValidator(v, message: 'Izoh kiritilishi majburiy'),
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
                          controller: _salaryCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              prefixIcon: const Icon(Icons.payments,color: Colors.blue,),
                              labelText: 'Oylik ish haqi',
                              labelStyle: TextStyle(color: Colors.blue.shade700),
                              errorText: _fieldErrors['salary']
                          ),
                          validator: _salaryValidator,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save,color: Colors.white,),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            child: Text(_isSubmitting ? 'Saqlanmoqda...' : 'Saqlash', style: TextStyle(fontSize: 16,color: Colors.white)),
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<bool>(
                future: File(_preview2).exists(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                  if (snap.hasData && snap.data == true) {
                    return Column(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_preview2), height: 120, fit: BoxFit.cover)),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              if (_fieldErrors.containsKey('__general__') && (_fieldErrors['__general__']?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_fieldErrors['__general__']!, style: TextStyle(color: Colors.red.shade700)),
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

  PositionItem({
    required this.id,
    required this.name,
    this.category,
  });

  factory PositionItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return PositionItem(
      id: parseInt(json['id']),
      name: (json['name']?.toString() ?? '').toUpperCase(),   // ← katta harf
      category: json['category']?.toString(),
    );
  }
}

