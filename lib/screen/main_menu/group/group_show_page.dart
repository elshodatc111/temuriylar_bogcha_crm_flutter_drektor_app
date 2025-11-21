// group_show_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

final String baseUrl = ApiConst.apiUrl;

/// Optional local image you uploaded earlier — will be used as a header/banner if present.
/// (Using the uploaded file path from your session.)
const String _localHeaderImage = '/mnt/data/ca1a3230-e059-4028-953c-b5e1d52f4fa4.png';

class GroupShowPage extends StatefulWidget {
  final int id;
  final String name;
  const GroupShowPage({super.key, required this.id, required this.name});

  @override
  State<GroupShowPage> createState() => _GroupShowPageState();
}

class _GroupShowPageState extends State<GroupShowPage> {
  final GetStorage _storage = GetStorage();

  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _group;

  @override
  void initState() {
    super.initState();
    _fetchGroup();
  }

  Future<void> _fetchGroup() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final token = _storage.read('token');
    if (token == null || token.toString().isEmpty) {
      setState(() {
        _error = 'Token topilmadi. Iltimos qayta login qiling.';
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/group-show/${widget.id}');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        setState(() {
          _group = (body['group'] as Map<String, dynamic>? ) ?? {};
          _isLoading = false;
        });
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final parsed = json.decode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        setState(() {
          _error = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'So‘rov xatosi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async => _fetchGroup();

  String _formatNumber(dynamic v) {
    if (v == null) return '0';
    final s = v.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write(' ');
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join('');
  }

  Widget _headerBanner(Color primary) {
    return FutureBuilder<bool>(
      future: File(_localHeaderImage).exists(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 120);
        }
        if (snap.hasData && snap.data == true) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(File(_localHeaderImage),
                height: 120, width: double.infinity, fit: BoxFit.cover),
          );
        }
        // fallback simple banner
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withOpacity(0.12)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group, size: 36, color: primary),
                const SizedBox(width: 8),
                Text(widget.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(Color primary) {
    final g = _group ?? {};
    final price = _formatNumber(g['group_price']);
    final room = g['group_room'] ?? '-';
    final created = g['group_create'] ?? '-';
    final creator = g['group_create_user'] ?? '-';
    final activeChild = g['active_child'] ?? 0;
    final endChild = g['end_child'] ?? 0;
    final debetCount = g['group_debet_count'] ?? 0;
    final debetSum = g['group_debet'] ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primary.withOpacity(0.12),
                child: Icon(Icons.group_work, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g['group_name']?.toString() ?? widget.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primary)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.meeting_room, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(room, style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(width: 12),
                    Icon(Icons.payments, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('$price UZS', style: TextStyle(color: Colors.grey.shade700)),
                  ]),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _smallStat('Faol bolalar', activeChild.toString(), Icons.person, Colors.green),
            _smallStat('Tugatganlar', endChild.toString(), Icons.check_circle, Colors.blueGrey),
            _smallStat('Debetlar', debetCount.toString(), Icons.error_outline, Colors.orange),
            _smallStat('Debet sum', _formatNumber(debetSum).toString(), Icons.payments_outlined, Colors.red),
          ]),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('Yaratdi: $creator', style: TextStyle(color: Colors.grey.shade700)),
              const Spacer(),
              Text(created, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _smallStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: _isLoading
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              _headerBanner(primary),
              const SizedBox(height: 12),
              const SizedBox(height: 24),
              Center(child: CircularProgressIndicator(color: primary)),
              const SizedBox(height: 12),
              Center(child: Text("Ma'lumotlar yuklanmoqda...", style: TextStyle(color: Colors.grey.shade700))),
              const SizedBox(height: 300),
            ],
          )
              : _error.isNotEmpty
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              const SizedBox(height: 80),
              Center(child: Text(_error, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _fetchGroup,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Qayta yuklash'),
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                ),
              ),
              const SizedBox(height: 300),
            ],
          )
              : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _infoCard(primary),

            ],
          ),
        ),
      ),
    );
  }
}
