// group_show_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_items/child_delet_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_items/group_child_deletes_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_items/group_davomad_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_items/group_tarbiyachilar_page.dart';
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
  List<dynamic> _active = [];
  Map<String, dynamic>? davomadJoriy;
  Map<String, dynamic>? davomadOtgan;
  List<dynamic>? tarbiyachilar;
  List<dynamic>? delete_child;

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
          _active = (body['active_child'] as List<dynamic>?) ?? [];
          delete_child = (body['delete_child'] as List<dynamic>?) ?? [];
          davomadJoriy = (body['davomad'] as Map<String, dynamic>?) ?? {};
          davomadOtgan =
              (body['oldingi_davomad'] as Map<String, dynamic>?) ?? {};
          tarbiyachilar = (body['tarbiyachilar'] as List<dynamic>?) ?? [];
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
    final parsed = int.tryParse(v.toString()) ?? 0;
    return formatSum(parsed);
  }

  String formatSum(int number) {
    final formatter = NumberFormat("#,###", "en_US");
    return formatter.format(number).replaceAll(",", " ");
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
              if (res == true) await _fetchGroup();
            },
            icon: const Icon(Icons.edit_sharp),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _isLoading
                ? SizedBox(
                    height: MediaQuery.of(context).size.height - kToolbarHeight,
                    child: Center(
                      child: CircularProgressIndicator(color: primary),
                    ),
                  )
                : _error.isNotEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height - kToolbarHeight,
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _fetchGroup,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Qayta yuklash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _infoCard(primary),
                        const SizedBox(height: 8),
                        _itemButton(),
                        const SizedBox(height: 8),
                        const Text(
                          "Aktiv bolalar",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _itemActivChild(), // ichida shrinkWrap ListView
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _itemButton() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.indigo),
                  ),
                ),
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.8,
                        minChildSize: 0.8,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (_, controller) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GroupTarbiyachilarPage(tarbiyachilar: tarbiyachilar as List<dynamic>)
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                  await _fetchGroup();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.school_outlined, size: 28, color: Colors.indigo),
                    SizedBox(height: 6),
                    Text("Tarbiyachilari"),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.deepOrangeAccent),
                  ),
                ),
                onPressed: () async{
                  final List<dynamic> joriyUsers = (davomadJoriy != null && davomadJoriy!['user'] is List) ? List<dynamic>.from(davomadJoriy!['user'] as List) : <dynamic>[];
                  final List<dynamic> otganUsers = (davomadOtgan != null && davomadOtgan!['user'] is List) ? List<dynamic>.from(davomadOtgan!['user'] as List) : <dynamic>[];
                  final List<dynamic> joriyDates = (davomadJoriy != null && davomadJoriy!['data'] is List) ? List<dynamic>.from(davomadJoriy!['data'] as List) : <dynamic>[];
                  final List<dynamic> otganDates = (davomadOtgan != null && davomadOtgan!['data'] is List) ? List<dynamic>.from(davomadOtgan!['data'] as List) : <dynamic>[];
                  await showModalBottomSheet(context: context,isScrollControlled: true,backgroundColor: Colors.transparent,
                    builder: (context) {
                      return DraggableScrollableSheet(initialChildSize: 0.8,minChildSize: 0.8,maxChildSize: 0.95,expand: false,
                        builder: (_, controller) {
                          return Container(
                            decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.vertical(top: Radius.circular(18)),),
                            child: Padding(padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Center(child: Container(width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GroupDavomadPage(
                                      id: widget.id,
                                      joriyOy: {'user': joriyUsers, 'data': joriyDates},
                                      otganOy: {'user': otganUsers, 'data': otganDates},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.checklist_rtl,
                      size: 28,
                      color: Colors.deepOrangeAccent,
                    ),
                    SizedBox(height: 6),
                    Text("Guruh davomadi"),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Guruhdan o'chirilganlar
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.8,
                        minChildSize: 0.8,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (_, controller) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child: GroupChildDeletesPage(list: delete_child as List<dynamic>)
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.history_toggle_off,
                      size: 28,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 6),
                    Text("Guruhdan o‘chirilganlar"),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Guruhdan o'chirish
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return DraggableScrollableSheet(
                        initialChildSize: 0.8,
                        minChildSize: 0.8,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (_, controller) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child: ChildDeletPage(active_child: _active)
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                  await _fetchGroup();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.person_remove_outlined,
                      size: 28,
                      color: Colors.redAccent,
                    ),
                    SizedBox(height: 6),
                    Text("Guruhdan o‘chirish"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemActivChild() {
    if (_active.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(child: Text("Aktiv bolalar mavjud emas.")),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _active.length,
      itemBuilder: (ctx, index) {
        final user = _active[index];
        final bal = int.tryParse(user['child_balans']?.toString() ?? '0') ?? 0;
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.blue),
          ),
          child: ListTile(
            onTap: () {
              Get.to(
                () => ChildShowPage(id: user['child_id'], name: user['child']),
              )?.then((_) => _fetchGroup());
            },
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                "${index + 1}",
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_2_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user['child']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${formatSum(bal)} UZS",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: bal < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            subtitle: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.supervised_user_circle_outlined,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text("${user['start_user'] ?? '-'}"),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text("${user['start_data'] ?? '-'}"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
    final debetSum = _formatNumber(g['group_debet']);
    final tarbCount = g['group_tarbiyachilar'] ?? 0;
    final created = g['group_create'] ?? '-';
    final creator = g['group_create_user'] ?? '-';

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.blue),
      ),
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // first row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.home_work_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Guruh: $name",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.child_care, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      "Aktiv bolalar: $activeChild",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6.0),

            // second row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.room_preferences_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Xona: $room",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.hide_source, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      "O'chirilgan: $endChild",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6.0),

            // third row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.request_quote_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Guruh narxi: $price UZS",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.supervisor_account_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Tarbiyachilar: $tarbCount",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6.0),

            // fourth row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calculate_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Qarzdorlik: $debetSum UZS",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calculate_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Qarzdorlar soni: $debetCount",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6.0),

            // fifth row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Menejer: $creator",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$created",
                      style: const TextStyle(
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
