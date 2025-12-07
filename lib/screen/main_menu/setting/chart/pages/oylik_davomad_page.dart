// oylik_davomad_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class OylikDavomadPage extends StatefulWidget {
  const OylikDavomadPage({super.key});

  @override
  State<OylikDavomadPage> createState() => _OylikDavomadPageState();
}

class _OylikDavomadPageState extends State<OylikDavomadPage> {
  bool _loading = true;
  String? _error;
  List<OylikItem> _items = [];

  static String baseUrl = ApiConst.apiUrl;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final box = GetStorage();
      final token = box.read('token') ?? '';

      final url = Uri.parse('$baseUrl/chart-davomad-oylik');
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
          _items = list.map((e) => OylikItem.fromJson(e as Map<String, dynamic>)).toList();
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

  Future<void> _refresh() async => _fetchData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Oylik davomad"),
        actions: [IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh))],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _fetchData, icon: const Icon(Icons.refresh), label: const Text('Qayta urinib ko\'rish'))
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.blue, width: 1.0)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  it.monthLabel(),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  '${it.davomadFoiz}%',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: it.davomadFoiz >= 50 ? Colors.black : Colors.black54),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                )
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 0),
                        const Divider(thickness: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14),
                                      const SizedBox(width: 6),
                                      Text("${it.ishKunlari} kun", overflow: TextOverflow.ellipsis, maxLines: 1),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Ish kunlari', textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 14),
                                      const SizedBox(width: 6),
                                      Text("${it.davomadOlindi} kun", overflow: TextOverflow.ellipsis, maxLines: 1),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Davomad olindi', textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.group, size: 14),
                                      const SizedBox(width: 6),
                                      Text("${it.aktivBolalar}", overflow: TextOverflow.ellipsis, maxLines: 1),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Aktiv bolalar', textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OylikItem {
  final String monch;
  final int ishKunlari;
  final int davomadOlindi;
  final int aktivBolalar;
  final int davomadFoiz;

  OylikItem({
    required this.monch,
    required this.ishKunlari,
    required this.davomadOlindi,
    required this.aktivBolalar,
    required this.davomadFoiz,
  });

  factory OylikItem.fromJson(Map<String, dynamic> json) {
    return OylikItem(
      monch: (json['monch'] ?? '') as String,
      ishKunlari: (json['ish_kunlari'] is num) ? (json['ish_kunlari'] as num).toInt() : int.tryParse('${json['ish_kunlari']}') ?? 0,
      davomadOlindi: (json['davomad_olindi'] is num) ? (json['davomad_olindi'] as num).toInt() : int.tryParse('${json['davomad_olindi']}') ?? 0,
      aktivBolalar: (json['aktiv_bolalar'] is num) ? (json['aktiv_bolalar'] as num).toInt() : int.tryParse('${json['aktiv_bolalar']}') ?? 0,
      davomadFoiz: (json['davomad_foiz'] is num) ? (json['davomad_foiz'] as num).toInt() : int.tryParse('${json['davomad_foiz']}') ?? 0,
    );
  }

  String monthLabel() {
    try {
      final parts = monch.split('-');
      if (parts.length >= 2) {
        final year = parts[0];
        final month = int.tryParse(parts[1]) ?? 1;
        const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        return '${names[month - 1]} $year';
      }
      return monch;
    } catch (_) {
      return monch;
    }
  }
}
