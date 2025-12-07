// oylik_tulov_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class OylikTulovPage extends StatefulWidget {
  const OylikTulovPage({super.key});

  @override
  State<OylikTulovPage> createState() => _OylikTulovPageState();
}

class _OylikTulovPageState extends State<OylikTulovPage> {
  bool _loading = true;
  String? _error;
  List<PaymentMonth> _items = [];

  static String baseUrl = ApiConst.apiUrl;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final box = GetStorage();
      final token = box.read('token') ?? '';

      final url = Uri.parse('$baseUrl/chart-paymart-oy');
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(res.body);

        if (json['status'] == true && json['data'] is List) {
          final list = json['data'] as List<dynamic>;
          _items = list.map((e) => PaymentMonth.fromJson(e)).toList();

          setState(() => _loading = false);
        } else {
          setState(() {
            _error = json['message'] ?? "Ma'lumot topilmadi";
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server xatosi: ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Xatolik: $e";
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async => _fetch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Oylik to'lovlar oxirgi 12 oy"),
        actions: [IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh))],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _fetch, child: const Text("Qayta urinib ko‘rish")),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text("Ma'lumot topilmadi"));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final it = _items[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue,width: 1.2)),
            child: ListTile(
              title: Center(child: Text(it.data, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              subtitle: Column(
                children: [
                  Divider(
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money_outlined,size: 16,color: Colors.blue,),
                          SizedBox(height: 4,),
                          Text("Naqt to'lovlar:")
                        ],
                      ),
                      Text("${_formatNumber(it.naqt)} UZS")
                    ],
                  ),
                  SizedBox(height: 4,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.credit_card_outlined,size: 16,color: Colors.blue),
                          SizedBox(height: 4,),
                          Text("Plastik to'lovlar:")
                        ],
                      ),
                      Text("${_formatNumber(it.card)} UZS")
                    ],
                  ),
                  SizedBox(height: 4,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flash_on_outlined,size: 16,color: Colors.blue),
                          SizedBox(height: 4,),
                          Text("Hisob raqamga to'lov:")
                        ],
                      ),
                      Text("${_formatNumber(it.shot)} UZS")
                    ],
                  ),
                  SizedBox(height: 4,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_offer_outlined,size: 16,color: Colors.blue),
                          SizedBox(height: 4,),
                          Text("Chegirma:")
                        ],
                      ),
                      Text("${_formatNumber(it.chegirma)} UZS")
                    ],
                  ),
                  SizedBox(height: 4,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.undo_outlined,size: 16,color: Colors.blue),
                          SizedBox(width: 4,),
                          Text("Qaytarildi:")
                        ],
                      ),
                      Text("${_formatNumber(it.qaytarish)} UZS")
                    ],
                  ),
                  SizedBox(height: 4,),
                ],
              ),
            )
          );
        },
      ),
    );
  }


  String _formatNumber(int v) {
    if (v == 0) return "0";
    final s = v.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => " ");
  }
}

class PaymentMonth {
  final String data;
  final int naqt;
  final int card;
  final int shot;
  final int chegirma;
  final int qaytarish;

  PaymentMonth({
    required this.data,
    required this.naqt,
    required this.card,
    required this.shot,
    required this.chegirma,
    required this.qaytarish,
  });

  factory PaymentMonth.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return PaymentMonth(
      data: json['data'] ?? '',
      naqt: toInt(json['naqt']),
      card: toInt(json['card']),
      shot: toInt(json['shot']),
      chegirma: toInt(json['chegirma']),
      qaytarish: toInt(json['qaytarish']),
    );
  }
}
