import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class KunlikDavomadPage extends StatefulWidget {
  const KunlikDavomadPage({super.key});

  @override
  State<KunlikDavomadPage> createState() => _KunlikDavomadPageState();
}

class _KunlikDavomadPageState extends State<KunlikDavomadPage> {
  bool _loading = true;
  String? _error;
  List<DavomadItem> _items = [];
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
      final token =
          box.read('token') ?? ''; // token nomini kerak bo'lsa o'zgartiring

      final url = Uri.parse('$baseUrl/chart-davomad-kunlik');
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
              .map((e) => DavomadItem.fromJson(e as Map<String, dynamic>))
              .toList();
          setState(() {
            _loading = false;
          });
        } else {
          setState(() {
            _error = json['message']?.toString() ?? 'No data';
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

  Future<void> _refresh() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kunlik davomad"),
        actions: [
          IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta urinib ko\'rish'),
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
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final it = _items[index];
          final dateLabel = it.dataFormatted(); // yyyy-mm-dd -> e.g. Dec 04
          return Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.blue),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 14,
              ),
              child: Row(
                children: [
                  // Status circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: it.davomadStatus
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: it.davomadStatus
                            ? Colors.green
                            : Colors.grey.shade300,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      it.davomadStatus
                          ? Icons.check_circle
                          : Icons.remove_circle_outline,
                      color: it.davomadStatus ? Colors.green : Colors.grey,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Main info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              it.davomadStatus
                                  ? 'Davomad olindi'
                                  : 'Davomad olinmadi',
                              style: TextStyle(
                                color: it.davomadStatus
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.group, size: 16),
                            const SizedBox(width: 6),
                            Text('Aktiv bolalar: ${it.aktivBolalar}'),
                            const SizedBox(width: 12),
                            const Icon(Icons.percent, size: 16),
                            const SizedBox(width: 6),
                            Text('Foiz: ${it.davomadFoiz}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (it.davomadFoiz / 100).clamp(0.0, 1.0),
                            minHeight: 6,
                          ),
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

/// MODELL
class DavomadItem {
  final DateTime data;
  final bool davomadStatus;
  final int aktivBolalar;
  final int davomadFoiz;

  DavomadItem({
    required this.data,
    required this.davomadStatus,
    required this.aktivBolalar,
    required this.davomadFoiz,
  });

  factory DavomadItem.fromJson(Map<String, dynamic> json) {
    String dateStr = (json['data'] ?? '') as String;
    DateTime parsed;
    try {
      parsed = DateTime.parse(dateStr);
    } catch (_) {
      parsed = DateTime.now();
    }

    return DavomadItem(
      data: parsed,
      davomadStatus:
          json['davomad_status'] == true ||
          json['davomad_status'].toString() == '1',
      aktivBolalar: (json['aktiv_bolalar'] is num)
          ? (json['aktiv_bolalar'] as num).toInt()
          : int.tryParse('${json['aktiv_bolalar']}') ?? 0,
      davomadFoiz: (json['davomad_foiz'] is num)
          ? (json['davomad_foiz'] as num).toInt()
          : int.tryParse('${json['davomad_foiz']}') ?? 0,
    );
  }

  String dataFormatted() {
    // Masalan: 2025-12-04 -> 04 Dec 2025
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = data.day.toString().padLeft(2, '0');
    final m = monthNames[data.month - 1];
    final y = data.year;
    return '$d $m $y';
  }
}
