import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_add_group.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_davomad_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_document_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_paymarts_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_qarindoshlar_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_show_page.dart';

final String baseUrl = ApiConst.apiUrl;

class ChildShowPage extends StatefulWidget {
  final int id;
  final String name;

  const ChildShowPage({super.key, required this.id, required this.name});

  @override
  State<ChildShowPage> createState() => _ChildShowPageState();
}

class _ChildShowPageState extends State<ChildShowPage> {
  final GetStorage _storage = GetStorage();
  String? _token;
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _child;
  List<GroupInfo> _group = [];

  @override
  void initState() {
    super.initState();
    _token = _storage.read('token') as String?;
    _fetchChild();
  }

  Future<void> _fetchChild() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = 'Token topilmadi. Iltimos qayta login qiling.';
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/child-show/${widget.id}');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final about = body['about'] as Map<String, dynamic>?;
        final group = body['group'] as List<dynamic>?;

        if (about == null) {
          setState(() {
            _error = 'Ma\'lumot topilmadi';
            _isLoading = false;
            _child = null;
            _group = [];
          });
          return;
        }

        // parse group list into typed objects
        _group = [];
        if (group != null) {
          _group = group.map((e) {
            if (e is Map<String, dynamic>) {
              return GroupInfo.fromJson(e);
            } else {
              return GroupInfo.empty();
            }
          }).toList();
        }

