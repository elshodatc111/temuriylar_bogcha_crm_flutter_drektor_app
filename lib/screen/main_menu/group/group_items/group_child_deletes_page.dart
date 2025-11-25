import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_page.dart';

class GroupChildDeletesPage extends StatefulWidget {
  final List<dynamic> list; // bu yerga "delete_child" arrayi keldi deb olinadi

  const GroupChildDeletesPage({super.key, required this.list});

  @override
  State<GroupChildDeletesPage> createState() => _GroupChildDeletesPageState();
}

class _GroupChildDeletesPageState extends State<GroupChildDeletesPage> {
  // Helper: initials from name
  String _initials(String name) {
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Helper: format date string (expects YYYY-MM-DD or similar)
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
  String formatSum(int number) {
    final formatter = NumberFormat("#,###", "en_US");
    return formatter.format(number).replaceAll(",", " ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guruhdan o'chirilganlar"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: widget.list.isEmpty
            ? _buildEmpty()
            : Container(
              margin: EdgeInsets.only(top: 8.0),
              child: ListView.separated(
                        itemCount: widget.list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
              final item = widget.list[index];
              final name = (item['child'] ?? '—').toString();
              final childId = item['child_id'];
              final balance = formatSum(item['child_balans'])?.toString() ?? '0';
              final startData = item['start_data']?.toString();
              final startUser = item['start_user']?.toString() ?? '-';
              final startAbout = item['start_about']?.toString() ?? '';
              final endData = item['end_data']?.toString();
              final endUser = item['end_user']?.toString() ?? '-';
              final endAbout = item['end_about']?.toString() ?? '';

              return InkWell(
                onTap: (){
                  Get.to(()=>ChildShowPage(id: childId, name: name));
                },
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue,width: 1.2)),
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.account_balance_wallet, size: 14, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(
                                          balance,
                                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.play_arrow, size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Qo\'shish izohi: ${_formatDate(startData)} • $startUser',
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (startAbout.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Boshlanish: $startAbout',
                                        style: TextStyle(color: Colors.grey.shade600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.stop, size: 16, color: Colors.red),
                                  Expanded(
                                    child: Text(
                                      'O\'chirish izoh: ${_formatDate(endData)} • $endUser',
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                              if (endAbout.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.note_alt_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Chiqarilish izohi: $endAbout',
                                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 18),
            const Text(
              "Hozircha bu guruhdan o'chirilgan bola yo'q",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Agar bola chiqarilgan bo'lsa u yerdan bu ro'yxatga tushadi.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
