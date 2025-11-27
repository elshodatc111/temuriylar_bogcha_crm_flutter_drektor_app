import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class HodimIshHaqiTulovAdmin extends StatefulWidget {
  final int id;

  const HodimIshHaqiTulovAdmin({super.key, required this.id});

  @override
  State<HodimIshHaqiTulovAdmin> createState() => _HodimIshHaqiTulovAdminState();
}

class _HodimIshHaqiTulovAdminState extends State<HodimIshHaqiTulovAdmin> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> employees = [];
  Map<String, dynamic>? moliyaData;
  String? selectedType;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  bool isLoading = true; // initial loading of employees + moliya
  bool isSubmitting = false;

  final box = GetStorage();
  late final String baseUrl;

  @override
  void initState() {
    super.initState();
    baseUrl = ApiConst.apiUrl;
    fetchInitialData();
  }

  Future<String?> _getToken() async {
    final token = box.read('token');
    if (token == null) return null;
    return token.toString();
  }

  Future<void> fetchInitialData() async {
    setState(() => isLoading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token topilmadi. Iltimos tizimga kiring.'),
        ),
      );
      return;
    }

    try {
      final emplUri = Uri.parse('$baseUrl/emploes');
      final moliyaUri = Uri.parse('$baseUrl/moliya-get');

      final responses = await Future.wait([
        http.get(
          emplUri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        http.get(
          moliyaUri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      ]);

      final emplResp = responses[0];
      final moliyaResp = responses[1];

      if (emplResp.statusCode == 200) {
        final json = jsonDecode(emplResp.body);
        if (json['status'] == true && json['users'] != null) {
          employees = List.from(json['users']);
        } else {
          employees = [];
        }
      } else {
        employees = [];
      }

      if (moliyaResp.statusCode == 200) {
        final json = jsonDecode(moliyaResp.body);
        if (json['status'] == true && json['data'] != null) {
          moliyaData = Map<String, dynamic>.from(json['data']);
        } else {
          moliyaData = null;
        }
      } else {
        moliyaData = null;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maʼlumotlarni olishda xato: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  int _balanceForType(String type) {
    if (moliyaData == null) return 0;
    final val = moliyaData![type];
    if (val == null) return 0;
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    if (val is double) return val.toInt();
    return 0;
  }

  String _formatCurrency(int value) {
    final f = NumberFormat.decimalPattern('uz');
    return '${f.format(value)} UZS';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Token topilmadi.')));
      return;
    }

    final amount = int.tryParse(amountController.text.trim()) ?? 0;
    if (selectedType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('To\'lov turini tanlang.')));
      return;
    }

    final available = _balanceForType(selectedType!);
    if (amount > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balansda yetarli mablag‘ mavjud emas.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final uri = Uri.parse('$baseUrl/emploes-paymart');
      final body = jsonEncode({
        'user_id': widget.id,
        'type': selectedType,
        'amount': amount,
        'about': aboutController.text.trim(),
      });

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final ok = json['status'] == true;
        final message = json['message'] ?? 'Javob olindi';
        if (ok) {
          // muvaffaqiyat — sahifani yopish
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message.toString())));
            Navigator.of(
              context,
            ).pop(true); // qaytganda muvaffaqiyatni qaytaradi
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Xato: $message')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('So\'rov bajarilmadi. Kod: ${resp.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('So\'rovda xato: $e')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  Widget _buildTypeDropdown() {
    final types = [
      {'key': 'naqt', 'label': 'Naqt to\'lov'},
      {'key': 'card', 'label': 'Plastik to\'lov'},
      {'key': 'shot', 'label': 'Hisob raqamdan to\'lov'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
        border: Border.all(color: Colors.blue),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: DropdownButtonFormField<String>(
        value: selectedType,
        decoration: const InputDecoration(
          labelText: 'To‘lov turi',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        hint: const Text('To‘lov turini tanlang'),
        items: types.map((t) {
          final key = t['key']!;
          final label = t['label']!;
          final bal = moliyaData != null ? _balanceForType(key) : 0;
          return DropdownMenuItem<String>(
            value: key,
            child: Text('$label (mavjud: ${_formatCurrency(bal)})'),
          );
        }).toList(),
        onChanged: (v) => setState(() => selectedType = v),
        validator: (v) => v == null ? 'To‘lov turini tanlang' : null,
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
        border: Border.all(color: Colors.blue),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: TextFormField(
        controller: amountController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'To\'lov summa',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) return 'Miqdorni kiriting';
          final parsed = int.tryParse(val.trim());
          if (parsed == null) return 'Faqat butun son kiriting';
          if (parsed <= 0) return 'Miqdor musbat bo\'lishi kerak';
          if (selectedType != null) {
            final avail = _balanceForType(selectedType!);
            if (parsed > avail) return 'Balansda yetarli mablag‘ mavjud emas';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAboutField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
        border: Border.all(color: Colors.blue),
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: TextFormField(
        controller: aboutController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'To\'lov haqida',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hodimga ish haqi to\'lash')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTypeDropdown(),
                    const SizedBox(height: 12),
                    _buildAmountField(),
                    const SizedBox(height: 12),
                    _buildAboutField(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // orqa fon rangi
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // radius 8
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: isSubmitting ? null : _submit,
                        child: isSubmitting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Saqlanmoqda...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : const Text(
                                'Saqlash',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
