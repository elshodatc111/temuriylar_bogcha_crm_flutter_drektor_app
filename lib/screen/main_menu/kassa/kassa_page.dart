// (BU TO'LIQ YANGILANGAN FILENI TO'G'RILAB O'RNATISH KERAK)
// KassaPage — yangilangan versiya (dizayn o'zgarmagan, kamchiliklar tuzatilgan)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_show/chegirma_items.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_show/ish_haqi_items.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_show/kassdan_chiqim_item.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_show/paymarts_item.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/group/group_show/qaytar_tulov_item.dart';

String baseUrl = ApiConst.apiUrl;

class KassaPage extends StatefulWidget {
  const KassaPage({super.key});

  @override
  State<KassaPage> createState() => _KassaPageState();
}

class _KassaPageState extends State<KassaPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _kassa = {};
  late final String token;
  List<dynamic> _tulovlar = [];
  List<dynamic> _ishHaqi = [];
  List<dynamic> _qaytarish = [];
  List<dynamic> _chegirma = [];
  List<dynamic> _chiqim_xarajat = [];

  // Per-item loading sets
  final Set<int> _loadingDeleteIds = {};
  final Set<int> _loadingConfirmIds = {};

  @override
  void initState() {
    super.initState();
    token = GetStorage().read('token') ?? '';
    _fetchKassa();
  }

  Future<void> _fetchKassa() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$baseUrl/kassa-get');
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;
        final kassaJson = jsonBody['kassa'] as Map<String, dynamic>? ?? {};
        final tulovlar = jsonBody['tulovlar'] as List<dynamic>? ?? [];
        final ishHaqi = jsonBody['ish_haqi'] as List<dynamic>? ?? [];
        final qaytarish = jsonBody['qaytarish'] as List<dynamic>? ?? [];
        final chegirma = jsonBody['chegirma'] as List<dynamic>? ?? [];
        final chiqim_xarajat =
            jsonBody['chiqim_xarajat'] as List<dynamic>? ?? [];
        if (!mounted) return;
        setState(() {
          _kassa = kassaJson;
          _tulovlar = tulovlar;
          _ishHaqi = ishHaqi;
          _qaytarish = qaytarish;
          _chegirma = chegirma;
          _chiqim_xarajat = chiqim_xarajat;
        });
      } else {
        if (!mounted) return;
        setState(() => _error = 'Server error: ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Network error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int _intFromKey(String key) {
    final v = _kassa[key];
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _formatCurrency(int value) {
    final f = NumberFormat.decimalPattern('uz');
    return '${f.format(value)} UZS';
  }

  // API: o'chirish
  Future<void> _cancelChiqim(int id) async {
    if (id <= 0) {
      // noto'g'ri id bo'lsa bekor qilamiz
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid id to cancel.')),
      );
      return;
    }
    if (_loadingDeleteIds.contains(id)) return;
    setState(() => _loadingDeleteIds.add(id));
    try {
      // har safar tokenni yangilab olish (agar sessiyada o'zgarishi mumkin bo'lsa)
      final localToken = GetStorage().read('token') ?? token;
      final uri = Uri.parse('$baseUrl/kassa-chiqim-cancel');
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $localToken',
        },
        body: jsonEncode({'id': id}),
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chiqqim muvaffaqiyatli o'chirildi.")),
        );
        await _fetchKassa();
      } else {
        // server error: agar kerak bo'lsa res.body ham chiqarilishi mumkin
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server xatosi: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarmoq xatosi: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loadingDeleteIds.remove(id));
    }
  }

  // API: tasdiqlash
  Future<void> _confirmChiqim(int id) async {
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid id to confirm.')),
      );
      return;
    }
    if (_loadingConfirmIds.contains(id)) return;
    setState(() => _loadingConfirmIds.add(id));
    try {
      final localToken = GetStorage().read('token') ?? token;
      final uri = Uri.parse('$baseUrl/kassa-chiqim-success');
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $localToken',
        },
        body: jsonEncode({'id': id}),
      );
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chiqqim tasdiqlandi.")),
        );
        await _fetchKassa();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server xatosi: ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarmoq xatosi: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loadingConfirmIds.remove(id));
    }
  }

  Future<void> _openCenteredModal(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      String type,
      ) async {
    final width = MediaQuery.of(context).size.width * 0.96;
    final maxHeight = MediaQuery.of(context).size.height * 0.60;
    Widget content;
    if (type == 'chegirma') {
      content = ChegirmaItems(chegirma: _chegirma);
    } else if (type == 'tulovlar') {
      content = PaymartsItem(tulovlar: _tulovlar);
    } else if (type == 'ishHaqi') {
      content = IshHaqiItems(ishHaqi: _ishHaqi);
    } else if (type == 'kassadan_chiqim' || type == 'kassadan_chiqim') {
      content = KassdanChiqimItem(amount: _kassa['kassa_naqt'],);
    } else if (type == 'qaytar' || type == 'qaytarish') {
      content = QaytarTulovItem(qaytar: _qaytarish);
    } else {
      content = const SizedBox.shrink();
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
          child: SizedBox(
            width: width,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.grey, thickness: 1, height: 16),
                    // Container ichidagi child — dialog ichida scrollable bo'lishi uchun Expanded ishlatiladi
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required String type,
      }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: SizedBox(
          height: 72,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await _openCenteredModal(context, label, icon, color, type);
              if (!mounted) return;
              await _fetchKassa();
            },
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: color.withOpacity(0.18)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kassaAbout() {
    final total =
        _intFromKey('kassa_naqt') + _intFromKey('kassa_pedding_card') + _intFromKey('kassa_pedding_shot');
    return Column(
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.blue.withOpacity(0.12)),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kassada mavjud",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(total),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await _fetchKassa();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.refresh, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  children: [
                    _infoColumn(
                      icon: Icons.account_balance_wallet,
                      title: "Naqt summa",
                      amount: _intFromKey('kassa_naqt'),
                    ),
                    _verticalDivider(),
                    _infoColumn(
                      icon: Icons.credit_card,
                      title: "Plastik summa",
                      amount: _intFromKey('kassa_pedding_card'),
                    ),
                    _verticalDivider(),
                    _infoColumn(
                      icon: Icons.account_balance,
                      title: "Hisob raqamga to'lov",
                      amount: _intFromKey('kassa_pedding_shot'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoColumn(
                      icon: Icons.money_off,
                      title: "Chiqim (Naqt)",
                      amount: _intFromKey('kassa_pedding_naqt'),
                    ),
                    _verticalDivider(),
                    _infoColumn(
                      icon: Icons.shopping_cart,
                      title: "Xarajat (Naqt)",
                      amount: _intFromKey('xarajat_pedding_naqt'),
                    ),
                    _verticalDivider(),
                    _infoColumn(
                      icon: Icons.payments,
                      title: "To'langan ish haqi",
                      amount: _intFromKey('teacher_pedding_pay_naqt'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 56,
      color: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _infoColumn({
    required IconData icon,
    required String title,
    required int amount,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.orange, size: 22),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _renderChiqimItem(dynamic item) {
    final userBox = GetStorage().read('user') ?? <String, dynamic>{};
    final String positionRaw = (userBox['position'] ?? '').toString();
    final String position = positionRaw.toLowerCase();
    final int amount = (item['amount'] is int)
        ? item['amount'] as int
        : int.tryParse(item['amount']?.toString() ?? '') ?? 0;
    final String type = (item['type'] ?? '').toString();
    final String user = (item['user'] ?? '').toString();
    final String date = (item['create_data'] ?? '').toString();
    final String about = (item['about'] ?? '').toString();
    final int id = (item['id'] is int)
        ? item['id'] as int
        : int.tryParse(item['id']?.toString() ?? '') ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue, width: 1.2),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: amount and type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _formatCurrency(amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: type == 'xarajat'
                        ? Colors.orange.withOpacity(0.12)
                        : Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type == 'xarajat' ? "Naqt Xarajat" : "Naqt Chiqim",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: type == 'xarajat'
                          ? Colors.orange.shade800
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Info row: user and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    user,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // About / description
            Text(
              about,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Buttons row - to'liq kenglikni teng bo'lib to'ldiradi
            Row(
              children: [
                // Delete button
                Expanded(
                  child: _loadingDeleteIds.contains(id)
                      ? SizedBox(
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                      : OutlinedButton.icon(
                    onPressed: () async {
                      if (id <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Not valid id for delete')),
                        );
                        return;
                      }
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            side: BorderSide(color: Colors.blue, width: 2),
                          ),
                          title: const Text('Tasdiqlash'),
                          content: Text('Bu chiqimni o\'chirishni xohlaysizmi?',),
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      backgroundColor: Colors.red.shade50,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Text(
                                      'Bekor qilish',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: Text(
                                      'O‘chirish',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                      if (ok == true) {
                        await _cancelChiqim(id);
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'O‘chirish',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

                const SizedBox(width: 10),
                if (position == 'admin' || position == 'direktor' || position == 'drektor')
                  Expanded(
                    child: _loadingConfirmIds.contains(id)
                        ? SizedBox(
                      height: 44,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                        : ElevatedButton.icon(
                      onPressed: () async {
                        if (id <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Not valid id for confirm')),
                          );
                          return;
                        }
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              side: BorderSide(color: Colors.blue, width: 1.2),
                            ),
                            title: const Text('Tasdiqlash'),
                            content: const Text('Bu chiqimni tasdiqlaysizmi?'),
                            actions: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: Colors.red.shade50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text(
                                        'Bekor qilish',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text(
                                        'Tasdiqlash',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                        if (ok == true) {
                          await _confirmChiqim(id);
                        }
                      },
                      icon: const Icon(Icons.check_box_outlined, color: Colors.white),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Tasdiqlash', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _itemButton() {
    return Column(
      children: [
        Row(
          children: [
            _actionButton(
              context,
              label: "Qaytarilgan\nto'lovlar",
              icon: Icons.reply_all_outlined,
              color: Colors.purple.shade600,
              type: "qaytarish",
            ),
            _actionButton(
              context,
              label: "Tasdiqlanmagan\nish haqi",
              icon: Icons.payments,
              color: Colors.blue.shade700,
              type: "ishHaqi",
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _actionButton(
              context,
              label: "Berilgan\nchegirmalar",
              icon: Icons.local_offer,
              color: Colors.indigo.shade700,
              type: "chegirma",
            ),
            _actionButton(
              context,
              label: "Tasdiqlanmagan\nto'lovlar",
              icon: Icons.pending_actions,
              color: Colors.orange.shade700,
              type: "tulovlar",
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kassa'),
        actions: _loading
            ? []
            : [
          IconButton(
            onPressed: () async {
              await _openCenteredModal(
                context,
                "Kassadan Chiqim",
                Icons.outbox_outlined,
                Colors.blue,
                'kassadan_chiqim',
              );
              if (!mounted) return;
              await _fetchKassa();
            },
            icon: const Icon(Icons.outbox_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              backgroundColor: Colors.white,
              color: Colors.blue,
            ),
            SizedBox(height: 12),
            Text("Ma'lumotlar yuklanmoqda..."),
          ],
        ),
      )
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
        onRefresh: _fetchKassa,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kassaAbout(),
              const SizedBox(height: 12),
              _itemButton(),
              const SizedBox(height: 12),
              // chiqim_xarajat list
              Expanded(
                child: _chiqim_xarajat.isEmpty
                    ? const Center(
                  child: Text(
                    'Chiqqim / Xarajat yozuvlari topilmadi',
                  ),
                )
                    : ListView.builder(
                  itemCount: _chiqim_xarajat.length,
                  itemBuilder: (ctx, index) {
                    final item = _chiqim_xarajat[index];
                    return _renderChiqimItem(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
