import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_create_paymart.dart';

class ChildPaymartsPage extends StatefulWidget {
  final int id;

  const ChildPaymartsPage({super.key, required this.id});

  @override
  State<ChildPaymartsPage> createState() => _ChildPaymartsPageState();
}

class _ChildPaymartsPageState extends State<ChildPaymartsPage> {
  bool _loading = false; // for list fetching
  List<Map<String, dynamic>> _paymarts = [];
  final String baseUrl = ApiConst.apiUrl;

  @override
  void initState() {
    super.initState();
    _fetchPaymarts();
  }

  Future<String?> _getToken() async {
    final box = GetStorage();
    final token = box.read('token');
    if (token == null) return null;
    return token.toString();
  }

  Future<void> _fetchPaymarts() async {
    setState(() {
      _loading = true;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      Get.snackbar(
        'Xato',
        'Token topilmadi. Iltimos tizimga kirganingizni tekshiring.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/child-all-paymart/${widget.id}');
      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = (body['data'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
            [];

        setState(() {
          _paymarts = list;
        });
      } else {
        String message = 'Server javobi: ${res.statusCode}';
        try {
          final rb = json.decode(res.body);
          if (rb is Map && rb['message'] != null) message = rb['message'].toString();
        } catch (_) {}
        Get.snackbar(
          'Xato',
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Xato',
        'Tarmoq xatosi: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
  String _formatAmount(dynamic value) {
    if (value == null) return '-';
    final s = value.toString();
    final isNegative = s.startsWith('-');
    final digits = isNegative ? s.substring(1) : s;
    final buffer = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write(' ');
    }
    final formatted = buffer.toString().split('').reversed.join();
    return isNegative ? '-$formatted' : formatted;
  }
  IconData _iconForType(String? type) {
    switch (type) {
      case 'naqt':
        return Icons.money; // cash
      case 'card':
        return Icons.credit_card;
      case 'shot':
        return Icons.qr_code_scanner;
      default:
        return Icons.payments;
    }
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final amount = _formatAmount(item['amount']).toString() ?? '-';
    final type = item['type']?.toString() ?? '-';
    final relative = item['relative']?.toString() ?? '-';
    final meneger = item['meneger']?.toString() ?? '-';
    final date = item['data']?.toString() ?? '-';
    final status = item['status'];

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: type=='qaytarish'?Colors.deepPurple:type=='chegirma'?Colors.orange:status?Colors.green:Colors.red, width: 1.2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: type=='qaytarish'?Colors.deepPurple.withOpacity(0.12):type=='chegirma'?Colors.orange.withOpacity(0.12):Colors.blue.withOpacity(0.12),
          child: Icon(
            _iconForType(type),
            color: type=='qaytarish'?Colors.deepPurple:type=='chegirma'?Colors.orange:Colors.blue,
            size: 20,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$amount UZS',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: type=='qaytarish'?Colors.deepPurple.withOpacity(0.12):type=='chegirma'?Colors.orange.withOpacity(0.12):status ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: type=='qaytarish'?Colors.deepPurple:type=='chegirma'?Colors.orange:status ? Colors.green : Colors.orange, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(
                    status ? Icons.check_circle : Icons.pending,
                    size: 14,
                    color: type=='qaytarish'?Colors.deepPurple:type=='chegirma'?Colors.orange:status ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    type,
                    style: TextStyle(
                      color: status ? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(meneger, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(date, style: const TextStyle(fontSize: 13)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(relative),
            ],
          ),
        ),
        // Optionally add trailing actions
        // trailing: IconButton(...),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                "Yangi to'lov kiritish",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                final res = await Get.to(() => ChildCreatePaymart(id: widget.id));
                if (res == true) {
                  await _fetchPaymarts();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 4.0),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _fetchPaymarts,
            child: _paymarts.isEmpty
                ? Center(child: Text('Toʻlovlar topilmadi'))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 4, top: 4),
              itemCount: _paymarts.length,
              itemBuilder: (ctx, index) {
                final item = _paymarts[index];
                return _buildItem(item);
              },
            ),
          ),
        ),
      ],
    );
  }
}
