import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class BalansDaromadPage extends StatefulWidget {
  final int maxNaqt;
  final int maxCard;
  final int maxShot;

  const BalansDaromadPage({
    super.key,
    required this.maxNaqt,
    required this.maxCard,
    required this.maxShot,
  });

  @override
  State<BalansDaromadPage> createState() => _BalansDaromadPageState();
}

class _BalansDaromadPageState extends State<BalansDaromadPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  bool _isSubmitting = false;

  final box = GetStorage();
  final String baseUrl = ApiConst.apiUrl;

  @override
  void dispose() {
    _amountController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final token = box.read('token');
    if (token == null) return null;
    return token.toString();
  }

  int _maxForType(String? type) {
    switch (type) {
      case 'naqt':
        return widget.maxNaqt;
      case 'card':
        return widget.maxCard;
      case 'shot':
        return widget.maxShot;
      default:
        return 0;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token topilmadi — iltimos tizimga kiring.'),
        ),
      );
      return;
    }

    final type = _selectedType!;
    final amount = int.parse(_amountController.text.trim());
    final about = _aboutController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('$baseUrl/moliya-daromad');
      final body = jsonEncode({'type': type, 'amount': amount, 'about': about});

      final resp = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final jsonResp = jsonDecode(resp.body);
        final ok =
            (jsonResp['status'] == true) || (jsonResp['success'] == true);
        final message = jsonResp['message'] ?? 'Amal bajarildi';
        if (ok) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message.toString())));
            Navigator.of(
              context,
            ).pop(true); // muvaffaqiyat belgisi bilan chiqish
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message.toString())));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server xatosi: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('So‘rovda xato: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatInt(int v) {
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final maxNaqt = widget.maxNaqt;
    final maxCard = widget.maxCard;
    final maxShot = widget.maxShot;

    return Scaffold(
      appBar: AppBar(title: const Text("Daromadni chiqim qilish")),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Info cards showing maxima
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        'Mavjud Naqt',
                        _formatInt(maxNaqt),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoTile(
                        'Mavjud Plastik',
                        _formatInt(maxCard),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoTile(
                        'Hisob raqamda',
                        _formatInt(maxShot),
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Form fields
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
                      border: Border.all(color: Colors.blue)
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Chiqim turi',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'naqt', child: Text('Naqt')),
                      DropdownMenuItem(
                        value: 'card',
                        child: Text('Plastik (Card)'),
                      ),
                      DropdownMenuItem(
                        value: 'shot',
                        child: Text('Hisob raqam (Shot)'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v),
                    validator: (v) => v == null ? 'Chiqim turini tanlang' : null,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
                      border: Border.all(color: Colors.blue)
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Miqdor',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixText: _selectedType == null
                          ? null
                          : 'Max: ${_formatInt(_maxForType(_selectedType))}',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Miqdorni kiriting';
                      // digit-by-digit safe parse
                      final s = val.trim();
                      // check each character is digit
                      for (int i = 0; i < s.length; i++) {
                        final code = s.codeUnitAt(i);
                        if (code < 48 || code > 57) return 'Faqat raqam kiriting';
                      }
                      final parsed = int.tryParse(s);
                      if (parsed == null) return 'Noto\'g\'ri son';
                      if (parsed <= 0) return 'Miqdor musbat bo\'lishi kerak';
                      if (_selectedType != null) {
                        final maxAllowed = _maxForType(_selectedType);
                        if (parsed > maxAllowed)
                          return 'Maksimal ruxsat etilgan: $maxAllowed';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadiusGeometry.all(Radius.circular(8.0)),
                      border: Border.all(color: Colors.blue)
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                  child: TextFormField(
                    controller: _aboutController,
                    decoration: const InputDecoration(
                      labelText: 'Izoh (about)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    maxLines: 3,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
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
                                'Jo\'natilmoqda...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            'Chiqim qilish',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
