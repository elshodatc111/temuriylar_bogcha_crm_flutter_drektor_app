import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:http/http.dart' as http;

String baseUrl = ApiConst.apiUrl;

class ChildTulovQaytar extends StatefulWidget {
  final int id;

  const ChildTulovQaytar({super.key, required this.id});

  @override
  State<ChildTulovQaytar> createState() => _ChildTulovQaytarState();
}

class _ChildTulovQaytarState extends State<ChildTulovQaytar> {
  final String type = 'qaytarish';

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // kassadagi mavjud summa (naqt)
  int? _mavjud;
  bool _kassaLoading = false;

  List<Map<String, dynamic>> _qarindoshlar = [];
  int? _selectedQarindoshId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchQarindoshlar();
    _fetchKassa();
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

  Future<void> _fetchQarindoshlar() async {
    final token = await _getToken();
    if (token == null) {
      _showSnack('Token topilmadi. Iltimos tizimga kiring.');
      return;
    }

    final url = Uri.parse('$baseUrl/child-show-qarindosh/${widget.id}');
    try {
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonResp = json.decode(res.body);
        final data = jsonResp['data'] as List<dynamic>?;
        setState(() {
          _qarindoshlar = data != null
              ? data.map((e) => Map<String, dynamic>.from(e)).toList()
              : [];
          _selectedQarindoshId = null;
        });
      } else {
        _showSnack('Qarindoshlarni yuklashda xato: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('Qarindoshlarni yuklashda xato: $e');
    }
  }

  /// Kassadagi mavjud naqt summani olish
  Future<void> _fetchKassa() async {
    final token = await _getToken();
    if (token == null) {
      _showSnack('Token topilmadi. Iltimos tizimga kiring.');
      return;
    }

    setState(() {
      _kassaLoading = true;
    });

    final url = Uri.parse('$baseUrl/kassa-get');
    try {
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonResp = json.decode(res.body);
        final kassa = jsonResp['kassa'] as Map<String, dynamic>?;

        if (kassa != null) {
          final dynamic naqt = kassa['kassa_naqt'] ?? 0;
          int mavjudInt;
          if (naqt is int) {
            mavjudInt = naqt;
          } else if (naqt is double) {
            mavjudInt = naqt.toInt();
          } else {
            mavjudInt = int.tryParse(naqt.toString()) ?? 0;
          }

          setState(() {
            _mavjud = mavjudInt;
          });
        } else {
          _showSnack('Kassa ma\'lumotlari topilmadi');
        }
      } else {
        _showSnack('Kassa ma\'lumotlarini yuklashda xato: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('Kassa ma\'lumotlarini yuklashda xato: $e');
    } finally {
      if (mounted) {
        setState(() {
          _kassaLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = await _getToken();
    if (token == null) {
      _showSnack('Token topilmadi. Iltimos tizimga kiring.');
      return;
    }

    final int amount = int.parse(_amountController.text.trim());
    final String about = _aboutController.text.trim();

    final body = {
      'type': type,
      'child_id': widget.id,
      'amount': amount,
      'about': about,
      'child_relative_id': _selectedQarindoshId,
    };

    setState(() {
      _loading = true;
    });

    final url = Uri.parse('$baseUrl/child-paymart-repet-chegirma');
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack('To\'lov qaytarish saqlandi');
        Get.back(result: true); // modalni yopish va parentga true qaytarish
      } else {
        String message = 'Xato: ${res.statusCode}';
        try {
          final Map<String, dynamic> jsonResp = json.decode(res.body);
          if (jsonResp.containsKey('message')) {
            message = jsonResp['message'].toString();
          }
        } catch (_) {}
        _showSnack('Saqlashda xato: $message');
      }
    } catch (e) {
      _showSnack('Saqlashda xato: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String formatSum(int number) {
    final formatter = NumberFormat("#,###", "en_US");
    return formatter.format(number).replaceAll(",", " ");
  }

  @override
  Widget build(BuildContext context) {
    final int mavjud = _mavjud ?? 0;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              _kassaLoading
                  ? "Kassada Mavjud summa: yuklanmoqda..."
                  : "Kassada Mavjud summa: ${formatSum(mavjud)} UZS",
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text("Bolaning yaqin qarindoshi"),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              border: Border.all(color: Colors.blue, width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: DropdownButtonFormField<int?>(
              value: _selectedQarindoshId,
              decoration: const InputDecoration(
                labelText: 'Bolaning qarindoshi (tanlash)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('— Tanlanmagan —'),
                ),
                ..._qarindoshlar.map((q) {
                  final id = q['id'] as int;
                  final name = q['name'] ?? '';
                  final about = q['about'] ?? '';
                  final phone = q['phone'] ?? '';
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text('$name — $about — $phone'),
                  );
                }).toList(),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedQarindoshId = val;
                });
              },
              validator: (val) {
                if (val == null) return 'Iltimos qarindoshni tanlang';
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text("Qaytariladigan summa"),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              border: Border.all(color: Colors.blue, width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Qaytariladigan summa',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Summa kiriting';
                }
                final parsed = int.tryParse(v.trim());
                if (parsed == null) return 'Butun son kiriting';
                if (parsed <= 0) return 'Musbat son kiriting';

                // Kassadagi mavjud summadan katta bo'lsa
                if (_mavjud != null && parsed > _mavjud!) {
                  return "Kassada mablag' yetarli emas (maks: ${formatSum(_mavjud!)} UZS)";
                }

                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text("To'lovni qaytarish haqida izoh"),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              border: Border.all(color: Colors.blue, width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextFormField(
              controller: _aboutController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'To\'lovni qaytarish haqida izoh',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Izoh kiriting';
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // orqa fon
                foregroundColor: Colors.white, // matn va ikonalar rangi
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // radius 8
                ),
                elevation: 2,
              ),
              child: _loading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Saqlanmoqda...'),
                ],
              )
                  : const Text('Saqlash'),
            ),
          ),
        ],
      ),
    );
  }
}
