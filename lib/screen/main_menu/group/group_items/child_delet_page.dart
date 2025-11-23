import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class ChildDeletPage extends StatefulWidget {
  final int group_id;
  final List<dynamic> active_child;

  const ChildDeletPage({
    super.key,
    required this.active_child,
    required this.group_id,
  });

  @override
  State<ChildDeletPage> createState() => _ChildDeletPageState();
}

class _ChildDeletPageState extends State<ChildDeletPage> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedChildId;
  final TextEditingController _endAboutCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _endAboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // init GetStorage if not already (safe to call repeatedly)
    await GetStorage.init();
    final box = GetStorage();
    final token = box.read('token') as String?;

    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token topilmadi. Iltimos qayta kiring.')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    final uri = Uri.parse('${ApiConst.apiUrl}/group-end-child');

    final payload = {
      'group_id': widget.group_id,
      'child_id': _selectedChildId,
      'end_about': _endAboutCtrl.text.trim(),
    };

    try {
      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 12));

      debugPrint('GROUP-END-CHILD ${uri.toString()} => ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          Get.snackbar(
              'Muvaffaqiyat',
              "Bola guruhdan muvaffaqiyatli chiqarildi",
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP
          );
          Navigator.of(context).pop(true);
        }
      } else {
        String err = 'Server xatosi: ${response.statusCode}';
        try {
          final b = jsonDecode(response.body);
          if (b is Map && b['message'] != null) err = b['message'];
        } catch (_) {}
        if (mounted) {
          Get.snackbar(
              'Xatolik',
              err,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        Get.snackbar(
            'Xatolik',
            "So‘rov vaqti tugadi. Internet aloqasini tekshiring.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP
        );
      }
    } on SocketException catch (_) {
      if (mounted) {
        Get.snackbar(
            'Xatolik',
            "Tarmoq xatosi. Qurilma internetga ulanganini tekshiring.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP
        );
      }
    } catch (e, st) {
      debugPrint('Error posting group-end-child: $e\n$st');
      if (mounted) {
        Get.snackbar(
            'Xatolik',
            "Xatolik yuz berdi. Iltimos qayta urinib ko‘ring.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.active_child.map<DropdownMenuItem<int>>((item) {
      final id = item['child_id'] as int;
      final name = item['child']?.toString() ?? 'No name';
      final extra = item['start_data'] != null ? ' (${item['start_data']})' : '';
      return DropdownMenuItem<int>(
        value: id,
        child: Text('$name$extra'),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Guruhdan bola o'chirish"),
        centerTitle: true,
      ),
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12.0),

              /// SELECT FIELD
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<int>(
                  value: _selectedChildId,
                  items: items,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                  decoration: const InputDecoration(
                    labelText: "Aktiv bolalardan tanlang",
                    labelStyle: TextStyle(color: Colors.blue),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (v) => v == null
                      ? 'Iltimos bir bolaning ustiga bosing'
                      : null,
                  onChanged: (val) => setState(() => _selectedChildId = val),
                ),
              ),

              const SizedBox(height: 12),

              /// IZOH FIELD
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextFormField(
                  controller: _endAboutCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'End about (izoh)',
                    labelStyle: TextStyle(color: Colors.blue),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Iltimos izoh kiriting';
                    }
                    if (v.trim().length < 3) {
                      return 'Izoh kamida 3 ta belgidan iborat bo‘lsin';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : const Text(
                    "Saqlash",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
