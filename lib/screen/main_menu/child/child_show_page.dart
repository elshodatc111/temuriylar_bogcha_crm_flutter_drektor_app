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
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      });

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);
        final about = body['about'] as Map<String, dynamic>?;
        if (about == null) {
          setState(() {
            _error = 'Ma\'lumot topilmadi';
            _isLoading = false;
            _child = null;
          });
          return;
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
        });
      }
    } catch (e) {
      setState(() {
        _error = 'So‘rovda xatolik: $e';
        _isLoading = false;
        _child = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Bola haqida"),
        actions: [
          IconButton(onPressed: (){Get.to(()=>ChildDocumentPage(id: widget.id,));}, icon: Icon(Icons.folder_open)),
          IconButton(onPressed: (){Get.to(()=>ChildQarindoshlarPage(id: widget.id,));}, icon: Icon(Icons.family_restroom)),
          IconButton(onPressed: (){Get.to(()=>ChildPaymartsPage());}, icon: Icon(Icons.account_balance_wallet)),
          IconButton(onPressed: (){Get.to(()=>ChildDavomadPage());}, icon: Icon(Icons.checklist)),
        ],
      ),
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
                )
              ],
            ),
          ),
        )
            : _child == null
            ? const Center(child: Text('Ma\'lumot topilmadi'))
            : RefreshIndicator(
          onRefresh: _fetchChild,
          // Use a ListView as the scrollable root so RefreshIndicator works reliably.
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              _buildInfoDetailsCard(theme),
              const SizedBox(height: 12),
              const Text("Bola Guruhlari", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              // Get groups from _child if present, otherwise empty list
              Builder(builder: (ctx) {
                final groupsRaw = _child?['group'];
                List<dynamic> groups = [];
                if (groupsRaw is List) groups = groupsRaw;
                // If no groups provided, show informative message
                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Guruhlar topilmadi', style: TextStyle(color: Colors.grey.shade600)),
                  );
                }
                // Use a shrink-wrapped ListView.builder inside the ListView
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (ctx, index) {
                    final g = groups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.group),
                        title: Text(g.toString()),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoDetailsCard(ThemeData theme) {
    final registr = _child?['registr']?.toString() ?? _child?['created_at']?.toString() ?? '';
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _child?['status'] == true ? Colors.blue : Colors.red),
      ),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_3, size: 14, color: Colors.blue),
                  const SizedBox(width: 4.0),
                  Text(
                    "${_child?['name'] ?? ''}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.badge, size: 14, color: Colors.blue),
                  const SizedBox(width: 4.0),
                  Text(
                    "${_child?['seria'] ?? ''}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 1),
          _InfoRow(icon: Icons.wallet, label: 'Balans:', value: '${_child?['balans'] ?? 0} UZS'),
          _InfoRow(icon: Icons.calculate, label: 'Hisobot davri:', value: '${_child?['balans_data'] ?? "..."}'),
          _InfoRow(icon: Icons.cake, label: 'Tug\'ilgan sana:', value: '${_child?['tkun'] ?? ''}'),
          _InfoRow(icon: Icons.person_2_rounded, label: 'Ro\'yhatga oldi:', value: '${_child?['user_id'] ?? ''}'),
          _InfoRow(icon: Icons.calendar_month, label: "Ro'yhatga olindi:", value: registr),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.white,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                      side: BorderSide(color: _child?['guvohnoma'] == true ? Colors.green : Colors.red)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Icon(Icons.badge, color: _child?['guvohnoma'] == true ? Colors.green : Colors.blue),
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
                      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                      side: BorderSide(color: _child?['passport'] == true ? Colors.green : Colors.red)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_ind, color: _child?['passport'] == true ? Colors.green : Colors.blue),
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
                      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                      side: BorderSide(color: _child?['gepatet'] == true ? Colors.green : Colors.red)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Icon(Icons.vaccines, color: _child?['gepatet'] == true ? Colors.green : Colors.blue),
                        const SizedBox(height: 4.0),
                        const Text("Vaksina"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0,),
          _child?['status'] == false ?SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Get.to(() => ChildAddGroup(id: int.tryParse(_child!['id'].toString()) ?? 0));
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
                child: Text("Guruhga qo'shish",style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ):
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Get.to(() => ChildAddGroup(id: int.tryParse(_child!['id'].toString()) ?? 0));
                if (result == true) {
                  await _fetchChild();
                  Get.snackbar(
                    'Muvaffaqiyat',
                    'Guruhdan o\'chirildi — maʼlumot yangilandi',
                    backgroundColor: Colors.green.shade600,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                }
              },
              icon: Icon(Icons.group_remove, size: 20, color: Colors.red),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Text("Guruhdan o'chirish",style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({Key? key, required this.icon, required this.label, required this.value}) : super(key: key);
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
              Text(label)
            ],
          ),
          Text(value)
        ],
      ),
    );
  }
}
