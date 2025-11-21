import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
final String baseUrl = ApiConst.apiUrl;
class DavomadCreatrePage extends StatefulWidget {
  const DavomadCreatrePage({super.key});
  @override
  State<DavomadCreatrePage> createState() => _DavomadCreatrePageState();
}
class _DavomadCreatrePageState extends State<DavomadCreatrePage> {
  final GetStorage _storage = GetStorage();
  String? _token;

  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _hodimlar = [];

  final List<String> statuses = [
    "formada_keldi",
    "formasiz_keldi",
    "ish_kuni_emas",
    "kelmadi",
    "kechikdi",
    "kasal",
    "sababli",
  ];
  Map<int, String> selectedStatus = {};
  @override
  void initState() {
    super.initState();
    _token = _storage.read('token');
    _fetchHodimlar();
  }
  Future<void> _fetchHodimlar() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('$baseUrl/emploes-davomad-show');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/json',
      });

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        _hodimlar = body["about"] ?? [];
      }
    } catch (e) {
      Get.snackbar("Xato", "So‘rovda xatolik: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveAttendance() async {
    if (selectedStatus.length != _hodimlar.length) {
      Get.snackbar("Xato", "Barcha hodimlarga status tanlang!");
      return;
    }
    setState(() => _isSaving = true);
    try {
      final uri = Uri.parse('$baseUrl/emploes-davomad');
      final body = {
        "attendance": selectedStatus.entries.map((e) => {
          "user_id": e.key,
          "status": e.value,
        }).toList(),
      };
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      if (resp.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop(true);
          Future.delayed(Duration(milliseconds: 50), () {
            Get.snackbar(
                'Muvaffaqiyat',
                "Davomad muvaffaqiyatli saqlandi",
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP
            );
          });
        }
      } else {
        Get.snackbar("Xato", "Server xatosi: serverga bog'lanishdagi xatolik");
      }
    } catch (e) {
      Get.snackbar("Xato", "So‘rov xatosi, Qaytadan urinib ko'ring.");
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue.shade700;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Davomad olish"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue,backgroundColor: Colors.white,))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _hodimlar.length,
              itemBuilder: (ctx, index) {
                final h = _hodimlar[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.blue, width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h["name"],style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 0,
                          children: statuses.map((s) {
                            final bool selected = selectedStatus[h["user_id"]] == s;
                            return ChoiceChip(
                              label: Text(
                                s.replaceAll("_", " ").toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: selected,
                              selectedColor: primary,
                              backgroundColor:
                              Colors.grey.shade200,
                              labelStyle: TextStyle(color:selected ? Colors.white : Colors.black),
                              onSelected: (val) {
                                setState(() {selectedStatus[h["user_id"]] = s;});
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20,left: 16,right: 16,top: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAttendance,
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(Icons.save,color: Colors.white,),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _isSaving ? "Saqlanmoqda..." : "Davomadni saqlash",
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
