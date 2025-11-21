import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

final String baseUrl = ApiConst.apiUrl;

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _sizeCtrl = TextEditingController();

  final GetStorage _storage = GetStorage();
  String? _token;

  bool _loading = false;
  Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    final t = _storage.read('token');
    if (t != null && t is String) _token = t.trim();

    _nameCtrl.addListener(() => _clearError('name'));
    _aboutCtrl.addListener(() => _clearError('about'));
    _sizeCtrl.addListener(() => _clearError('size'));
  }

  void _clearError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() => _fieldErrors[key] = null);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) {
      Get.snackbar("Xatolik", "Token topilmadi", colorText: Colors.white, backgroundColor: Colors.red);
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$baseUrl/room-create');
      final resp = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $_token",
          "Accept": "application/json",
        },
        body: {
          "name": _nameCtrl.text.trim(),
          "about": _aboutCtrl.text.trim(),
          "size": _sizeCtrl.text.trim(),
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Navigator.of(context).pop(true);
        Future.delayed(Duration(milliseconds: 50), () {
          Get.snackbar(
              'Muvaffaqiyat',
              "Yangi xona saqlandi",
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP
          );
        });
      } else if (resp.statusCode == 422) {
        final body = json.decode(resp.body);
        _fieldErrors.clear();
        body["errors"]?.forEach((k, v) {
          _fieldErrors[k] = v[0];
        });
        setState(() {});
      } else {
        Get.snackbar("Xato", "Server xatosi: ${resp.statusCode}", backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Xato", "So'rovda muammo: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yangi xona yaratish"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.meeting_room, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue,width: 1.5),
                  color: Colors.white,
                ),
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    prefixIcon: const Icon(Icons.home_work,color: Colors.blue,),
                    labelText: "Xona nomi",
                    errorText: _fieldErrors["name"],
                  ),
                  validator: (v) => v!.trim().isEmpty ? "Xona nomi majburiy" : null,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue,width: 1.5),
                  color: Colors.white,
                ),
                child: TextFormField(
                  controller: _aboutCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    prefixIcon: const Icon(Icons.info_outline,color: Colors.blue,),
                    labelText: "Xona haqida",
                    errorText: _fieldErrors["about"],
                  ),
                  validator: (v) => v!.trim().isEmpty ? "Ma'lumot majburiy" : null,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue,width: 1.5),
                  color: Colors.white,
                ),
                child: TextFormField(
                  controller: _sizeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.square_foot,color: Colors.blue,),
                    labelText: "O‘lchami (m²)",
                    errorText: _fieldErrors["size"],
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                  ),
                  validator: (v) => v!.trim().isEmpty ? "O‘lcham majburiy" : null,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    "Saqlash",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,color: Colors.white),
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

class PositionItem {
  final int id;
  final String name;
  final String? category;

  PositionItem({required this.id, required this.name, this.category});

  factory PositionItem.fromJson(Map<String, dynamic> json) {
    return PositionItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'].toString(),
      category: json['category']?.toString(),
    );
  }
}
