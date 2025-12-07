// tarbiyachi_reyting_table_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class TarbiyachiReytingPage extends StatefulWidget {
  const TarbiyachiReytingPage({super.key});

  @override
  State<TarbiyachiReytingPage> createState() => _TarbiyachiReytingPageState();
}

class _TarbiyachiReytingPageState extends State<TarbiyachiReytingPage> {
  bool _loading = true;
  String? _error;
  List<Tarbiyachi> _items = [];

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

      final url = Uri.parse('$baseUrl/chart-tarbiyachi');
      final res = await http.get(url, headers: {
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        if (json['status'] == true && json['data'] is List) {
          final list = (json['data'] as List<dynamic>);
          _items = list.map((e) => Tarbiyachi.fromJson(e as Map<String, dynamic>)).toList();
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
        title: const Text('Tarbiyachilar reytingi'),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, tIndex) {
          final teacher = _items[tIndex];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue,width: 1.2)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 10),
                  // For each group show group name and a table
                  ...teacher.groups.map((g) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        // horizontal scroll in case screen is narrow
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            defaultColumnWidth: const IntrinsicColumnWidth(),
                            border: TableBorder.all(color: Colors.black12, width: 1),
                            children: [
                              // Header row
                              TableRow(
                                decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                                children: [
                                  _tableCellHeader('\nOylar', textAlign: TextAlign.left),
                                  _tableCellHeader('Ish\nkunlari', textAlign: TextAlign.center),
                                  _tableCellHeader('Davomad\nolindi', textAlign: TextAlign.center),
                                  _tableCellHeader("Davomad\nko'rsatki", textAlign: TextAlign.center),
                                ],
                              ),
                              // Data rows
                              ...g.charts.map((c) {
                                final monch = c.monch;
                                final foiz = c.data.foiz;
                                final ish = c.data.ishKuni;
                                final count = c.data.countDavomad;
                                return TableRow(children: [
                                  _tableCell(monch, align: TextAlign.left),
                                  _tableCell('$ish', align: TextAlign.center),
                                  _tableCell('$count', align: TextAlign.center),
                                  _tableCell('$foiz%', align: TextAlign.center),
                                ]);
                              }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tableCellHeader(String txt, {TextAlign textAlign = TextAlign.left}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        txt,
        textAlign: textAlign,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget _tableCell(String txt, {TextAlign align = TextAlign.left}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(minWidth: 100),
      child: Text(
        txt,
        textAlign: align,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

/// Models

class Tarbiyachi {
  final int id;
  final String name;
  final String lovozim;
  final int countGroup;
  final List<Group> groups;

  Tarbiyachi({required this.id, required this.name, required this.lovozim, required this.countGroup, required this.groups});

  factory Tarbiyachi.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'];
    final List<Group> parsed = [];

    if (rawGroups is List) {
      for (var g in rawGroups) {
        if (g is List) {
          for (var gg in g) {
            if (gg is Map<String, dynamic>) parsed.add(Group.fromJson(gg));
          }
        } else if (g is Map<String, dynamic>) {
          parsed.add(Group.fromJson(g));
        }
      }
    } else if (rawGroups is Map) {
      for (var entry in rawGroups.entries) {
        final value = entry.value;
        if (value is List) {
          for (var gg in value) {
            if (gg is Map<String, dynamic>) parsed.add(Group.fromJson(gg));
          }
        }
      }
    }

    return Tarbiyachi(
      id: (json['id'] is num) ? (json['id'] as num).toInt() : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      lovozim: (json['lovozim'] ?? '').toString(),
      countGroup: (json['count_group'] is num) ? (json['count_group'] as num).toInt() : int.tryParse('${json['count_group']}') ?? 0,
      groups: parsed,
    );
  }
}

class Group {
  final String groupName;
  final List<ChartItem> charts;

  Group({required this.groupName, required this.charts});

  factory Group.fromJson(Map<String, dynamic> json) {
    final chartsRaw = (json['charts'] as List<dynamic>?) ?? [];
    final charts = chartsRaw.map((e) => ChartItem.fromJson(e as Map<String, dynamic>)).toList();
    return Group(groupName: (json['group_name'] ?? '').toString(), charts: charts);
  }
}

class ChartItem {
  final String monch;
  final ChartData data;

  ChartItem({required this.monch, required this.data});

  factory ChartItem.fromJson(Map<String, dynamic> json) {
    return ChartItem(
      monch: (json['monch'] ?? '').toString(),
      data: ChartData.fromJson((json['data'] as Map<String, dynamic>?) ?? {}),
    );
  }
}

class ChartData {
  final int foiz;
  final int ishKuni;
  final int countDavomad;

  ChartData({required this.foiz, required this.ishKuni, required this.countDavomad});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      foiz: (json['foiz'] is num) ? (json['foiz'] as num).toInt() : int.tryParse('${json['foiz']}') ?? 0,
      ishKuni: (json['ish_kuni'] is num) ? (json['ish_kuni'] as num).toInt() : int.tryParse('${json['ish_kuni']}') ?? 0,
      countDavomad: (json['countdavomad'] is num) ? (json['countdavomad'] as num).toInt() : int.tryParse('${json['countdavomad']}') ?? 0,
    );
  }
}
