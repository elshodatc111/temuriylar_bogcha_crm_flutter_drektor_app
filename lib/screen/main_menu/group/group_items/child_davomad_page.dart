// child_group_davomad_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

final String baseUrl = ApiConst.apiUrl;

class ChildGroupDavomadPage extends StatefulWidget {
  final int id;
  const ChildGroupDavomadPage({super.key, required this.id});

  @override
  State<ChildGroupDavomadPage> createState() => _ChildGroupDavomadPageState();
}

class _ChildGroupDavomadPageState extends State<ChildGroupDavomadPage> {
  final GetStorage _storage = GetStorage();

  bool _isLoading = true; // for initial fetch
  bool _isSaving = false; // for save button loading
  String _error = '';

  List<Map<String, dynamic>> _children = []; // each: {child_id, child, child_balans, start_data, ...}
  Map<int, String> _selectedStatus = {}; // child_id -> status

  // allowed statuses
  static const List<String> statuses = ['keldi', 'kechikdi', 'kelmadi', 'kasal', 'sababli'];

  @override
  void initState() {
    super.initState();
    _fetchActiveChildren();
  }

  Future<void> _fetchActiveChildren() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _children = [];
      _selectedStatus = {};
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
      final uri = Uri.parse('$baseUrl/group-active-child/${widget.id}');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        // expected body: { status: true, message: "...", data: [ {child...}, ... ] }
        final List<dynamic> data = (body['data'] is List) ? (body['data'] as List) : <dynamic>[];
        _children = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();

        // default status for each child -> 'keldi' (you can change default if needed)
        for (final c in _children) {
          final int cid = (c['child_id'] is int) ? c['child_id'] as int : int.tryParse(c['child_id']?.toString() ?? '') ?? 0;
          // default to 'keldi' or 'false' — I'll default to 'keldi'
          _selectedStatus[cid] = 'keldi';
        }

        setState(() {
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

  Future<void> _saveAttendance() async {
    if (_children.isEmpty) {
      Get.snackbar('Xato', 'Hech qanday bola topilmadi.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final token = _storage.read('token');
    if (token == null || token.toString().isEmpty) {
      Get.snackbar('Xato', 'Token topilmadi. Iltimos qayta login qiling.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // prepare payload
    final List<Map<String, dynamic>> attendance = _children.map((c) {
      final int cid = (c['child_id'] is int) ? c['child_id'] as int : int.tryParse(c['child_id']?.toString() ?? '') ?? 0;
      final String status = _selectedStatus[cid] ?? 'false';
      return {'child_id': cid, 'status': status};
    }).toList();

    final payload = {
      'group_id': widget.id,
      'attendance': attendance,
    };

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('$baseUrl/group-create-davomad');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // success - close page and maybe return true
        if (mounted) {
          setState(() => _isSaving = false);
          Get.back(result: true);
        }
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final parsed = json.decode(resp.body);
          if (parsed is Map && parsed['message'] != null) msg = parsed['message'].toString();
        } catch (_) {}
        if (mounted) {
          setState(() => _isSaving = false);
          Get.snackbar('Xato', msg, snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        Get.snackbar('Xatolik', e.toString(), snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Widget _buildStatusDropdown(int childId) {
    final current = _selectedStatus[childId] ?? 'false';
    return DropdownButton<String>(
      value: current,
      items: statuses.map((s) {
        return DropdownMenuItem<String>(
          value: s,
          child: Text(_statusLabel(s)),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() {
          _selectedStatus[childId] = val;
        });
      },
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'keldi':
        return 'Keldi';
      case 'kechikdi':
        return 'Kechikdi';
      case 'kelmadi':
        return 'Kelmadi';
      case 'kasal':
        return 'Kasal';
      case 'sababli':
        return 'Sababli';
      default:
        return 'Belgisiz';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'keldi':
        return Colors.green.shade100;
      case 'kechikdi':
        return Colors.orange.shade100;
      case 'kelmadi':
        return Colors.red.shade100;
      case 'kasal':
        return Colors.purple.shade100;
      case 'sababli':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'keldi':
        return Icons.check;
      case 'kechikdi':
        return Icons.access_time;
      case 'kelmadi':
        return Icons.close;
      case 'kasal':
        return Icons.local_hospital;
      case 'sababli':
        return Icons.info_outline;
      default:
        return Icons.remove_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Davomad olish'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveAttendance,
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, color: Colors.white),
            label: _isSaving ? const Text('Saqlanmoqda...', style: TextStyle(color: Colors.white)) : const Text('Saqlash', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchActiveChildren,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinib ko‘rish'),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _children.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final c = _children[index];
                  final int cid = (c['child_id'] is int) ? c['child_id'] as int : int.tryParse(c['child_id']?.toString() ?? '') ?? 0;
                  final String name = c['child']?.toString() ?? '-';
                  final String start = c['start_data']?.toString() ?? '-';
                  final String balStr = c['child_balans']?.toString() ?? '0';
                  final int bal = int.tryParse(balStr) ?? 0;
                  final String current = _selectedStatus[cid] ?? 'keldi';

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // index or avatar
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text('${index + 1}', style: TextStyle(color: Colors.blue)),
                        ),
                        const SizedBox(width: 12),
                        // name and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(start, style: TextStyle(color: Colors.grey.shade600)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.monetization_on_outlined, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text('$bal UZS', style: TextStyle(color: bal < 0 ? Colors.red : Colors.grey.shade600)),
                                ],
                              )
                            ],
                          ),
                        ),

                        // status display with color
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(current),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(_statusIcon(current), size: 16, color: Colors.black87),
                              const SizedBox(width: 8),
                              // Dropdown to change status
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: current,
                                  items: statuses.map((s) {
                                    return DropdownMenuItem(
                                      value: s,
                                      child: Row(
                                        children: [
                                          Icon(_statusIcon(s), size: 16, color: Colors.black54),
                                          const SizedBox(width: 6),
                                          Text(_statusLabel(s)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() {
                                      _selectedStatus[cid] = val;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // bottom Save button (redundant to AppBar save)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAttendance,
                icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(_isSaving ? 'Saqlanmoqda...' : 'Davomadni saqlash'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
