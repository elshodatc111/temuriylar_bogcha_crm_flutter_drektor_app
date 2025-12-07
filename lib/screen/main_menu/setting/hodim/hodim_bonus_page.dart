import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class HodimBonusPage extends StatefulWidget {
  final int id;
  const HodimBonusPage({super.key, required this.id});

  @override
  State<HodimBonusPage> createState() => _HodimBonusPageState();
}

class _HodimBonusPageState extends State<HodimBonusPage> {
  bool _loading = true;
  String? _error;
  BonusResponse? _response;

  // O'zingizning baseUrl ni shu yerga qo'ying
  static String baseUrl = ApiConst.apiUrl; // <- o'zgartiring

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

      final url = Uri.parse('$baseUrl/chart-tarbiyachi-bonus/${widget.id}');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(res.body);
        final parsed = BonusResponse.fromJson(json);
        setState(() {
          _response = parsed;
          _loading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonus'),
        actions: [
          IconButton(
            tooltip: 'Yangilash',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          )
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinib ko\'rish'),
            )
          ],
        ),
      );
    }

    if (_response == null || _response!.data.groups.isEmpty) {
      return const Center(child: Text('Maʼlumot topilmadi'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _response!.data.groups.length,
      itemBuilder: (context, i) {
        final group = _response!.data.groups[i];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${group.charts.length} oy maʼlumotlari'),
            children: [
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: group.charts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, j) {
                  final chart = group.charts[j];
                  final foiz = chart.data.foiz.clamp(0, 100).toDouble();
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    title: Text(chart.monc),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Foiz: ${chart.data.foiz}%  ·  Ish kuni: ${chart.data.ishKuni}'),
                            Text('Bonus: ${chart.bonus} UZS'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: foiz / 100,
                          minHeight: 6,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// --- MODELLAR ---
class BonusResponse {
  final bool status;
  final String message;
  final BonusData data;

  BonusResponse({required this.status, required this.message, required this.data});

  factory BonusResponse.fromJson(Map<String, dynamic> json) {
    return BonusResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: BonusData.fromJson(json['data'] ?? {}),
    );
  }
}

class BonusData {
  final int countGroup;
  final List<BonusGroup> groups;

  BonusData({required this.countGroup, required this.groups});

  factory BonusData.fromJson(Map<String, dynamic> json) {
    final groupsJson = (json['groups'] as List<dynamic>?) ?? [];
    return BonusData(
      countGroup: json['count_group'] ?? 0,
      groups: groupsJson.map((e) => BonusGroup.fromJson(e)).toList(),
    );
  }
}

class BonusGroup {
  final String groupName;
  final List<BonusChart> charts;

  BonusGroup({required this.groupName, required this.charts});

  factory BonusGroup.fromJson(Map<String, dynamic> json) {
    final chartsJson = (json['charts'] as List<dynamic>?) ?? [];
    return BonusGroup(
      groupName: json['group_name'] ?? '',
      charts: chartsJson.map((e) => BonusChart.fromJson(e)).toList(),
    );
  }
}

class BonusChart {
  final String monc; // month string e.g. "2025-07"
  final ChartData data;
  final num bonus;

  BonusChart({required this.monc, required this.data, required this.bonus});

  factory BonusChart.fromJson(Map<String, dynamic> json) {
    return BonusChart(
      monc: json['monch'] ?? json['month'] ?? '',
      data: ChartData.fromJson(json['data'] ?? {}),
      bonus: json['bonus'] ?? 0,
    );
  }

  String monchFormatted() {
    return monc;
  }

  // Short month label for avatar (e.g. "07/25")
  String monchShort() {
    final parts = monc.split('-');
    if (parts.length >= 2) {
      return '${parts[1]}/${parts[0].substring(2)}';
    }
    return monc;
  }
}

// small helpers to avoid naming collisions with variable names in user's JSON
extension BonusChartExt on BonusChart {
  String moncHShort() => monchShort();
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
