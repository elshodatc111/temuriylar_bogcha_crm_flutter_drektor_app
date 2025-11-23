import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/child/child_show_item/child_document_create_page.dart';

class ChildDocumentPage extends StatefulWidget {
  final int id;

  const ChildDocumentPage({super.key, required this.id});

  @override
  State<ChildDocumentPage> createState() => _ChildDocumentPageState();
}

class _ChildDocumentPageState extends State<ChildDocumentPage> {
  bool _loading = true;
  bool _error = false;
  String _errorText = '';
  List<Map<String, dynamic>>? _data;

  static String baseUrl = ApiConst.apiUrl;
  static String imageUrl = ApiConst.imageUrl;

  final box = GetStorage();

  // Set of document ids that are currently being deleted
  final Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchDocument();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = box.read('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchDocument() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/child-show-document/${widget.id}');
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);

        if (body['data'] != null) {
          final raw = body['data'];
          List<Map<String, dynamic>> listData = [];

          if (raw is List) {
            listData = List<Map<String, dynamic>>.from(
              raw.map((e) => Map<String, dynamic>.from(e)),
            );
          } else if (raw is Map) {
            listData = [Map<String, dynamic>.from(raw)];
          }

          setState(() {
            _data = listData;
            _loading = false;
          });
        } else {
          setState(() {
            _error = true;
            _errorText = body['message'] ?? "Ma'lumot topilmadi";
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = true;
          _errorText = "Server xatosi: ${res.statusCode}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = true;
        _errorText = "Tarmoq xatosi: $e";
        _loading = false;
      });
    }
  }

  String _fullUrl(String relative) {
    if (relative.startsWith('http')) return relative;
    return imageUrl + relative;
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("URL nusxalandi")));
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          side: BorderSide(color: Colors.blue, width: 1.2),
        ),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.all(0),
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    "To‘liq ko‘rish",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, thickness: 1),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image, size: 60)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(dynamic rawId) async {
    final int? docId = _normalizeId(rawId);
    if (docId == null) {
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          side: BorderSide(color: Colors.blue, width: 1.2),
        ),
        backgroundColor: Colors.white,
        title: const Text('Hujjatni o‘chirish'),
        content: const Text(
          'Siz rostdan ham ushbu hujjatni o‘chirmoqchimisiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ha, o‘chirish'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteDocument(docId);
    }
  }

  int? _normalizeId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    try {
      return (raw as num).toInt();
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteDocument(int docId) async {
    setState(() => _deletingIds.add(docId));
    try {
      final uri = Uri.parse('$baseUrl/child-show-document-delete');
      final headers = await _getHeaders();
      final Map<String, String> sendHeaders = Map.from(headers);
      sendHeaders['Content-Type'] = 'application/json';
      final body = json.encode({'id': docId});
      final res = await http
          .post(uri, headers: sendHeaders, body: body)
          .timeout(const Duration(seconds: 120));
      if (res.statusCode == 200) {
        Get.snackbar(
          'Muvaffaqiyat',
          "Bola hujjati o'chirildi.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        await _fetchDocument();
      } else {
        Get.snackbar(
          'Xatolik',
          "Serverga bog'lanishda xatolik.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Xatolik',
        "Serverga bog'lanishda xatolik.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() => _deletingIds.remove(docId));
    }
  }

  /*

 */
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(
              "Yangi hujjat qo'shish",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              final res = await Get.to(
                    () => ChildDocumentCreatePage(id: widget.id),
              );

              if (res == true) {
                _fetchDocument();
              }
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                )
              : _error
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(_errorText),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _fetchDocument,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Qayta urinish"),
                      ),
                    ],
                  ),
                )
              : _data == null || _data!.isEmpty
              ? const Center(child: Text("Hujjat topilmadi"))
              : RefreshIndicator(
                  onRefresh: _fetchDocument,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 0,
                    ),
                    itemCount: _data!.length,
                    itemBuilder: (ctx, index) {
                      final item = _data![index];
                      final full = _fullUrl(item['url'] ?? "");
                      final int? docId = _normalizeId(
                        item['id'] ?? item['document_id'],
                      );
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: Colors.blue,
                            width: 1.2,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: SizedBox(
                            width: 54,
                            child: GestureDetector(
                              onTap: () {
                                if (full.isNotEmpty) _showImage(full);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  full,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image, size: 36),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            (item['type']?.toString().toUpperCase() ?? '-'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['user_id']?.toString() ?? ''),
                              Text(item['created_at']?.toString() ?? ''),
                            ],
                          ),
                          trailing: docId == null
                              ? IconButton(
                                  onPressed: null,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                )
                              : (_deletingIds.contains(docId)
                                    ? const SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: () =>
                                            _confirmAndDelete(docId),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                      )),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
