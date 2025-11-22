import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_qarindosh_create_page.dart';

class ChildQarindoshlarPage extends StatefulWidget {
  final int id;

  const ChildQarindoshlarPage({super.key, required this.id});

  @override
  State<ChildQarindoshlarPage> createState() => _ChildQarindoshlarPageState();
}

class _ChildQarindoshlarPageState extends State<ChildQarindoshlarPage> {
  bool _loading = true;
  bool _error = false;
  String _errorText = '';
  List<dynamic> _items = [];

  final box = GetStorage();
  static final String baseUrl = ApiConst.apiUrl;

  // Track which item ids are currently deleting
  final Set<dynamic> _deletingIds = {};

  // placeholder image path from uploaded file (developer instruction)
  final String _placeholderImagePath =
      '/mnt/data/eefbd720-7663-489b-9a50-76c843ffba7f.png';

  @override
  void initState() {
    super.initState();
    _fetchList();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = box.read('token') ?? '';
    final Map<String, String> headers = {'Accept': 'application/json'};
    if (token.toString().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> _fetchList() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorText = '';
    });

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/child-show-qarindosh/${widget.id}');
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body['data'];
        if (data is List) {
          setState(() {
            _items = data;
            _loading = false;
          });
        } else {
          setState(() {
            _items = [];
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = true;
          _errorText = 'Server xatosi: ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = true;
        _errorText = 'Tarmoq xatosi: $e';
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchList();
  }

  Future<void> _deleteItem(dynamic itemId) async {
    if (_deletingIds.contains(itemId)) return;

    setState(() {
      _deletingIds.add(itemId);
    });

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/child-show-qarindosh-delete');
      final body = {'id': itemId.toString()};

      final res = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 120));

      if (res.statusCode == 200 || res.statusCode == 204) {
        try {
          final js = json.decode(res.body);
          final msg = (js is Map && js['message'] != null) ? js['message'].toString() : 'O‘chirildi';
          Get.snackbar(
            'Muvaffaqiyat',
            msg,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
          );
        } catch (_) {
          Get.snackbar(
            'Muvaffaqiyat',
            'Element o‘chirildi',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
          );
        }

        await _fetchList();
      } else {
        String msg = 'Server xatosi: ${res.statusCode}';
        try {
          final js = json.decode(res.body);
          if (js is Map && js['message'] != null) msg = js['message'].toString();
        } catch (_) {}
        Get.snackbar(
          'Xatolik',
          msg,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
        );
      }
    } on TimeoutException {
      Get.snackbar(
        'Xatolik',
        'Soʻrov vaqti tugadi — keyinroq qayta urinib koʻring.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
    } catch (e) {
      Get.snackbar(
        'Xatolik',
        'So‘rov yuborishda xatolik: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
    } finally {
      setState(() {
        _deletingIds.remove(itemId);
      });
    }
  }

  Widget _leadingThumbnail(Map<String, dynamic> item) {
    final f = File(_placeholderImagePath);
    if (f.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          f,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.person_outline, size: 36),
        ),
      );
    } else {
      return const Icon(Icons.person_outline, size: 36);
    }
  }

  /// Build a tel: Uri from various phone formats.
  /// Returns null if phone seems empty/invalid.
  Uri? _buildTelUri(String raw) {
    final str = raw.trim();
    if (str.isEmpty) return null;

    // keep digits and leading plus only
    String cleaned = str.replaceAll(RegExp(r'[^0-9+]'), '');

    // If starts with '+' then ensure it has digits after it
    if (cleaned.startsWith('+')) {
      final afterPlus = cleaned.substring(1);
      if (afterPlus.isEmpty) return null;
      // normalize common Uzbekistan cases: if +998 then ok
      return Uri(scheme: 'tel', path: cleaned);
    }

    // If numbers only:
    String digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

    // Common Uzbek local formats:
    // 9 digits (e.g., 901234567) -> +998901234567
    if (digits.length == 9) {
      return Uri(scheme: 'tel', path: '+998$digits');
    }

    // 10 digits starting with 0 (e.g., 0901234567) -> drop leading 0 -> +998901234567
    if (digits.length == 10 && digits.startsWith('0')) {
      final local = digits.substring(1);
      return Uri(scheme: 'tel', path: '+998$local');
    }

    // 12 digits starting with 998 -> +998...
    if (digits.length == 12 && digits.startsWith('998')) {
      return Uri(scheme: 'tel', path: '+$digits');
    }

    // Fallback: if there are digits, use them directly (may or may not work)
    if (digits.isNotEmpty) {
      return Uri(scheme: 'tel', path: digits);
    }

    return null;
  }

  Future<void> _callPhone(String phone) async {
    final uri = _buildTelUri(phone);
    if (uri == null) {
      Get.snackbar(
        'Xatolik',
        'Telefon raqam noto‘g‘ri: $phone',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      // Optional: check if device can handle tel:
      final can = await canLaunchUrl(uri);
      if (!can) {
        Get.snackbar(
          'Xatolik',
          'Ushbu qurilma telefon qo‘ng‘iroqlarini ishga tushira olmaydi.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        Get.snackbar(
          'Xatolik',
          'Qo‘ng‘iroqni amalga oshirib bo‘lmadi.',
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Xatolik',
        'Qo‘ng‘iroqni amalga oshirishda xato: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolaning qarindoshlari'),
        actions: [
          IconButton(
            onPressed: () async {
              final res = await Get.to(() => ChildQarindoshCreatePage(id: widget.id));
              if (res == true) _fetchList();
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(_errorText, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchList,
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta urinib ko‘rish'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _onRefresh,
        child: _items.isEmpty
            ? const Center(child: Text("Qarindosh topilmadi"))
            : ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _items[index];
            final itemId = item['id'] ?? item['child_rel_id'] ?? item['qarindosh_id'] ?? item;

            return Card(
              color: Colors.white,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.blue),
              ),
              elevation: 2,
              child: ListTile(
                leading: SizedBox(
                  width: 44,
                  height: 44,
                  child: _deletingIds.contains(itemId)
                      ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                            side: BorderSide(color: Colors.blue, width: 1.2),
                          ),
                          title: const Text('O‘chirishni tasdiqlash'),
                          content: const Text('Rostdan ham bu qarindoshni o‘chirmoqchimisiz?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Bekor qilish')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ha, O\'chirish')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deleteItem(itemId);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${item['name'] ?? '-'}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${item['phone'] ?? ''}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(child: Text(item['address'] ?? '', style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.help_center_outlined, size: 14, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(child: Text(item['about'] ?? '', style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () {
                    final phone = item['phone'] ?? '';
                    if (phone.toString().isNotEmpty) {
                      _callPhone(phone.toString());
                    } else {
                      Get.snackbar(
                        'Xatolik',
                        'Telefon raqam mavjud emas',
                        backgroundColor: Colors.red.shade700,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                      );
                    }
                  },
                  icon: const Icon(Icons.phone, color: Colors.blue),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
