// moliya_chart_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class MoliyaChartPage extends StatefulWidget {
  const MoliyaChartPage({super.key});

  @override
  State<MoliyaChartPage> createState() => _MoliyaChartPageState();
}

class _MoliyaChartPageState extends State<MoliyaChartPage> {
  bool _loading = true;
  String? _error;
  List<MoliyaItem> _items = [];

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

      final url = Uri.parse('$baseUrl/chart-moliya');
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        if (json['status'] == true && json['data'] is List) {
          final list = (json['data'] as List<dynamic>);
          _items = list.map((e) => MoliyaItem.fromJson(e as Map<String, dynamic>)).toList();
          setState(() => _loading = false);
        } else {
          setState(() {
            _error = json['message']?.toString() ?? 'Maʼlumot topilmadi';
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
        title: const Text('Moliya Statistikasi'),
        actions: [IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh))],
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh), label: const Text('Qayta yuklash'))
          ]),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(children: const [SizedBox(height: 120), Center(child: Text('Maʼlumot topilmadi'))]),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue,width: 1.4)),
            child: ListTile(
              title: Center(child: Text(it.data, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              subtitle: Column(
                children: [
                  Divider(
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  _item(Icons.payments_outlined,"To'lovlar",it.tulov),
                  SizedBox(height: 8,),
                  _item(Icons.local_offer_outlined,"Chegirmalar",it.chegirmalar),
                  SizedBox(height: 8,),
                  _item(Icons.undo_outlined,"Qaytarilgan to'lov",it.qaytarilgan),
                  SizedBox(height: 8,),
                  _item(Icons.money_off_outlined,"Xarajatlar",it.xarajat),
                  SizedBox(height: 8,),
                  _item(Icons.work_outline,"To'langan ish haqi",it.ishHaqi),
                  SizedBox(height: 8,),
                  _item(Icons.volunteer_activism_outlined,"Exson",it.exson),
                  SizedBox(height: 8,),
                  _item(Icons.add_card_outlined,"Balanga qo'shimcha kirim",it.kirim),
                  SizedBox(height: 8,),
                  _item(Icons.trending_up_outlined,"Daromad",it.daromad),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _item(IconData icon, String title, int amount){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon,size: 16,color: Colors.blue,),
            SizedBox(width: 4,),
            Text("$title:")
          ],
        ),
        Text("${_formatNumber(amount)} UZS")
      ],
    );
  }

  String _formatNumber(int v) {
    if (v == 0) return '0';
    final s = v.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ',');
  }
}

class MoliyaItem {
  final String data;
  final int tulov;
  final int xarajat;
  final int chegirmalar;
  final int qaytarilgan;
  final int exson;
  final int ishHaqi;
  final int daromad;
  final int kirim;

  MoliyaItem({
    required this.data,
    required this.tulov,
    required this.xarajat,
    required this.chegirmalar,
    required this.qaytarilgan,
    required this.exson,
    required this.ishHaqi,
    required this.daromad,
    required this.kirim,
  });

  factory MoliyaItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse('${v ?? 0}') ?? 0;
    }

    return MoliyaItem(
      data: json['data'] ?? '',
      tulov: toInt(json['tulov']),
      xarajat: toInt(json['xarajat']),
      chegirmalar: toInt(json['chegirmalar']),
      qaytarilgan: toInt(json['qaytarilgan']),
      exson: toInt(json['exson']),
      ishHaqi: toInt(json['ish_haqi']),
      daromad: toInt(json['daromad']),
      kirim: toInt(json['kirim']),
    );
  }
}
