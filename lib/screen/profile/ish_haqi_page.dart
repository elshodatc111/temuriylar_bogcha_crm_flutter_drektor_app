import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../const/api_const.dart';

class IshHaqiPage extends StatefulWidget {
  final int id;
  final String name;
  const IshHaqiPage({super.key, required this.id, required this.name});

  @override
  State<IshHaqiPage> createState() => _IshHaqiPageState();
}

class _IshHaqiPageState extends State<IshHaqiPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final box = GetStorage();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? about;
  List<dynamic> paymart = [];
  Map<String, dynamic>? davomad;
  final String baseUrl = ApiConst.apiUrl;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final String? token = box.read<String>('token');
      final uri = Uri.parse('$baseUrl/emploes-show/${widget.id}');
      final response = await http.get(uri,
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == true) {
          setState(() {
            about = body['about'] as Map<String, dynamic>?;
            paymart = (body['paymart'] as List<dynamic>?) ?? [];
            davomad = (body['davomad'] as Map<String, dynamic>?) ?? {};
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          Get.rawSnackbar(
            message: "So‘rov vaqti tugadi. Internet aloqasini tekshiring",
            backgroundColor: Colors.red,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            snackPosition: SnackPosition.TOP,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        Get.rawSnackbar(
          message: "So‘rov vaqti tugadi. Internet aloqasini tekshiring",
          backgroundColor: Colors.red,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
        );
      }
    } on TimeoutException {
      setState(() {
        _isLoading = false;
      });
      Get.rawSnackbar(
        message: "So‘rov vaqti tugadi. Internet aloqasini tekshiring",
        backgroundColor: Colors.red,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.rawSnackbar(
        message: "Serverga bog'lanishda xatolik.",
        backgroundColor: Colors.red,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        snackPosition: SnackPosition.TOP,
      );
    }
    if (_error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
    }
  }

  String _formatAmount(dynamic amount) {
    try {
      final num value = amount is num ? amount : num.parse(amount.toString());
      final String s = value.toStringAsFixed(0);
      final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
      return s.replaceAllMapped(reg, (m) => ' ${m.group(0)}');
    } catch (_) {
      return amount?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Davomad, To'langan ish haqi"),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: _isLoading && paymart.isEmpty
              ? const Center(child: CircularProgressIndicator(backgroundColor: Colors.blue,color: Colors.grey,))
              : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (davomad != null && davomad!.isNotEmpty) _buildDavomadCard(),
              const SizedBox(height: 12),
              Center(child: Text('Ish haqi to\'lovlari',style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),),),
              const SizedBox(height: 8),
              if (paymart.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.payments_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('To‘lovlar topilmadi', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: paymart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = paymart[index] as Map<String, dynamic>;
                    final String admin = item['admin_id']?.toString() ?? '';
                    final dynamic amount = item['amount'];
                    final String type = item['type']?.toString() ?? '';
                    final String aboutText = item['about']?.toString() ?? '';
                    final String createdAt = item['created_at']?.toString() ?? '';
                    return Card(
                      color: Colors.white,
                      margin: EdgeInsets.all(0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(Icons.payments_outlined, color: Colors.blue, size: 28),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${_formatAmount(amount)} UZS',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        ),
                                      ),
                                      Text(
                                        type.toUpperCase(),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    aboutText,
                                    style: TextStyle(color: Colors.grey[700]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(admin, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text(createdAt, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDavomadCard() {
    final joriy = davomad?['joriy_oy'] as Map<String, dynamic>? ?? {};
    final otgan = davomad?['otgan_oy'] as Map<String, dynamic>? ?? {};
    return Card(
      elevation: 2,
      margin: EdgeInsets.all(0),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),side: BorderSide(color: Colors.blue)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: const Text('Davomad', style: TextStyle(fontWeight: FontWeight.bold))),
            Divider(
              thickness: 1,
              color: Colors.grey,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Joriy oy ish kuni:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                Text("${joriy['jami_ish_kuni']} kun",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400),)
              ],
            ),
            SizedBox(height: 4.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Formada keldi:"),
                Text("${joriy['formada_keldi']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Formasiz keldi:"),
                Text("${joriy['formasiz_keldi']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Kechikib keldi:"),
                Text("${joriy['kechikdi']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sababli, Ishga kelmadi:"),
                Text("${joriy['sababli']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sababsiz, Ishga kelmadi:"),
                Text("${joriy['kelmadi']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Kasal, Ishga kelmadi:"),
                Text("${joriy['kasal']} kun")
              ],
            ),
            Divider(
              thickness: 1,
              color: Colors.grey,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("O'tgan oy ish kuni:",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                Text("${otgan['jami_ish_kuni']} kun",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400),)
              ],
            ),
            SizedBox(height: 4.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Formada keldi:"),
                Text("${otgan['formada_keldi']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Formasiz keldi:"),
                Text("${otgan['formasiz_keldi']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Kechikib keldi:"),
                Text("${otgan['kechikdi']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sababli, Ishga kelmadi:"),
                Text("${otgan['sababli']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sababsiz, Ishga kelmadi:"),
                Text("${otgan['kelmadi']} kun")
              ],
            ),
            SizedBox(height: 2.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Kasal, Ishga kelmadi:"),
                Text("${otgan['kasal']} kun")
              ],
            ),
          ],
        ),
      ),
    );
  }
}
