import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class BalansInputCreate extends StatefulWidget {
  const BalansInputCreate({super.key});

  @override
  State<BalansInputCreate> createState() => _BalansInputCreateState();
}

class _BalansInputCreateState extends State<BalansInputCreate> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedType; // 'naqt', 'card', 'shot'
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  bool _isSubmitting = false;

  final box = GetStorage();
  final String baseUrl = ApiConst.apiUrl;

  Future<String?> _getToken() async {
    final token = box.read('token');
    if (token == null) return null;
    return token.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token topilmadi — iltimos tizimga kiring.')),
      );
      return;
    }

    final type = _selectedType!;
    final amount = int.parse(_amountController.text.trim());
    final about = _aboutController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('$baseUrl/moliya-kirim');

      final body = jsonEncode({
        'type': type,
        'amount': amount,
        'about': about,
      });

      final resp = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final jsonResp = jsonDecode(resp.body);
        final ok = jsonResp['status'] == true || jsonResp['success'] == true;
        final message = jsonResp['message'] ?? 'Amal bajarildi';

        if (ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Balansga kirim qilindi.")));
            Navigator.of(context).pop(true); // true -> muvaffaqiyat belgisi
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.toString())));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server xatosi: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('So‘rovda xato: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Balansga kirim'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Type select
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
                    border: Border.all(color: Colors.blue)
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'To\'lov turi',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'naqt', child: Text('Naqt')),
                      DropdownMenuItem(value: 'card', child: Text('Plastik (Card)')),
                      DropdownMenuItem(value: 'shot', child: Text('Hisob raqam (Shot)')),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v),
                    validator: (v) => v == null ? 'To\'lov turini tanlang' : null,
                  ),
                ),

                const SizedBox(height: 12),

                // Amount
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
                      border: Border.all(color: Colors.blue)
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Miqdor (int)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Miqdorni kiriting';
                      final parsed = int.tryParse(val.trim());
                      if (parsed == null) return 'Faqat butun son kiriting';
                      if (parsed <= 0) return 'Miqdor musbat bo\'lishi kerak';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // About
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
                      border: Border.all(color: Colors.blue)
                  ),
                  child: TextFormField(
                    controller: _aboutController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'To\'lov haqida (about)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),

                const Spacer(),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Saqlanmoqda...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                        : const Text('Saqlash', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
