import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class PaymartSettingPage extends StatefulWidget {
  const PaymartSettingPage({super.key});

  @override
  State<PaymartSettingPage> createState() => _PaymartSettingPageState();
}

class _PaymartSettingPageState extends State<PaymartSettingPage> {
  final GetStorage _storage = GetStorage();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _error = '';

  // controllers
  final TextEditingController _exsonCtrl = TextEditingController();
  final TextEditingController _b80Ctrl = TextEditingController();
  final TextEditingController _b85Ctrl = TextEditingController();
  final TextEditingController _b90Ctrl = TextEditingController();
  final TextEditingController _b95Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final token = _storage.read("token");

    if (token == null || token.toString().isEmpty) {
      setState(() {
        _error = "Token topilmadi!";
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse("${ApiConst.apiUrl}/setting-paymart");
      final resp = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body)["data"];

        _exsonCtrl.text = data["exson_foiz"].toString();
        _b80Ctrl.text = data["bonus_80_plus"].toString();
        _b85Ctrl.text = data["bonus_85_plus"].toString();
        _b90Ctrl.text = data["bonus_90_plus"].toString();
        _b95Ctrl.text = data["bonus_95_plus"].toString();
      } else {
        _error = "Server xatosi: ${resp.statusCode}";
      }
    } catch (e) {
      _error = "Xatolik: $e";
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    final token = _storage.read("token");

    if (token == null || token.toString().isEmpty) {
      Get.snackbar("Xato", "Token topilmadi!");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse("${ApiConst.apiUrl}/setting-paymart-update");

      final resp = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "exson_foiz": _exsonCtrl.text.trim(),
          "bonus_80_plus": _b80Ctrl.text.trim(),
          "bonus_85_plus": _b85Ctrl.text.trim(),
          "bonus_90_plus": _b90Ctrl.text.trim(),
          "bonus_95_plus": _b95Ctrl.text.trim(),
        },
      );

      if (resp.statusCode == 200) {
        Navigator.of(context).pop(true);
        Future.delayed(Duration(milliseconds: 50), () {
          Get.snackbar(
              'Muvaffaqiyat',
              "To'lov sozlamalari muvaffaqiyatli saqland.",
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP
          );
        });
      } else {
        Get.snackbar("Xato", "Server xatosi: ${resp.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Xato", "So‘rovda xatolik: $e");
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text("To'lov sozlamalari"),
        backgroundColor: primary,
      ),

      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primary),
            const SizedBox(height: 10),
            const Text("Ma'lumotlar yuklanmoqda...")
          ],
        ),
      )
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _fetchInitial,
              icon: const Icon(Icons.refresh),
              label: const Text("Qayta urinish"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
              ),
            )
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input("Exson foiz (%)", _exsonCtrl,true),
            const SizedBox(height: 12),
            _input("Bonus 80%+", _b80Ctrl,false),
            const SizedBox(height: 12),
            _input("Bonus 85%+", _b85Ctrl,false),
            const SizedBox(height: 12),
            _input("Bonus 90%+", _b90Ctrl,false),
            const SizedBox(height: 12),
            _input("Bonus 95%+", _b95Ctrl,false),
            const SizedBox(height: 20),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  "Saqlash",
                  style: TextStyle(fontSize: 16,color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, bool status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue,width: 1.5),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: status?Icon(Icons.percent,color: Colors.blue,):Icon(Icons.payment,color: Colors.blue,),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          labelStyle: TextStyle(color: Colors.blue.shade700),
        ),
      ),
    );
  }
}
