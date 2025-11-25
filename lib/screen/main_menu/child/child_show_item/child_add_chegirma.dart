import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

String baseUrl = ApiConst.apiUrl;

class ChildAddChegirma extends StatefulWidget {
  final int id;

  const ChildAddChegirma({super.key, required this.id});

  @override
  State<ChildAddChegirma> createState() => _ChildAddChegirmaState();
}

class _ChildAddChegirmaState extends State<ChildAddChegirma> {
  final String type = 'chegirma';

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  List<Map<String, dynamic>> _qarindoshlar = [];
  int? _selectedQarindoshId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchQarindoshlar();
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
      final res = await http.get(url,
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
        _showSnack('Chegirma saqlandi');
        Get.back(result: true);
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8,),
          Text("Bolaning yaqin qarindosi"),
          SizedBox(height: 4,),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
                border: Border.all(color: Colors.blue,width: 1.2)
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.0,vertical: 4.0),
            child: DropdownButtonFormField<int?>(
              value: _selectedQarindoshId,
              decoration: InputDecoration(
                labelText: 'Bolaning qarindoshi (tanlash)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: [
                DropdownMenuItem<int?>(
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
          Text("Chegirma summasi"),
          SizedBox(height: 4,),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
                border: Border.all(color: Colors.blue,width: 1.2)
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.0,vertical: 4.0),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chegirma summasi UZS',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Summa kiriting';
                final parsed = int.tryParse(v.trim());
                if (parsed == null) return 'Butun son kiriting';
                if (parsed <= 0) return 'Musbat son kiriting';
                return null;
              },
            ),
          ),
          SizedBox(height: 20,),
          Text("Chegirma haqida izoh"),
          SizedBox(height: 4,),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
              border: Border.all(color: Colors.blue,width: 1.2)
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.0,vertical: 4.0),
            child: TextFormField(
              controller: _aboutController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Chegirma haqida izoh',
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
                  borderRadius: BorderRadius.circular(8), // border radius 8
                ),
                elevation: 2, // ixtiyoriy: soyalanish
              ),
              child: _loading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
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
