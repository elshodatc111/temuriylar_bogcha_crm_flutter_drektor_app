import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/moliya/balans_daromad_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/moliya/balans_exson_page.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/moliya/balans_input_create.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/moliya/balans_xarajat_page.dart';

class MoliyaPage extends StatefulWidget {
  const MoliyaPage({super.key});

  @override
  State<MoliyaPage> createState() => _MoliyaPageState();
}

class _MoliyaPageState extends State<MoliyaPage> {
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Map<String, dynamic>? dataBalances;
  List<dynamic> history = [];
  final box = GetStorage();
  final String baseUrl = ApiConst.apiUrl;

  final currencyF = NumberFormat.decimalPattern('uz');

  @override
  void initState() {
    super.initState();
    fetchMoliya();
  }

  Future<String?> _getToken() async {
    final token = box.read('token');
    if (token == null) return null;
    return token.toString();
  }

  Future<void> fetchMoliya() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });
    final token = await _getToken();
    if (token == null) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = "Token topilmadi — iltimos tizimga kiring.";
      });
      return;
    }
    try {
      final uri = Uri.parse('$baseUrl/moliya-get');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['status'] == true) {
          setState(() {
            dataBalances = Map<String, dynamic>.from(json['data'] ?? {});
            history = List<dynamic>.from(json['history'] ?? []);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = json['message']?.toString() ?? 'Server xatosi';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'HTTP xato: ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'So‘rovda xato: $e';
      });
    }
  }

  String _formatCurrency(dynamic v) {
    final val = (v is int) ? v : (int.tryParse(v?.toString() ?? '') ?? 0);
    return '${currencyF.format(val)} UZS';
  }

  Color _colorForType(String? t) {
    switch (t) {
      case 'naqt':
        return Colors.green.shade700;
      case 'card':
        return Colors.blue.shade700;
      case 'shot':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _iconForType(String? t) {
    switch (t) {
      case 'naqt':
        return Icons.attach_money;
      case 'card':
        return Icons.credit_card;
      case 'shot':
        return Icons.account_balance_wallet;
      default:
        return Icons.receipt_long;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return iso ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Moliya'),
      ),
      body: RefreshIndicator(
        onRefresh: fetchMoliya,
        child: isLoading
            ? _circleLoading()
            : hasError
            ? _errorWidget()
            : SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _summaryCards(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _actionButtons(),
              ),
              const SizedBox(height: 12),
              if (history.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balans tarixi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('oxirgi 90 kunlik', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(child: _moliyaHistory()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCards() {
    final naqt = dataBalances?['naqt'] ?? 0;
    final card = dataBalances?['card'] ?? 0;
    final shot = dataBalances?['shot'] ?? 0;
    final ex_naqt = dataBalances?['exson_naqt'] ?? 0;
    final ex_card = dataBalances?['exson_card'] ?? 0;
    final ex_shot = dataBalances?['exson_shot'] ?? 0;

    final total = (naqt is int ? naqt : int.tryParse(naqt?.toString() ?? '0') ?? 0) +
        (card is int ? card : int.tryParse(card?.toString() ?? '0') ?? 0) +
        (shot is int ? shot : int.tryParse(shot?.toString() ?? '0') ?? 0);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.indigo.shade200.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jami balans', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('${currencyF.format(total)} UZS', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(
                onPressed: fetchMoliya,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Yangilash',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _smallBalanceCard('Naqt summa', naqt, ex_naqt, Colors.green),
            const SizedBox(width: 8),
            _smallBalanceCard('Plastik kartada', card, ex_card, Colors.blue),
            const SizedBox(width: 8),
            _smallBalanceCard('Hisob raqam', shot, ex_shot, Colors.orange),
          ],
        )
      ],
    );
  }

  Widget _smallBalanceCard(String title, dynamic value, dynamic ex, Color color) {
    final intVal = (value is int) ? value : (int.tryParse(value?.toString() ?? '') ?? 0);
    final exVal = (ex is int) ? ex : (int.tryParse(ex?.toString() ?? '') ?? 0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(
                    title == 'Naqt' ? Icons.attach_money : (title == 'Plastik' ? Icons.credit_card : Icons.account_balance_wallet),
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: Text('${currencyF.format(intVal)} UZS', style: TextStyle(fontWeight: FontWeight.bold, color: color))),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text('Exson: ${currencyF.format(exVal)} UZS', style: const TextStyle(fontSize: 12, color: Colors.black54))),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _menuButton(
                title: "Balansdan xarajat",
                color: Colors.red.shade600,
                icon: Icons.money_off,
                onTap: () async {
                  final result = await Get.to(() => BalansXarajatPage(maxNaqt: dataBalances!['naqt'], maxCard: dataBalances!['card'], maxShot: dataBalances!['shot']));
                  if (result == true) {
                    fetchMoliya();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _menuButton(
                title: "Exson chiqim",
                color: Colors.orange.shade700,
                icon: Icons.account_balance_wallet,
                onTap: () async {
                  final result = await Get.to(() => BalansExsonPage(maxNaqt: dataBalances!['exson_naqt'], maxCard: dataBalances!['exson_card'], maxShot: dataBalances!['exson_shot']));
                  if (result == true) {
                    fetchMoliya();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _menuButton(
                title: "Daromad chiqim",
                color: Colors.green.shade600,
                icon: Icons.attach_money,
                onTap: () async {
                  final result = await Get.to(() => BalansDaromadPage(maxNaqt: dataBalances!['naqt'], maxCard: dataBalances!['card'], maxShot: dataBalances!['shot']));
                  if (result == true) {
                    fetchMoliya();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _menuButton(
                title: "Balansga kirim",
                color: Colors.blue.shade600,
                icon: Icons.trending_up,
                onTap: () async {
                  final result = await Get.to(() => BalansInputCreate());
                  if (result == true) {
                    fetchMoliya();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _menuButton({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.14)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moliyaHistory() {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Tarixda yozuvlar mavjud emas', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (ctx, index) {
        final item = history[index] as Map<String, dynamic>;
        final t = item['type']?.toString();
        final status = item['status']?.toString() ?? '';
        final amount = item['amount'];
        final about = item['about'] ?? '';
        final user = item['user_id'] ?? '';
        final created = item['created_at'] ?? '';

        final color = _colorForType(t);
        final icon = _iconForType(t);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),side: BorderSide(color: Colors.blue)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(status, style: const TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(width: 8),
                  Text(_formatCurrency(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(user.toString(), style: const TextStyle(fontSize: 13))),
                      Text(_formatDate(created.toString()), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  if ((about?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(about.toString(), style: const TextStyle(fontSize: 13)),
                  ]
                ],
              ),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemCount: history.length,
    );
  }

  Widget _circleLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(color: Colors.indigo),
          SizedBox(height: 12),
          Text('Yuklanmoqda...'),
        ],
      ),
    );
  }

  Widget _errorWidget() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 70, color: Colors.red.shade400),
        const SizedBox(height: 16),
        Center(child: Text(errorMessage, textAlign: TextAlign.center)),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: fetchMoliya,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            ),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Qayta urinib ko\'rish', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
