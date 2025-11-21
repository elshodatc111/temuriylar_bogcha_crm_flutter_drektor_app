// create_group_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

final String baseUrl = ApiConst.apiUrl;

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final GetStorage _storage = GetStorage();

  bool _isLoading = true; // initial rooms load
  bool _isSubmitting = false; // submit button loading
  String _error = '';

  List<Map<String, dynamic>> _rooms = [];
  int? _selectedRoomId;

  // controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _rooms = [];
      _selectedRoomId = null;
    });

    final token = _storage.read('token');
    if (token == null || token.toString().isEmpty) {
      setState(() {
        _error = 'Token topilmadi. Iltimos qayta login qiling.';
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/group-get-room');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        final data = body['data'] as List<dynamic>? ?? [];
        setState(() {
          _rooms = data.map<Map<String, dynamic>>((e) {
            if (e is Map<String, dynamic>) return e;
            return Map<String, dynamic>.from(e);
          }).toList();
          if (_rooms.isNotEmpty) _selectedRoomId = _rooms.first['id'] as int?;
          _isLoading = false;
        });
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final parsed = json.decode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'So‘rov xatosi: $e';
        _isLoading = false;
      });
    }
  }

  bool get _canSubmit {
    return !_isSubmitting &&
        !_isLoading &&
        _selectedRoomId != null &&
        _nameCtrl.text.trim().isNotEmpty &&
        _priceCtrl.text.trim().isNotEmpty &&
        double.tryParse(_priceCtrl.text.trim()) != null;
  }

  Future<void> _submit() async {
    // client-side validation
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    final token = _storage.read('token');
    if (token == null || token.toString().isEmpty) {
      Get.snackbar('Xato', 'Token topilmadi. Iltimos qayta login qiling.',
          backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/group-create');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'room_id': _selectedRoomId.toString(),
          'name': _nameCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        String message = 'Guruh muvaffaqiyatli yaratildi';
        try {
          final body = json.decode(resp.body);
          if (body is Map && body['message'] != null) message = body['message'].toString();
        } catch (_) {}
        if (mounted) {
          Navigator.of(context).pop(true);
          Future.delayed(Duration(milliseconds: 50), () {
            Get.snackbar(
                'Muvaffaqiyat',
                "Yangi guruh saqlandi",
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP
            );
          });
        }
      } else if (resp.statusCode == 422) {
        // validation errors
        String msg = 'Ma\'lumotni tekshiring';
        try {
          final body = json.decode(resp.body);
          if (body is Map && body['message'] != null) msg = body['message'].toString();
        } catch (_) {}
        Get.snackbar('Xato', msg, backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final parsed = json.decode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        Get.snackbar('Xato', msg, backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
      }
    } catch (e) {
      Get.snackbar('Xato', 'So‘rov xatosi: $e', backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi guruh yaratish'),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primary),
              const SizedBox(height: 12),
              const Text("Xonalar yuklanmoqda..."),
            ],
          ),
        )
            : _error.isNotEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchRooms,
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta yuklash'),
                style: ElevatedButton.styleFrom(backgroundColor: primary),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Guruh uchun xonani tanlang.'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue,width: 1.5),
                    color: Colors.white,
                  ),
                  child: DropdownButton<int>(
                    value: _selectedRoomId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _rooms.map((r) {
                      final id = r['id'];
                      final name = r['name'] ?? '';
                      final size = r['size'] ?? '';
                      return DropdownMenuItem<int>(
                        value: id as int?,
                        child: Text('$name — ${size} m2'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedRoomId = v;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Group name
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
                      prefixIcon: const Icon(Icons.note_add_outlined,color: Colors.blue,),
                      labelText: 'Guruh nomi',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Guruh nomi kiritilishi majburiy' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),

                // Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue,width: 1.5),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                      prefixIcon: const Icon(Icons.payments_outlined,color: Colors.blue,),
                      labelText: 'Narx (UZS)',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Narx kiritilishi majburiy';
                      final n = double.tryParse(v.trim());
                      if (n == null) return 'To\'g\'ri son kiriting';
                      if (n < 0) return 'Musbat qiymat kiriting';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    icon: _isSubmitting
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save,color: Colors.white,),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(_isSubmitting ? 'Saqlanmoqda...' : 'Saqlash', style: TextStyle(fontSize: 16,color: Colors.white)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
