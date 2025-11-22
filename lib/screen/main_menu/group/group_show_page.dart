import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_update_page.dart';

final String baseUrl = ApiConst.apiUrl;

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
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        setState(() {
          _group = (body['group'] as Map<String, dynamic>?) ?? {};
          _isLoading = false;
        });
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final parsed = json.decode(resp.body);
          if (parsed is Map && parsed['message'] != null)
            msg = parsed['message'].toString();
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

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            onPressed: () async {
              final res = await Get.to(() => GroupUpdatePage(id: widget.id));
              if (res == true) _fetchGroup();
            },
            icon: Icon(Icons.edit_sharp),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: primary))
              : _error.isNotEmpty
              ? Center(
                  child: ElevatedButton.icon(
                    onPressed: _fetchGroup,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Qayta yuklash'),
                    style: ElevatedButton.styleFrom(backgroundColor: primary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [_infoCard(primary)],
                ),
        ),
      ),
    );
  }

  Widget _infoCard(Color primary) {
    final g = _group ?? {};
    final name = g['group_name'] ?? '-';
    final room = g['group_room'] ?? '-';
    final price = _formatNumber(g['group_price']);
    final activeChild = g['active_child'] ?? 0;
    final endChild = g['end_child'] ?? 0;
    final debetCount = g['group_debet_count'] ?? 0;
    final debetSum = g['group_debet'] ?? 0;
    final tarbiyachilar = g['group_tarbiyachilar'] ?? 0;
    final created = g['group_create'] ?? '-';
    final creator = g['group_create_user'] ?? '-';
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue),
      ),
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Guruh: $name",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.child_care, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      "Aktiv bolalar: $activeChild",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.room_preferences_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Xona: $room",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.hide_source, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      "O'chirilgan: $endChild",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.request_quote_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Guruh narxi: $price UZS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.supervisor_account_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Tarbiyachilar: $tarbiyachilar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Qarzdorlik: $debetSum UZS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Qarzdorlar soni: $debetCount",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Menejer: $creator",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "$created",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
