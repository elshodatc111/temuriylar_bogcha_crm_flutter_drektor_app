import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_items/group_add_tarbiyachi.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/hodim_show_page.dart';

class GroupTarbiyachilarPage extends StatefulWidget {
  final int group_id;
  final List<dynamic> tarbiyachilar;

  const GroupTarbiyachilarPage({
    super.key,
    required this.tarbiyachilar,
    required this.group_id,
  });

  @override
  State<GroupTarbiyachilarPage> createState() => _GroupTarbiyachilarPageState();
}

class _GroupTarbiyachilarPageState extends State<GroupTarbiyachilarPage> {
  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _showRemoveDialog(Map<String, dynamic> staff) async {
    final TextEditingController _aboutCtrl = TextEditingController();
    bool isSubmitting = false;

    // showDialog returns when Navigator.pop is called inside
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
              side: BorderSide(color: Colors.blue,width: 1.2)
            ),
            title: Text('Tarbiyachini guruhdan o\'chirish.',style: TextStyle(fontSize: 16,color: Colors.black),),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    staff['user']?.toString() ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 1.2),
                    ),
                    child: TextField(
                      controller: _aboutCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Oʻchirish izohi',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                  final aboutText = _aboutCtrl.text.trim();
                  if (aboutText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Iltimos o\'chirish izohini kiriting')),
                    );
                    return;
                  }

                  setState(() => isSubmitting = true);

                  // get token
                  await GetStorage.init();
                  final box = GetStorage();
                  final token = box.read('token') as String?;
                  if (token == null || token.isEmpty) {
                    setState(() => isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token topilmadi. Iltimos qayta kiring.')),
                    );
                    Navigator.of(dialogContext).pop();
                    return;
                  }

                  final uri = Uri.parse('${ApiConst.apiUrl}/group-end-hodim');
                  final payload = {
                    'group_id': widget.group_id,
                    'user_id': staff['user_id'] ?? staff['id'],
                    'end_about': aboutText,
                  };

                  try {
                    final resp = await http
                        .post(
                      uri,
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode(payload),
                    )
                        .timeout(const Duration(seconds: 12));

                    if (resp.statusCode == 200) {
                      // try parse response message
                      String? message;
                      try {
                        final b = jsonDecode(resp.body);
                        if (b is Map && b['message'] != null) message = b['message'].toString();
                      } catch (_) {}
                      // close dialog
                      Navigator.of(dialogContext).pop();
                      // notify parent (close sheet and refresh)
                      Get.back(result: true);
                      // show success snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message ?? 'Tarbiyachi guruhdan muvaffaqiyatli o\'chirildi')),
                      );
                    } else {
                      String err = 'Server xatosi: ${resp.statusCode}';
                      try {
                        final b = jsonDecode(resp.body);
                        if (b is Map && b['message'] != null) err = b['message'];
                      } catch (_) {}
                      setState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  } on TimeoutException {
                    setState(() => isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("So‘rov vaqti tugadi. Internet aloqasini tekshiring.")),
                    );
                  } on SocketException {
                    setState(() => isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Tarmoq xatosi. Internetni tekshiring.")),
                    );
                  } catch (e, st) {
                    setState(() => isSubmitting = false);
                    debugPrint('Error group-end-hodim: $e\n$st');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Xatolik yuz berdi. Iltimos qayta urinib ko‘ring.")),
                    );
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('O\'chirish',style: TextStyle(color: Colors.white),),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.tarbiyachilar;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guruh tarbiyachilar"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final res = await Get.to(
                    () => GroupAddTarbiyachi(group_id: widget.group_id),
              );
              if (res == true) Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? _buildEmpty()
            : ListView.separated(
          padding: const EdgeInsets.only(top: 12.0),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, index) {
            final e = items[index] as Map<String, dynamic>;
            final id = e['user_id'];
            final name = e['user']?.toString() ?? '—';
            final position = e['lovozim']?.toString() ?? '';
            final startData = e['start_data']?.toString();
            final about = e['start_about']?.toString() ?? '';

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.blue)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                child: ListTile(
                  onTap: () {
                    Get.to(()=>HodimShowPage(id: id));
                  },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (position.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            position,
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Guruhga qo\'shildi: ${_formatDate(startData)}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.note, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              about,
                              style: TextStyle(color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => _showRemoveDialog(e),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 18),
            const Text(
              "Hozircha tarbiyachi mavjud emas",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Guruhga tarbiyachi qo'shish uchun + tugmasini bosing.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