        setState(() {
          _child = about;
          _isLoading = false;
        });
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) msg = b['message'].toString();
        } catch (_) {}
        setState(() {
          _error = msg;
          _isLoading = false;
          _child = null;
          _group = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'So‘rovda xatolik: $e';
        _isLoading = false;
        _child = null;
        _group = [];
      });
    }
  }

  void _openModal(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String type,
  ) {
    final size = MediaQuery.of(context).size;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: size.width,
              height: size.height *0.92,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(width: 12),
                          Text(title, style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: type == "hujjat"
                        ? ChildDocumentPage(id: widget.id)
                        : type == "qarindosh"
                        ? ChildQarindoshlarPage(id: widget.id)
                        : type == "paymart"
                        ? ChildPaymartsPage(id: widget.id)
                        : ChildDavomadPage(id: widget.id),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text("Bola haqida")),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                  color: Colors.blue,
                ),
              )
            : _error.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _fetchChild,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Qayta yuklash'),
                      ),
                    ],
                  ),
                ),
              )
            : _child == null
            ? const Center(child: Text('Ma\'lumot topilmadi'))
            : RefreshIndicator(
                onRefresh: _fetchChild,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      _buildInfoDetailsCard(theme),
                      _itemButton(),
                      const SizedBox(height: 12),
                      const Text(
                        "Bola Guruhlari",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _buildGroupHistory(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
  Widget _itemButton(){
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.folder),
                label: const Text("Bola hujjatlari"),
                onPressed: () => _openModal(
                  context,
                  "Bola hujjatlari",
                  Icons.folder,
                  Colors.blue,
                  'hujjat',
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.people),
                label: const Text("Yaqin qarindoshlar"),
                onPressed: () => _openModal(
                  context,
                  "Yaqin qarindoshlar",
                  Icons.people,
                  Colors.green,
                  'qarindosh',
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.payment),
                label: const Text("To'lovlar"),
                onPressed: () => _openModal(
                  context,
                  "To'lovlar",
                  Icons.payment,
                  Colors.orange,
                  'paymart',
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.schedule),
                label: const Text("Davomad tarixi"),
                onPressed: () => _openModal(
                  context,
                  "Davomad tarixi",
                  Icons.schedule,
                  Colors.purple,
                  'davomad',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildGroupHistory() {
    if (_group.isEmpty) {
      return const Expanded(child: Text('Bola guruhlar tarixi mavjud emas.'));
    }
    return Expanded(
      child: ListView.separated(
        itemCount: _group.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, index) {
          final g = _group[index];
          return InkWell(
            onTap: () {
              Get.to(() => GroupShowPage(id: g.groupId, name: g.groupName));
            },
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.blue),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            g.groupName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          padding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 0,
                          ),
                          label: Text(
                            g.status ? 'Aktiv' : 'Guruhdan o\'chirildi',
                          ),
                          backgroundColor: g.status
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                        ),
                      ],
                    ),
                    const Divider(color: Colors.grey, thickness: 0.5),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Start: ${g.startDate.isNotEmpty ? g.startDate : "-"}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${g.startUserId.isNotEmpty ? g.startUserId : "-"}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.comment_bank_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4.0),
                        Text('Izoh: ${g.startAbout}'),
                      ],
                    ),
                    g.status == false
                        ? Column(
                            children: [
                              const Divider(color: Colors.grey, thickness: 0.5),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_month,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Start: ${g.endDate.isNotEmpty ? g.endDate : "-"}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${g.endUserId.isNotEmpty ? g.endUserId : "-"}',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (g.endAbout.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.comment_bank_outlined,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4.0),
                                    Text('Izoh: ${g.endAbout}'),
                                  ],
                                ),
                              ],
                            ],
                          )
                        : SizedBox(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoDetailsCard(ThemeData theme) {
    final registr =
        _child?['registr']?.toString() ??
        _child?['created_at']?.toString() ??
        '';
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _child?['status'] == true ? Colors.blue : Colors.red,
        ),
      ),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_3, size: 14, color: Colors.blue),
                    const SizedBox(width: 4.0),
                    Text(
                      "${_child?['name'] ?? ''}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.badge, size: 14, color: Colors.blue),
                    const SizedBox(width: 4.0),
                    Text(
                      "${_child?['seria'] ?? ''}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.grey, thickness: 1),
            _InfoRow(
              icon: Icons.wallet,
              label: 'Balans:',
              value: '${_child?['balans'] ?? 0} UZS',
            ),
            _InfoRow(
              icon: Icons.calculate,
              label: 'Hisobot davri:',
              value: '${_child?['balans_data'] ?? "..."}',
            ),
            _InfoRow(
              icon: Icons.cake,
              label: 'Tug\'ilgan sana:',
              value: '${_child?['tkun'] ?? ''}',
            ),
            _InfoRow(
              icon: Icons.person_2_rounded,
              label: 'Ro\'yhatga oldi:',
              value: '${_child?['user_id'] ?? ''}',
            ),
            _InfoRow(
              icon: Icons.calendar_month,
              label: "Ro'yhatga olindi:",
              value: registr,
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                      side: BorderSide(
                        color: _child?['guvohnoma'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.badge,
                            color: _child?['guvohnoma'] == true
                                ? Colors.green
                                : Colors.blue,
                          ),
                          const SizedBox(height: 4.0),
                          const Text("Guvohnoma"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Card(
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                      side: BorderSide(
                        color: _child?['passport'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_ind,
                            color: _child?['passport'] == true
                                ? Colors.green
                                : Colors.blue,
                          ),
                          const SizedBox(height: 4.0),
                          const Text("Pasport"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Card(
                    color: Colors.white,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                      side: BorderSide(
                        color: _child?['gepatet'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.vaccines,
                            color: _child?['gepatet'] == true
                                ? Colors.green
                                : Colors.blue,
                          ),
                          const SizedBox(height: 4.0),
                          const Text("Vaksina"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            _child?['status'] == false
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Get.to(
                          () => ChildAddGroup(
                            id: int.tryParse(_child!['id'].toString()) ?? 0,
                          ),
                        );
                        if (result == true) {
                          await _fetchChild();
                          Get.snackbar(
                            'Muvaffaqiyat',
                            'Guruhga qoʻshildi — maʼlumot yangilandi',
                            backgroundColor: Colors.green.shade600,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.TOP,
                          );
                        }
                      },
                      icon: const Icon(Icons.group_add, size: 20),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Text(
                          "Guruhga qo'shish",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.blue.shade300),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          Text(value),
        ],
      ),
    );
  }
}

class GroupInfo {
  final int groupId;
  final String groupName;
  final bool status;
  final String startDate;
  final String startUserId;
  final String startAbout;
  late final String endDate;
  final String endUserId;
  final String endAbout;

  GroupInfo({
    required this.groupId,
    required this.groupName,
    required this.status,
    required this.startDate,
    required this.startUserId,
    required this.startAbout,
    required this.endDate,
    required this.endUserId,
    required this.endAbout,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      groupId: int.tryParse('${json['group_id'] ?? 0}') ?? 0,
      groupName: json['group_name']?.toString() ?? '',
      status: json['status'] == true,
      startDate: json['start_data']?.toString() ?? '',
      startUserId: json['start_user_id']?.toString() ?? '',
      startAbout: json['start_about']?.toString() ?? '',
      endDate: json['end_data']?.toString() ?? '',
      endUserId: json['end_user_id']?.toString() ?? '',
      endAbout: json['end_about']?.toString() ?? '',
    );
  }

  factory GroupInfo.empty() {
    return GroupInfo(
      groupId: 0,
      groupName: '',
      status: false,
      startDate: '',
      startUserId: '',
      startAbout: '',
      endDate: '',
      endUserId: '',
      endAbout: '',
    );
  }
}
