// kunlik_tulov_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class KunlikTulovPage extends StatefulWidget {
  const KunlikTulovPage({super.key});

  @override
  State<KunlikTulovPage> createState() => _KunlikTulovPageState();
}

class _KunlikTulovPageState extends State<KunlikTulovPage> {
  bool _loading = true;
  String? _error;
  List<PaymentItem> _items = [];

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

      final url = Uri.parse('$baseUrl/chart-paymart-kun');
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        if (json['status'] == true && json['data'] is List) {
          final list = (json['data'] as List<dynamic>);
          _items = list
              .map((e) => PaymentItem.fromJson(e as Map<String, dynamic>))
              .toList();
          setState(() => _loading = false);
        } else {
          setState(() {
            _error = json['message']?.toString() ?? 'Maʼlumot yo\'q';
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
        _error = 'Xatolik: $e';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async => _fetch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kunlik to'lovlar oxirgi 30 kun"),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta yuklash'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Maʼlumot topilmadi')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final it = _items[index];
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.blue),
            ),
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Center(
                child: Text(
                  it.dateLabel(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
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
                          Icon(Icons.payments_outlined,size: 16,color: Colors.blue,),
                          SizedBox(width: 4,),
                          Text("Naqt to'lov:")
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
                          Icon(Icons.payment_outlined,size: 16,color: Colors.blue,),
                          SizedBox(width: 4,),
                          Text("Plastik to'lov:")
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
                          Icon(Icons.atm,size: 16,color: Colors.blue,),
                          SizedBox(width: 4,),
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
                          Icon(Icons.local_offer_outlined,size: 16,color: Colors.blue,),
                          SizedBox(width: 4,),
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
                          Icon(Icons.keyboard_return,size: 16,color: Colors.blue,),
                          SizedBox(width: 4,),
                          Text("Qaytarildi:")
                        ],
                      ),
                      Text("${_formatNumber(it.qaytarish)} UZS")
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(int v) {
    if (v == 0) return '0';
    // simple thousands separator
    final s = v.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ' ');
  }
}

class PaymentItem {
  final DateTime date;
  final int naqt;
  final int card;
  final int shot;
  final int chegirma;
  final int qaytarish;

  PaymentItem({
    required this.date,
    required this.naqt,
    required this.card,
    required this.shot,
    required this.chegirma,
    required this.qaytarish,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    DateTime parsed;
    try {
      parsed = DateTime.parse((json['data'] ?? '') as String);
    } catch (_) {
      parsed = DateTime.now();
    }

    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse('${v ?? 0}') ?? 0;
    }

    return PaymentItem(
      date: parsed,
      naqt: toInt(json['naqt']),
      card: toInt(json['card']),
      shot: toInt(json['shot']),
      chegirma: toInt(json['chegirma']),
      qaytarish: toInt(json['qaytarish']),
    );
  }

  String dateLabel() {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$y-$m-$d';
  }
}
