import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class SmsSettingPage extends StatefulWidget {
  const SmsSettingPage({super.key});

  @override
  State<SmsSettingPage> createState() => _SmsSettingPageState();
}

class _SmsSettingPageState extends State<SmsSettingPage> {
  final GetStorage _storage = GetStorage();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _error = '';

  // Controllers
  final TextEditingController _loginCtrl = TextEditingController();
  final TextEditingController _parolCtrl = TextEditingController();
  final TextEditingController _createChildTextCtrl = TextEditingController();
  final TextEditingController _debetTextCtrl = TextEditingController();
  final TextEditingController _paymartTextCtrl = TextEditingController();

  // Statuslar
  bool _createChildStatus = false;
  bool _debetStatus = false;
  bool _paymartStatus = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  // ================= GET SETTINGS =================
  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    final token = _storage.read('token');

    if (token == null) {
      setState(() {
        _error = "Token topilmadi";
        _isLoading = false;
      });
      return;
    }

    try {
      final resp = await http.get(
        Uri.parse("${ApiConst.apiUrl}/setting-sms"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body)["data"];

        setState(() {
          _loginCtrl.text = data["login"] ?? "";
          _parolCtrl.text = data["parol"] ?? "";
          _createChildTextCtrl.text = data["create_child_text"] ?? "";
          _debetTextCtrl.text = data["debet_send_text"] ?? "";
          _paymartTextCtrl.text = data["paymart_text"] ?? "";

          _createChildStatus = data["create_child_status"] == 1;
          _debetStatus = data["debet_send_status"] == 1;
          _paymartStatus = data["paymart_status"] == 1;

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Server xatosi: ${resp.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Xatolik: $e";
        _isLoading = false;
      });
    }
  }

  // ================= SUBMIT =================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final token = _storage.read('token');

    try {
      final resp = await http.post(
        Uri.parse("${ApiConst.apiUrl}/setting-sms-update"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "login": _loginCtrl.text.trim(),
          "parol": _parolCtrl.text.trim(),
          "create_child_status": _createChildStatus ? "1" : "0",
          "create_child_text": _createChildTextCtrl.text.trim(),
          "debet_send_status": _debetStatus ? "1" : "0",
          "debet_send_text": _debetTextCtrl.text.trim(),
          "paymart_status": _paymartStatus ? "1" : "0",
          "paymart_text": _paymartTextCtrl.text.trim(),
        },
      );

      if (resp.statusCode == 200) {
        Navigator.of(context).pop(true);
        Future.delayed(Duration(milliseconds: 50), () {
          Get.snackbar(
              'Muvaffaqiyat',
              "SMS sozlamalari muvaffaqiyatli saqland.",
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP
          );
        });
      } else {
        Get.snackbar("Xato", "Server xatosi: ${resp.statusCode}",
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade700);
      }
    } catch (e) {
      Get.snackbar("Xato", "So‘rovda xatolik: $e",
          backgroundColor: Colors.red.shade50, colorText: Colors.red.shade700);
    }

    setState(() => _isSubmitting = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SMS Sozlamalari"),
        backgroundColor: primary,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: primary),
      )
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            ElevatedButton.icon(
              onPressed: _fetchSettings,
              icon: const Icon(Icons.refresh),
              label: const Text("Qayta urinish"),
            )
          ],
        ),
      )
          : _buildForm(primary),
    );
  }

  Widget _buildForm(Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("Sms API Kirish ma'lumotlari", Icons.vpn_key),
              const SizedBox(height: 10),

              _inputField(
                controller: _loginCtrl,
                label: "Login (Majburiy emas)",
                icon: Icons.person_outline,
                required: false,
              ),
              const SizedBox(height: 12),

              _inputField(
                controller: _parolCtrl,
                label: "Parol (Majburiy emas)",
                icon: Icons.lock_outline,
                required: false,
              ),
              const SizedBox(height: 18),

              _title("Yuboriladigan SMS xabarlari", Icons.sms_outlined),
              const SizedBox(height: 14),

              _switchTile(
                  "Yangi bola qo‘shilganda SMS", _createChildStatus,
                      (v) => setState(() => _createChildStatus = v)),
              _inputField(
                  controller: _createChildTextCtrl,
                  label: "SMS matni",
                  icon: Icons.message_outlined),
              const SizedBox(height: 14),

              _switchTile("Qarzdorlik SMS", _debetStatus,
                      (v) => setState(() => _debetStatus = v)),
              _inputField(
                  controller: _debetTextCtrl,
                  label: "SMS matni",
                  icon: Icons.warning_amber),
              const SizedBox(height: 14),

              _switchTile("To‘lov SMS", _paymartStatus,
                      (v) => setState(() => _paymartStatus = v)),
              _inputField(
                  controller: _paymartTextCtrl,
                  label: "SMS matni",
                  icon: Icons.payments_outlined),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : Text("Saqlash", style: TextStyle(fontSize: 16,color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue,width: 1.5),
        color: Colors.white,
      ),
      child: TextFormField(
        controller: controller,
        validator: (v) =>
        required && (v == null || v.trim().isEmpty) ? "Majburiy maydon" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon,color: Colors.blue,),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          labelStyle: TextStyle(color: Colors.blue.shade700),
        ),
        minLines: 1,
        maxLines: 3,
      ),
    );
  }

  Widget _switchTile(String title, bool value, Function(bool) onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue,width: 1.5),
        color: Colors.white,
      ),
      margin: EdgeInsets.only(bottom: 4),
      child: SwitchListTile(
        value: value,
        onChanged: onChange,
        activeColor: Colors.blue,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _title(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade700),
        ),
      ],
    );
  }
}
