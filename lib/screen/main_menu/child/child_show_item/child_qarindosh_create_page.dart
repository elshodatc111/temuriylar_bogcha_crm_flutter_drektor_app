import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class ChildQarindoshCreatePage extends StatefulWidget {
  final int id;
  const ChildQarindoshCreatePage({super.key, required this.id});

  @override
  State<ChildQarindoshCreatePage> createState() => _ChildQarindoshCreatePageState();
}

class _ChildQarindoshCreatePageState extends State<ChildQarindoshCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  bool _loading = false;

  final box = GetStorage();
  static String baseUrl = ApiConst.apiUrl;

  final _phoneMask = MaskTextInputFormatter(
    mask: '## ### ####',
    filter: {'#': RegExp(r'\d')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = box.read('token') ?? '';
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (token.toString().isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final digits = _phoneMask.getUnmaskedText(); // 9 ta raqam
    if (digits.length != 9) {
      _showSnack('Telefon raqam toʻliq emas (9 ta raqam kerak)', isError: true);
      return;
    }
    final phoneToSend = '+998 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$baseUrl/child-create-qarindosh');
      final headers = await _getHeaders();
      final body = {
        'child_id': widget.id.toString(),
        'name': _nameCtrl.text.trim(),
        'phone': phoneToSend,
        'address': _addressCtrl.text.trim(),
        'about': _aboutCtrl.text.trim(),
      };
      final res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 120));
      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final js = json.decode(res.body);
          final msg = (js is Map && js['message'] != null)
              ? js['message'].toString()
              : 'Muvaffaqiyatli saqlandi';
          _showSnack(msg, isError: false);
        } catch (_) {
          _showSnack('Muvaffaqiyatli saqlandi', isError: false);
        }
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 600),() => Navigator.of(context).pop(true));
        }
      } else {
        String msg = 'Server xatosi: ${res.statusCode}';
        try {
          final js = json.decode(res.body);
          if (js is Map && js['message'] != null) msg = js['message'].toString();
        } catch (_) {}
        _showSnack(msg, isError: true);
      }
    } catch (e) {
      _showSnack('Soʻrov yuborishda xatolik: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String text, {bool isError = true}) {
    Get.snackbar(
      isError ? 'Xatolik' : 'Muvaffaqiyat',
      text,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi qarindosh qoʻshish'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  border: Border.all(color: Colors.blue,width: 1.2)
                ),
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person,color: Colors.blue,),
                    labelText: 'Ismi (F.I.O.)',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ism kiritilishi majburiy' : null,
                ),
              ),
              const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 52,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0),bottomLeft: Radius.circular(8.0)),
                      border: Border.all(color: Colors.blue,width: 1.2)
                  ),
                  alignment: Alignment.center,
                  child: const Text('+998',style: TextStyle(fontWeight: FontWeight.w600),),
                ),
              ),
              const SizedBox(width: 0),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(8.0),bottomRight: Radius.circular(8.0)),
                        border: Border.all(color: Colors.blue,width: 1.2)
                    ),
                    child: TextFormField(
                      controller: _phoneCtrl,
                      inputFormatters: [_phoneMask],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Telefon raqam',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final unmasked = _phoneMask.getUnmaskedText();
                        if (unmasked.length != 9) return 'Telefon toʻliq emas (9 raqam kerak)';
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

              // Address
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    border: Border.all(color: Colors.blue,width: 1.2)
                ),
                child: TextFormField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on,color: Colors.blue,),
                    labelText: 'Manzil',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Manzil kiritilishi majburiy' : null,
                ),
              ),
              const SizedBox(height: 12),

              // About / relation
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    border: Border.all(color: Colors.blue,width: 1.2)
                ),
                child: TextFormField(
                  controller: _aboutCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.info_outline,color: Colors.blue,),
                    labelText: 'Qarindosh haqida',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Maʼlumot kiritilishi majburiy' : null,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save,color: Colors.white,),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_loading ? 'Saqlanmoqda...' : 'Saqlash', style: const TextStyle(fontSize: 16,color: Colors.white)),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue)),
                    backgroundColor: Colors.blue
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
