import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

String baseUrl = ApiConst.apiUrl;
class PaymartsItem extends StatefulWidget {
  final List<dynamic> tulovlar;
  const PaymartsItem({super.key, required this.tulovlar});

  @override
  State<PaymartsItem> createState() => _PaymartsItemState();
}

class _PaymartsItemState extends State<PaymartsItem> {
  String _formatCurrency(int value) {
    final f = NumberFormat.decimalPattern('uz');
    return '${f.format(value)} UZS';
  }
  final Set<int> _loadingIds = {};
  Future<void> _confirmPayment(int id) async {
    final token = GetStorage().read('token') ?? '';
    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token topilmadi. Iltimos, tizimga kiring.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _loadingIds.add(id));

    try {
      final uri = Uri.parse('$baseUrl/kassa-success-paymart');
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'id': id}),
      );

      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: server serverba bog\'lanishda xatolik qaytadan urinib ko\'ting')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarmoq xatosi: Qaytadan urinib ko\'ring')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loadingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage().read('user');
    final String position = box['position'];

    return ListView.builder(
        itemCount: widget.tulovlar.length,
        itemBuilder: (ctx, index) {
          final pay = widget.tulovlar[index];
          final int id = (pay['id'] is int) ? pay['id'] as int : int.tryParse(pay['id'].toString()) ?? 0;
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.blue),
                borderRadius: BorderRadiusGeometry.all(Radius.circular(4.0))),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(pay['child']?.toString() ?? '')),
                  Text(pay['relative']?.toString() ?? ''),
                ],
              ),
              subtitle: Column(
                children: [
                  SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_formatCurrency((pay['amount'] is int) ? pay['amount'] as int : int.tryParse(pay['amount'].toString()) ?? 0))),
                      pay['type'] == 'card' ? Text("Karta") : Text("Hisob raqam"),
                    ],
                  ),
                  SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(pay['meneger']?.toString() ?? '')),
                      Text(pay['data']?.toString() ?? ''),
                    ],
                  ),
                ],
              ),
              trailing: _loadingIds.contains(id)
                  ? SizedBox(
                width: 36,
                height: 36,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ): position=='admin'?IconButton(onPressed: () {_confirmPayment(id);},
                icon: Icon(
                  Icons.check_box_outlined,
                  color: Colors.green,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ):position=='direktor'?IconButton(onPressed: () {_confirmPayment(id);},
                icon: Icon(
                  Icons.check_box_outlined,
                  color: Colors.green,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ):SizedBox(),
            ),
          );
        });
  }
}
