import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class GroupUpdatePage extends StatefulWidget {
  final int id;
  const GroupUpdatePage({super.key, required this.id});

  @override
  State<GroupUpdatePage> createState() => _GroupUpdatePageState();
}

class _GroupUpdatePageState extends State<GroupUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  bool _loading = false;
  bool _initialLoading = true;
  int? _roomId;
  List<Map<String, dynamic>> _rooms = [];
  static String baseUrl = ApiConst.apiUrl;

  final box = GetStorage();

  final NumberFormat _numFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = box.read('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Group digits into "300 000"
  String _groupDigits(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    int len = digits.length;
    int firstGroup = len % 3 == 0 ? 3 : len % 3;
    int pos = 0;
    buffer.write(digits.substring(0, firstGroup));
    pos += firstGroup;
    while (pos < len) {
      buffer.write(' ');
      buffer.write(digits.substring(pos, pos + 3));
      pos += 3;
    }
    return buffer.toString();
  }

  Future<void> _fetchGroupData() async {
    setState(() => _initialLoading = true);
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/group-show-update/${widget.id}');
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['status'] == true && body['data'] != null) {
          final data = body['data'];

          final String name = data['name']?.toString() ?? '';
          final dynamic rawPrice = data['price'];
          final int? priceInt = rawPrice != null
              ? (rawPrice is int ? rawPrice : int.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9]'), '')))
              : null;

          final dynamic roomIdFromApi = data['room_id'];
          final int? roomIdParsed = roomIdFromApi != null ? int.tryParse(roomIdFromApi.toString()) : null;

          String? roomTextFromApi;
          if (data['room'] != null) {
            roomTextFromApi = data['room'].toString();
          } else if (roomIdParsed != null) {
            roomTextFromApi = 'Xona #$roomIdParsed';
          }

          // rooms array from response (if exists)
          List<Map<String, dynamic>> fetchedRooms = [];
          if (body['room'] is List) {
            fetchedRooms = (body['room'] as List).map<Map<String, dynamic>>((e) {
              if (e is Map) return Map<String, dynamic>.from(e);
              return {'id': e, 'name': e.toString()};
            }).toList();
          }

          if (roomIdParsed != null && fetchedRooms.indexWhere((r) {
            final id = r['id'];
            if (id is int) return id == roomIdParsed;
            return id.toString() == roomIdParsed.toString();
          }) ==
              -1) {
            fetchedRooms.insert(0, {'id': roomIdParsed, 'name': roomTextFromApi ?? 'Xona #$roomIdParsed'});
          }

          // Prepare price display: "300 000" (grouped with spaces)
          final priceDigits = priceInt != null ? priceInt.toString() : '';
          final displayPrice = priceDigits.isNotEmpty ? _groupDigits(priceDigits) : '';

          setState(() {
            _nameController.text = name;
            _priceController.text = displayPrice; // editable, grouped
            _roomId = roomIdParsed;
            _rooms = fetchedRooms;
            _roomController.text = roomTextFromApi ?? '—';
          });
        } else {
          _showSnack('Maʼlumot olinishda xatolik: ${body['message'] ?? 'No data'}');
        }
      } else {
        _showSnack('Server javobi xato: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('Tarmoq xatosi: $e');
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  /// Extract plain numeric value (e.g. from "300 000" -> 300000)
  int? _getNumericPrice() {
    final txt = _priceController.text;
    final clean = txt.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    return int.tryParse(clean);
  }

  /// Called on each change: keep only digits, group them with spaces, update controller.
  /// This implementation keeps the caret at the end for simplicity & reliability.
  void _onPriceChanged(String rawValue) {
    final digits = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    final grouped = _groupDigits(digits);
    // Put grouped text into controller and place caret at the end
    _priceController.value = TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/group-update');

      final int? numericPrice = _getNumericPrice();

      final Map<String, dynamic> payload = {
        'id': widget.id,
        'room_id': _roomId,
        'name': _nameController.text.trim(),
        'price': numericPrice ?? _priceController.text.trim(),
      };

      final res = await http.post(uri, headers: headers, body: json.encode(payload));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == true) {
          if (mounted) {
            Get.snackbar(
                'Muvaffaqiyat',
                "O'zgarishlar saqalandi",
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP
            );
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) Navigator.of(context).pop(true);
            });
          }
        } else {
          _showSnack(data['message'] ?? 'Saqlashda xatolik');
        }
      } else {
        _showSnack('Server javobi xato: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('So‘rov yuborishda xatolik: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String text, {bool isError = true}) {
    final snack = SnackBar(
      content: Text(text),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guruhni yangilash'),
      ),
      body: _initialLoading
          ? const Center(
        child: CircularProgressIndicator(
          backgroundColor: Colors.white,
          color: Colors.blue,
        ),
      )
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue, width: 1.2),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.edit, color: Colors.blue),
                      labelText: 'Guruh nomi',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Guruh nomi majburiy';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Price: editable, grouped "300 000"
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue, width: 1.2),
                  ),
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.attach_money, color: Colors.blue),
                      labelText: 'To‘lov summasi (masalan: 300 000)',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'To‘lov summasi majburiy';
                      final clean = v.replaceAll(RegExp(r'[^0-9]'), '');
                      if (clean.isEmpty) return 'To‘lov summasi raqam bo‘lishi kerak';
                      return null;
                    },
                    onChanged: _onPriceChanged,
                  ),
                ),
                const SizedBox(height: 16),

                // Room selection (unchanged)
                if (_rooms.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue, width: 1.2),
                    ),
                    child: DropdownButtonFormField<int>(
                      value: _roomId,
                      items: _rooms
                          .map((r) => DropdownMenuItem<int>(
                        value: r['id'] is int ? r['id'] : int.tryParse(r['id'].toString()),
                        child: Text(r['name']?.toString() ?? 'Xona ${r['id']}'),
                      ))
                          .toList(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.meeting_room, color: Colors.blue),
                        labelText: 'Xona',
                      ),
                      validator: (v) {
                        if (v == null) return 'Xona tanlanishi majburiy';
                        return null;
                      },
                      onChanged: (v) => setState(() => _roomId = v),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue, width: 1.2),
                    ),
                    child: TextFormField(
                      controller: _roomController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.meeting_room, color: Colors.blue),
                        labelText: 'Xona',
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(_loading ? 'Saqlanmoqda...' : 'Saqlash',
                          style: const TextStyle(fontSize: 16, color: Colors.white)),
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
