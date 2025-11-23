import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class GroupAddTarbiyachi extends StatefulWidget {
  final int group_id;
  const GroupAddTarbiyachi({super.key, required this.group_id});

  @override
  State<GroupAddTarbiyachi> createState() => _GroupAddTarbiyachiState();
}

class _GroupAddTarbiyachiState extends State<GroupAddTarbiyachi> {
  bool _isLoading = true; // data fetch loading
  bool _isSubmitting = false; // submit loading
  List<Map<String, dynamic>> _staff = [];
  int? _selectedUserId;
  final TextEditingController _aboutCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  @override
  void dispose() {
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    await GetStorage.init();
    final box = GetStorage();
    final token = box.read('token') as String?;
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token topilmadi. Iltimos qayta kiring.')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final uri = Uri.parse('${ApiConst.apiUrl}/group-hodim-new');

    try {
      final resp = await http
          .get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
          .timeout(const Duration(seconds: 12));

      debugPrint('GROUP-HODIM-NEW ${resp.statusCode}');
      debugPrint('BODY: ${resp.body}');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(resp.body);
        if (body['status'] == true && body['data'] is List) {
          final List data = body['data'];
          _staff = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
          // NOTE: Do NOT auto-select first item — keep _selectedUserId null so hint is shown
          // if (_staff.isNotEmpty) _selectedUserId = _staff.first['id'] as int?;
        } else {
          // No data or status false
          _staff = [];
        }
      } else {
        // Show server message if present
        String err = 'Server xatosi: ${resp.statusCode}';
        try {
          final b = jsonDecode(resp.body);
          if (b is Map && b['message'] != null) err = b['message'];
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('So‘rov vaqti tugadi. Internet aloqasini tekshiring.')),
        );
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarmoq xatosi. Qurilma internetga ulanganini tekshiring.')),
        );
      }
    } catch (e, st) {
      debugPrint('Fetch staff error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xatolik yuz berdi. Iltimos qayta urinib ko‘ring.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Iltimos tarbiyachini tanlang')));
      return;
    }

    setState(() => _isSubmitting = true);
    await GetStorage.init();
    final box = GetStorage();
    final token = box.read('token') as String?;
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token topilmadi. Iltimos qayta kiring.')));
        setState(() => _isSubmitting = false);
      }
      return;
    }

    final uri = Uri.parse('${ApiConst.apiUrl}/group-add-hodim');
    final payload = {
      'group_id': widget.group_id,
      'user_id': _selectedUserId,
      'about': _aboutCtrl.text.trim(),
    };

    try {
      final resp = await http
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

      debugPrint('GROUP-ADD-HODIM ${resp.statusCode}');
      debugPrint('BODY: ${resp.body}');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(resp.body);
        final bool status = body['status'] == true;
        final String? message = body['message']?.toString();
        if (status) {
          if (mounted) {
            Get.snackbar(
                'Muvaffaqiyat',
                "Guruhga tarbiyachi qo'shildi",
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP
            );
            Navigator.of(context).pop(true);
          }
        } else {
          final err = message ?? 'So‘rov bajarilmadi';
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      } else {
        String err = 'Server xatosi: ${resp.statusCode}';
        try {
          final b = jsonDecode(resp.body);
          if (b is Map && b['message'] != null) err = b['message'];
        } catch (_) {}
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    } on TimeoutException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('So‘rov vaqti tugadi.')));
    } on SocketException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarmoq xatosi.')));
    } catch (e, st) {
      debugPrint('Submit add hodim error: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xatolik yuz berdi.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guruhga tarbiyachi qo‘shish'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dropdown with HINT instead of preselected value
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<int>(
                    value: _selectedUserId, // remains null until user selects
                    hint: const Text('Tarbiyachini tanlang'),
                    isExpanded: true,
                    items: _staff
                        .map(
                          (e) => DropdownMenuItem<int>(
                        value: e['id'] as int,
                        child: Text('${e['name'] ?? '—'} (${e['position'] ?? ''})'),
                      ),
                    )
                        .toList(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    validator: (v) => v == null ? 'Iltimos tarbiyachini tanlang' : null,
                    onChanged: (v) => setState(() => _selectedUserId = v),
                  ),
                ),

                const SizedBox(height: 16),

                // About
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: TextFormField(
                    controller: _aboutCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Guruhga qo\'shish (izoh)',
                      labelStyle: TextStyle(color: Colors.blue),
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Iltimos izoh kiriting';
                      if (v.trim().length < 3) return 'Izoh kamida 3 ta belgidan iborat bo‘lsin';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : const Text(
                      'Saqlash',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
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
