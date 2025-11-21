import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_page.dart';

final String baseUrl = ApiConst.apiUrl;

class EndChildWidget extends StatefulWidget {
  const EndChildWidget({super.key});

  @override
  State<EndChildWidget> createState() => _EndChildWidgetState();
}

class _EndChildWidgetState extends State<EndChildWidget>with SingleTickerProviderStateMixin {
  final GetStorage _storage = GetStorage();
  final TextEditingController _searchController = TextEditingController();

  List<Child> _allChildren = [];
  List<Child> _filteredChildren = [];
  bool _isLoading = false;
  String? _token;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _token = _storage.read('token') as String?;
    _fetchChildren();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredChildren = List.from(_allChildren));
      return;
    }

    setState(() {
      _filteredChildren = _allChildren.where((c) {
        final name = c.name.toLowerCase();
        final seria = c.seria.toLowerCase();
        return name.contains(q) || seria.contains(q);
      }).toList();
    });
  }

  Future<void> _fetchChildren() async {
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = "Token topilmadi. Iltimos login holatini tekshiring.";
        _allChildren = [];
        _filteredChildren = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final uri = Uri.parse('$baseUrl/child-end');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        final children = data.map((e) => Child.fromJson(e)).toList();
        setState(() {
          _allChildren = children;
          _filteredChildren = List.from(_allChildren);
        });
      } else {
        String msg = 'Server xatosi: ${response.statusCode}';
        try {
          final Map<String, dynamic> err = json.decode(response.body);
          if (err.containsKey('message')) msg = err['message'].toString();
        } catch (_) {}
        setState(() {
          _error = msg;
          _allChildren = [];
          _filteredChildren = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'So‘rovda xatolik: $e';
        _allChildren = [];
        _filteredChildren = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchChildren();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Ism yoki guvohnoma/seria...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                  setState(() => _filteredChildren = List.from(_allChildren));
                },
              )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
              isDense: true,
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: Builder(builder: (context) {
              if (_isLoading) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: CircularProgressIndicator()),
                    SizedBox(height: 12),
                    Center(child: Text("Ma'lumot yuklanmoqda...")),
                  ],
                );
              }

              if (_error.isNotEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    Center(child: Text(_error, style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _fetchChildren,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Qayta yuklash'),
                      ),
                    ),
                  ],
                );
              }

              if (_filteredChildren.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 40),
                    Center(child: Text("Ma'lumot topilmadi")),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _filteredChildren.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final child = _filteredChildren[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final result = await Get.to(() => ChildShowPage(id: child.id,name: child.name,));
                      if (result == true) {
                        await _onRefresh();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                        border: Border.all(
                          color: child.status ? Colors.green.shade600 : Colors.red.shade400,
                          width: 0.9,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                  child.status ? Colors.green.shade50 : Colors.red.shade50,
                                  child: Text(
                                    child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: child.status ? Colors.green.shade800 : Colors.red.shade700,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.confirmation_number, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            child.seria,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          // user / creator
                                          Icon(Icons.person_outline, size: 13, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              child.userId,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _BalanceText(balans: child.balans),
                                    const SizedBox(height: 8),
                                    StatusChip(isActive: child.status),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      DocumentBadge(
                                        available: child.guvohnoma,
                                        icon: Icons.badge,
                                        label: ' ',
                                      ),
                                      DocumentBadge(
                                        available: child.passport,
                                        icon: Icons.password,
                                        label: ' ',
                                      ),
                                      DocumentBadge(
                                        available: child.gepatet,
                                        icon: Icons.vaccines,
                                        label: ' ',
                                      ),
                                    ],
                                  ),
                                ),

                                // Small timestamps
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.cake, size: 14, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(child.tkun, style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(child.createdAt,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    )
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
              );
            }),
          ),
        ),
      ],
    );
  }
}

class DocumentBadge extends StatelessWidget {
  final bool available;
  final IconData icon;
  final String label;
  const DocumentBadge({
    Key? key,
    required this.available,
    required this.icon,
    required this.label,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final bg = available ? Colors.green.shade50 : Colors.grey.shade100;
    final ic = available ? Colors.green.shade700 : Colors.grey.shade500;
    final txt = available ? Colors.green.shade800 : Colors.grey.shade600;
    return Tooltip(
      message: available ? '$label: Mavjud' : '$label: Topilmadi',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: bg,
            child: Icon(icon, size: 16, color: ic),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: txt)),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final bool isActive;
  const StatusChip({Key? key, required this.isActive}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green.shade600 : Colors.red.shade600;
    final bg = isActive ? Colors.green.shade50 : Colors.red.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? Icons.check_circle : Icons.remove_circle, size: 14, color: color),
          const SizedBox(width: 6),
          Text(isActive ? 'Aktiv' : 'Faol emas', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BalanceText extends StatelessWidget {
  final int balans;
  const _BalanceText({Key? key, required this.balans}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey.shade700;
    if (balans < 0) color = Colors.red.shade700;
    else if (balans > 0) color = Colors.green.shade700;
    return Text(
      '${balans} so\'m',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({Key? key, required this.label, required this.value}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
class Child {
  final int id;
  final String name;
  final String seria;
  final String tkun;
  final bool status;
  final int balans;
  final bool guvohnoma;
  final bool passport;
  final bool gepatet;
  final String userId;
  final String createdAt;

  Child({
    required this.id,
    required this.name,
    required this.seria,
    required this.tkun,
    required this.status,
    required this.balans,
    required this.guvohnoma,
    required this.passport,
    required this.gepatet,
    required this.userId,
    required this.createdAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      seria: json['seria']?.toString() ?? '',
      tkun: json['tkun']?.toString() ?? '',
      status: json['status'] == true || json['status'].toString() == '1',
      balans: json['balans'] is int ? json['balans'] : int.tryParse(json['balans'].toString()) ?? 0,
      guvohnoma: json['guvohnoma'] == true,
      passport: json['passport'] == true,
      gepatet: json['gepatet'] == true,
      userId: json['user_id']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
