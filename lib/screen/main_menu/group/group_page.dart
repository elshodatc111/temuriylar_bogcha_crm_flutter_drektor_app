// group_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/create_group_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_show_page.dart';

final String baseUrl = ApiConst.apiUrl;

/// Optional local header image you uploaded earlier (will be displayed at top if exists)
const String _localHeaderImage = '/mnt/data/ca1a3230-e059-4028-953c-b5e1d52f4fa4.png';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with SingleTickerProviderStateMixin {
  final GetStorage _storage = GetStorage();

  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _groups = [];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _fetchGroups();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _groups = [];
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
      final uri = Uri.parse('$baseUrl/group-active');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        final data = body['data'] as List<dynamic>? ?? [];
        setState(() {
          _groups = data.map<Map<String, dynamic>>((e) {
            if (e is Map<String, dynamic>) return e;
            return Map<String, dynamic>.from(e);
          }).toList();
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

  Future<void> _onRefresh() async => _fetchGroups();

  String _formatCurrency(dynamic v) {
    if (v == null) return '-';
    int amount = 0;
    if (v is int) amount = v;
    if (v is String) amount = int.tryParse(v) ?? 0;
    final s = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(' ');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join('') + ' UZS';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guruhlar'),
        backgroundColor: primary,
        actions: [
          IconButton(
            onPressed: () async {
              final res = await Get.to(() => const CreateGroupPage());
              if (res == true) _fetchGroups();
            },
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Yangi guruh qo\'shish',
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: _isLoading
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 18),
              FutureBuilder<bool>(
                future: File(_localHeaderImage).exists(),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 120);
                  }
                  if (snap.hasData && snap.data == true) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_localHeaderImage), height: 120, width: double.infinity, fit: BoxFit.cover),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: Get.height*0.35),
              Center(child: CircularProgressIndicator(color: primary)),
              const SizedBox(height: 12),
              Center(child: Text("Ma'lumotlar yuklanmoqda...", style: TextStyle(color: Colors.grey.shade700))),
              const SizedBox(height: 300),
            ],
          )
              : _error.isNotEmpty
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              Center(child: Text(_error, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _fetchGroups,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Qayta yuklash'),
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                ),
              ),
              const SizedBox(height: 300),
            ],
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _groups.length,
            itemBuilder: (ctx, i) {
              final g = _groups[i];
              final name = g['name']?.toString() ?? '-';
              final room = g['room']?.toString() ?? '-';
              final price = _formatCurrency(g['price']);
              final user = g['user']?.toString() ?? '-';
              final created = g['created_at']?.toString() ?? '-';
              final status = g['status'] == true || g['status'] == 1;

              return InkWell(
                onTap: (){
                  Get.to(()=>GroupShowPage(id: g['id'], name: name));
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: primary.withOpacity(0.12),
                                  child: Icon(Icons.group, color: primary),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primary)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.meeting_room, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(room, style: TextStyle(color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        status ? Icons.check_circle : Icons.cancel,
                                        size: 14,
                                        color: status ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(status ? 'Aktiv' : 'Faol emas',
                                          style: TextStyle(color: status ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(created, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Price & user row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.payments, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(user, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
