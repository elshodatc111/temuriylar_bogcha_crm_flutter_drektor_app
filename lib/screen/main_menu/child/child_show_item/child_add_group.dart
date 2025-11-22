import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

String baseUrl = ApiConst.apiUrl;

class ChildAddGroup extends StatefulWidget {
  final int id;
  const ChildAddGroup({super.key, required this.id});
  @override
  State<ChildAddGroup> createState() => _ChildAddGroupState();
}

class _ChildAddGroupState extends State<ChildAddGroup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aboutController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  List<GroupItem> _groups = [];
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() => _loading = true);
    try {
      final box = GetStorage();
      final token = box.read('token');
      if (token == null) throw Exception('Token not found in GetStorage');

      final uri = Uri.parse('$baseUrl/group-active');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(resp.body);
        if (body['status'] == true && body['data'] is List) {
          final List data = body['data'];
          _groups = data.map((e) => GroupItem.fromJson(e)).toList();
          // Eslatma: endi hech qachon avtomatik tanlanmaydi — foydalanuvchi tanlashi kerak
          _selectedGroupId = null;
        } else {
          throw Exception(body['message'] ?? 'Invalid response');
        }
      } else {
        throw Exception('Server error: ${resp.statusCode}');
      }
    } catch (e) {
      // xatolikni ko'rsatish — kerak bo'lsa SnackBar bilan
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guruhlarni yuklashda xatolik: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGroupId == null) {
      // qo'shimcha tekshiruv (validator allaqachon ko'rsatgan bo'ladi)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, guruhni tanlang')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final box = GetStorage();
      final token = box.read('token');
      if (token == null) throw Exception('Token not found');

      final uri = Uri.parse('$baseUrl/group-add-child');
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'child_id': widget.id,
          'group_id': _selectedGroupId,
          'start_about': _aboutController.text.trim(),
        }),
      );
      print("###########################################${_aboutController.text.trim()}");
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(resp.body);
        if (body['status'] == true) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        } else {
          throw Exception(body['message'] ?? 'So‘rov bajarilmadi');
        }
      } else {
        throw Exception('Server javobi: ${resp.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guruhga qo\'shishda xatolik: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guruhga qo\'shish')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_groups.isEmpty)
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Guruhlar topilmadi'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchGroups,
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta urinib ko\'rish'),
              )
            ],
          ),
        )
            : Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  border: Border.all(color: Colors.blue,width: 1.2)
                ),
                padding: EdgeInsets.symmetric(horizontal: 8.0,vertical: 4.0),
                child: DropdownButtonFormField<int>(
                  value: _selectedGroupId,
                  items: _groups
                      .map(
                        (g) => DropdownMenuItem<int>(
                      value: g.id,
                      child: Text('${g.name} (Guruh narx: ${g.price})'),
                    ),
                  )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGroupId = v),
                  decoration: const InputDecoration(
                    labelText: 'Guruhni tanlang',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  hint: const Text('Guruhni tanlang'),
                  validator: (v) {
                    if (v == null) return 'Iltimos, guruhni tanlang';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0,vertical: 4.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    border: Border.all(color: Colors.blue,width: 1.2)
                ),
                child: TextFormField(
                  controller: _aboutController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Guruhga qo\'shish haqida',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Iltimos, izoh kiriting' : null,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save,color: Colors.white,),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_submitting ? 'Saqlanmoqda...' : 'Guruhga qo\'shish', style: const TextStyle(fontSize: 16,color: Colors.white)),
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

class GroupItem {
  final int id;
  final String name;
  final String room;
  final int price;
  final bool status;
  final String user;
  final String createdAt;

  GroupItem({
    required this.id,
    required this.name,
    required this.room,
    required this.price,
    required this.status,
    required this.user,
    required this.createdAt,
  });

  factory GroupItem.fromJson(Map<String, dynamic> json) => GroupItem(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
    name: json['name']?.toString() ?? '',
    room: json['room']?.toString() ?? '',
    price: (json['price'] is int) ? json['price'] as int : int.tryParse('${json['price']}') ?? 0,
    status: json['status'] == true,
    user: json['user']?.toString() ?? '',
    createdAt: json['created_at']?.toString() ?? '',
  );
}
