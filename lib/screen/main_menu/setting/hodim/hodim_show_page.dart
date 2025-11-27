import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/hodim_ish_haqi_tolov_meneger.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/hodim_ish_haqi_tulov_admin.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/hodim/hodim_update_page.dart';

final String baseUrl = ApiConst.apiUrl;

class HodimShowPage extends StatefulWidget {
  final int id;

  const HodimShowPage({super.key, required this.id});

  @override
  State<HodimShowPage> createState() => _HodimShowPageState();
}

class _HodimShowPageState extends State<HodimShowPage> {
  final GetStorage _storage = GetStorage();
  String? _token;

  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _about;
  List<PaymartItem> _paymarts = [];
  Map<String, dynamic>? _davomad;
  bool _isUpdatingPassword = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    final t = _storage.read('token');
    if (t != null && t is String && t.trim().isNotEmpty) {
      _token = t.trim();
    }
    _fetchAll();
  }

  Future<void> _fetchAll() async {
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
      final uri = Uri.parse('$baseUrl/emploes-show/${widget.id}');
      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);

        final about = body['about'] as Map<String, dynamic>?;
        final paymart = body['paymart'] as List<dynamic>?;
        final davomad = body['davomad'] as Map<String, dynamic>?;

        setState(() {
          _about = about;
          _davomad = davomad;
          _paymarts = (paymart ?? []).map((e) {
            if (e is Map<String, dynamic>) return PaymartItem.fromJson(e);
            return PaymartItem.fromJson(Map<String, dynamic>.from(e));
          }).toList();
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
        });
      }
    } catch (e) {
      setState(() {
        _error = 'So‘rovda xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async => _fetchAll();

  String formatNumber(int number) {
    String s = number.toString();
    StringBuffer buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write(' ');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  /// POST to update password. Body contains id (string).
  Future<void> _updatePassword() async {
    if (_isUpdatingPassword) return;
    if (_token == null || _token!.isEmpty) {
      Get.snackbar(
        'Xato',
        'Token topilmadi. Iltimos qayta login qiling.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      final uri = Uri.parse('$baseUrl/emploes-update-password');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'id': widget.id.toString()},
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        String message = 'Parol yangilandi.';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) message = b['message'].toString();
        } catch (_) {}
        if (mounted) {
          Get.snackbar(
            'Muvaffaqiyat',
            message,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          await _fetchAll();
        }
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) msg = b['message'].toString();
        } catch (_) {}
        if (mounted) {
          Get.snackbar(
            'Xato',
            msg,
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade700,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Xato',
          'So‘rov xatosi: $e',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _updateStatus() async {
    if (_isUpdatingStatus) return;
    if (_token == null || _token!.isEmpty) {
      Get.snackbar(
        'Xato',
        'Token topilmadi. Iltimos qayta login qiling.',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    setState(() => _isUpdatingStatus = true);

    try {
      final uri = Uri.parse('$baseUrl/emploes-update-status');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
        body: {'id': widget.id.toString()},
      );

      if (resp.statusCode == 200) {
        String message = 'Ishdan bo\'shatildi.';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) message = b['message'].toString();
        } catch (_) {}
        if (mounted) {
          Get.snackbar(
            'Muvaffaqiyat',
            "Hodim ishdan bo'shatildi.",
            backgroundColor: Colors.red.shade600,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          await _fetchAll();
        }
      } else {
        String msg = 'Server xatosi: ${resp.statusCode}';
        try {
          final Map<String, dynamic> b = json.decode(resp.body);
          if (b.containsKey('message')) msg = b['message'].toString();
        } catch (_) {}
        if (mounted) {
          Get.snackbar(
            'Xato',
            msg,
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade700,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Xato',
          'So‘rov xatosi: $e',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue.shade700;
    final user = _storage.read('user');
    final String lavozim = (user != null && user is Map && user.containsKey('position'))? '${user['position']}': '';

    return Scaffold(
      appBar: AppBar(title: const Text('Hodim haqida'),actions: [
        IconButton(onPressed: () async {
          dynamic result;
          if (lavozim == 'direktor' || lavozim == 'admin' || lavozim == 'metodist') {
            result = await Get.to(() => HodimUpdatePage(id: _about!['id'],),);
          }
          if (result == true) {
            await _fetchAll();
          }
        }, icon: Icon(Icons.edit_note_outlined,size: 28,)),
        SizedBox(width: 8,)
      ],),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: _isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(child: CircularProgressIndicator(color: primary)),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "Ma'lumotlar yuklanmoqda...",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(height: 200),
                  ],
                )
              : _error.isNotEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _fetchAll,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Qayta yuklash'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 200),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _itemAbout(),
                      const SizedBox(height: 8.0),
                      _about!['status']
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isUpdatingPassword
                                        ? null
                                        : () async {
                                            await _updatePassword();
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _isUpdatingPassword
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.lock_reset,
                                                color: Colors.white,
                                              ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Parolni\nyangilash",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      dynamic result;
                                      if (lavozim == 'direktor' ||
                                          lavozim == 'admin') {
                                        result = await Get.to(
                                          () => HodimIshHaqiTulovAdmin(id: widget.id,),
                                        );
                                      } else {
                                        result = await Get.to(
                                          () => HodimIshHaqiTolovMeneger(),
                                        );
                                      }
                                      // Per your earlier code, check result and refresh if needed.
                                      if (result == true) {
                                        await _fetchAll();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.payments_outlined,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Ish haqi\nto'lash",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                lavozim=="direktor"?const SizedBox(width: 8):lavozim=="admin"?const SizedBox(width: 8):SizedBox(),
                                lavozim=="direktor"?Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isUpdatingStatus
                                        ? null
                                        : () async {
                                            // Confirm action? (optional) - here we proceed directly
                                            final confirm = await Get.dialog<bool>(
                                              AlertDialog(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(8.0),
                                                      ),
                                                  side: BorderSide(
                                                    color: Colors.blue,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                title: Text(
                                                  'Hodimni ishdan bo\'shatishni tasdiqlaysizmi?',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                content: const Text(
                                                  'Ishdan bo\'shatilgan hodimni malumotlarini qayta tiklab bo\'lmaydi.',
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed: () => Get.back(result: false),
                                                    child: const Text(
                                                      'Bekor qilish',
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Get.back(result: true),
                                                    child: const Text(
                                                      'Tasdiqlash',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await _updateStatus();
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _isUpdatingStatus
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.person_remove_alt_1,
                                                color: Colors.white,
                                              ),
                                        const SizedBox(height: 4),
                                        const Text("Ishdan\nbo'shatish",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ):lavozim=="admin"?Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isUpdatingStatus
                                        ? null
                                        : () async {
                                      final confirm = await Get.dialog<bool>(
                                        AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.all(
                                              Radius.circular(8.0),
                                            ),
                                            side: BorderSide(
                                              color: Colors.blue,
                                              width: 1.0,
                                            ),
                                          ),
                                          title: Text(
                                            'Hodimni ishdan bo\'shatishni tasdiqlaysizmi?',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          content: const Text(
                                            'Ishdan bo\'shatilgan hodimni malumotlarini qayta tiklab bo\'lmaydi.',
                                          ),
                                          actions: [
                                            ElevatedButton(
                                              onPressed: () => Get.back(result: false),
                                              child: const Text(
                                                'Bekor qilish',
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Get.back(result: true),
                                              child: const Text(
                                                'Tasdiqlash',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _updateStatus();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _isUpdatingStatus
                                            ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                            : const Icon(
                                          Icons.person_remove_alt_1,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text("Ishdan\nbo'shatish",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ):SizedBox(),
                              ],
                            )
                          : lavozim=="direktor"?SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUpdatingStatus
                              ? null
                              : () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                  side: BorderSide(
                                    color: Colors.blue,
                                    width: 1.0,
                                  ),
                                ),
                                title: Text(
                                  'Hodimni ishga qaytarib olishni tasdiqlaysizmi?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Get.back(result: false),
                                    child: const Text(
                                      'Bekor qilish',
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Get.back(result: true),
                                    child: const Text(
                                      'Tasdiqlash',
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _updateStatus();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isUpdatingStatus
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons.person_remove_alt_1,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text("Ishga qaytarib olish",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ):lavozim=="admin"?Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdatingStatus
                              ? null
                              : () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                  side: BorderSide(
                                    color: Colors.blue,
                                    width: 1.0,
                                  ),
                                ),
                                title: Text(
                                  'Hodimni ishga qaytarib olishni tasdiqlaysizmi?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () => Get.back(result: false),
                                    child: const Text(
                                      'Bekor qilish',
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Get.back(result: true),
                                    child: const Text(
                                      'Tasdiqlash',
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _updateStatus();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isUpdatingStatus
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons.person_remove_alt_1,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text("Ishga qaytarib olish",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ):SizedBox(),
                      SizedBox(height: 8.0),
                      _buildDavomadCard(_davomad),
                      const SizedBox(height: 8.0),
                      const Text(
                        "Ish haqi to'lovlari",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      _paymartss(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _paymartss() {
    return Expanded(
      child: ListView.builder(
        itemCount: _paymarts.length,
        itemBuilder: (ctx, index) {
          final pay = _paymarts[index];
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              side: BorderSide(color: Colors.blue, width: 0.5),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                '${formatNumber(pay.amount)} UZS',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((pay.about ?? '').isNotEmpty)
                    Text(
                      pay.about ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          pay.adminId ?? '-',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    pay.type != null && pay.type!.isNotEmpty ? pay.type! : '-',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pay.createdAt ?? '-',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _itemAbout() {
    return Card(
      margin: const EdgeInsets.all(0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(
          color: _about!['status'] ? Colors.blue : Colors.red,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: Colors.blue),
                    const SizedBox(width: 4.0),
                    Text(
                      _about!['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 20, color: Colors.blue),
                    const SizedBox(width: 4.0),
                    Text(
                      _about!['seriya'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.grey.shade300, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text("Telefon raqam"), Text(_about!['phone'])],
            ),
            const SizedBox(height: 2.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text("Manzil"), Text(_about!['address'])],
            ),
            const SizedBox(height: 2.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text("Tug'ilgan kuni:"), Text(_about!['tkun'])],
            ),
            const SizedBox(height: 2.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ish haqi:"),
                Text("${formatNumber(_about!['salary'])} UZS"),
              ],
            ),
            const SizedBox(height: 2.0),
            Text(_about!['about']),
          ],
        ),
      ),
    );
  }

  Widget _buildDavomadCard(Map<String, dynamic>? davomad) {
    final j = (davomad?['joriy_oy'] as Map<String, dynamic>?) ?? {};
    final o = (davomad?['otgan_oy'] as Map<String, dynamic>?) ?? {};
    int jamiJoriy = (j['jami_ish_kuni'] is int)
        ? j['jami_ish_kuni']
        : int.tryParse('${j['jami_ish_kuni']}') ?? 0;
    int formadaJoriy = (j['formada_keldi'] is int)
        ? j['formada_keldi']
        : int.tryParse('${j['formada_keldi']}') ?? 0;
    int formasizJoriy = (j['formasiz_keldi'] is int)
        ? j['formasiz_keldi']
        : int.tryParse('${j['formasiz_keldi']}') ?? 0;
    int kelmadiJoriy = (j['kelmadi'] is int)
        ? j['kelmadi']
        : int.tryParse('${j['kelmadi']}') ?? 0;
    int kechikdiJoriy = (j['kechikdi'] is int)
        ? j['kechikdi']
        : int.tryParse('${j['kechikdi']}') ?? 0;
    int kasalJoriy = (j['kasal'] is int)
        ? j['kasal']
        : int.tryParse('${j['kasal']}') ?? 0;
    int sababliJoriy = (j['sababli'] is int)
        ? j['sababli']
        : int.tryParse('${j['sababli']}') ?? 0;

    int jamiOtgan = (o['jami_ish_kuni'] is int)
        ? o['jami_ish_kuni']
        : int.tryParse('${o['jami_ish_kuni']}') ?? 0;
    int formadaOtgan = (o['formada_keldi'] is int)
        ? o['formada_keldi']
        : int.tryParse('${o['formada_keldi']}') ?? 0;
    int formasizOtgan = (o['formasiz_keldi'] is int)
        ? o['formasiz_keldi']
        : int.tryParse('${o['formasiz_keldi']}') ?? 0;
    int kelmadiOtgan = (o['kelmadi'] is int)
        ? o['kelmadi']
        : int.tryParse('${o['kelmadi']}') ?? 0;
    int kechikdiOtgan = (o['kechikdi'] is int)
        ? o['kechikdi']
        : int.tryParse('${o['kechikdi']}') ?? 0;
    int kasalOtgan = (o['kasal'] is int)
        ? o['kasal']
        : int.tryParse('${o['kasal']}') ?? 0;
    int sababliOtgan = (o['sababli'] is int)
        ? o['sababli']
        : int.tryParse('${o['sababli']}') ?? 0;
    final primary = Colors.blue.shade700;
    return Card(
      margin: const EdgeInsets.all(0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.blue, width: 1),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: primary),
                const SizedBox(width: 8),
                const Text(
                  "Hodim davomadi",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joriy oy',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _singleStat('Jami ish kuni:', '$jamiJoriy'),
                      _singleStat('Formada keldi:', '$formadaJoriy'),
                      _singleStat('Formasiz keldi:', '$formasizJoriy'),
                      _singleStat('Kechikib keldi:', '$kechikdiJoriy'),
                      _singleStat('Kasal kelmadi:', '$kasalJoriy'),
                      _singleStat('Sababli kelmadi:', '$sababliJoriy'),
                      _singleStat('Sababsiz kelmadi:', '$kelmadiJoriy'),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(width: 2, height: 162, color: Colors.blue),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'O\'tgan oy',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _singleStat('Jami ish kuni', '$jamiOtgan'),
                      _singleStat('Formada keldi', '$formadaOtgan'),
                      _singleStat('Formasiz keldi', '$formasizOtgan'),
                      _singleStat('Kechikib keldi:', '$kechikdiOtgan'),
                      _singleStat('Kasal kelmadi:', '$kasalOtgan'),
                      _singleStat('Sababli kelmadi:', '$sababliOtgan'),
                      _singleStat('Sababsiz kelmadi:', '$kelmadiOtgan'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _singleStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            "$value kun",
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

/// Paymart model
class PaymartItem {
  final int id;
  final String? adminId;
  final int amount;
  final String? type;
  final String? about;
  final String? createdAt;

  PaymartItem({
    required this.id,
    this.adminId,
    required this.amount,
    this.type,
    this.about,
    this.createdAt,
  });

  factory PaymartItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return PaymartItem(
      id: parseInt(json['id']),
      adminId: json['admin_id']?.toString(),
      amount: parseInt(json['amount']),
      type: json['type']?.toString(),
      about: json['about']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
