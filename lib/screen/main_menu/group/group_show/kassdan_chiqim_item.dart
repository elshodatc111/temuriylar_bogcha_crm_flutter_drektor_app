import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class KassdanChiqimItem extends StatefulWidget {
  final int amount;
  const KassdanChiqimItem({super.key, required this.amount});
  @override
  State<KassdanChiqimItem> createState() => _KassdanChiqimItemState();
}

class _KassdanChiqimItemState extends State<KassdanChiqimItem> {
  final _formKey = GlobalKey<FormState>();
  String? _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  bool _submitting = false;
  String get baseUrl => ApiConst.apiUrl;
  @override
  void initState() {
    super.initState();
    _amountController.text ='';
  }
  @override
  void dispose() {
    _amountController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validatsiya
    if (!_formKey.currentState!.validate()) return;

    final int amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final String about = _aboutController.text.trim();
    final String type = _type!;
    if (amount > widget.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ruxsat etilgan miqdordan oshib\nketmoqda (maks: ${widget.amount}).',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final token = GetStorage().read('token') ?? '';
      final uri = Uri.parse('$baseUrl/kassa-chiqim');
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'type': type, 'amount': amount, 'about': about}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chiqqim muvaffaqiyatli saqlandi.')),
        );
        Navigator.of(context).pop(true);
      } else {
        String message = 'Server xatosi: Serverga bog\'lanib bo\'lmadi';
        try {
          final body = jsonDecode(res.body);
          if (body is Map && body['message'] != null) message = body['message'].toString();
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tarmoq xatosi: Internetga ulanishni teksiring.')));
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  String? _validateType(String? v) {
    if (v == null || v.isEmpty) return 'Iltimos, turini tanlang';
    return null;
  }

  String? _validateAmount(String? v) {
    if (v == null || v.trim().isEmpty) return 'Iltimos, summani kiriting';
    final parsed = int.tryParse(v.trim());
    if (parsed == null) return 'Faqat raqam kiriting';
    if (parsed <= 0) return 'Summa 0 dan katta bo\'lishi kerak';
    if (parsed > widget.amount)
      return 'Maksimal miqdordan oshib ketdi (${widget.amount})';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
                border: Border.all(color: Colors.blue,width: 1.2)
              ),
              child: DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'Chiqim turi',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                hint: const Text('Tanlanmagan'),
                items: const [
                  DropdownMenuItem(value: 'xarajat', child: Text('Xarajat')),
                  DropdownMenuItem(value: 'chiqim', child: Text('Chiqim')),
                ],
                onChanged: (v) => setState(() => _type = v),
                validator: _validateType,
              ),
            ),
            const SizedBox(height: 12),

            // Amount input
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
                  border: Border.all(color: Colors.blue,width: 1.2)
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  labelText: 'Chiqim summa (maks: ${widget.amount})',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
                validator: _validateAmount,
              ),
            ),
            const SizedBox(height: 12),

            // About
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
                  border: Border.all(color: Colors.blue,width: 1.2)
              ),
              child: TextFormField(
                controller: _aboutController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Chiqim summasi',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.blue
                ),
                child: _submitting
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Saqlash',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
