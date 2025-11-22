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
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.image),
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
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bola hujjatlari"),actions: [
        IconButton(onPressed: () async {
          final res = await Get.to(() => ChildDocumentCreatePage(id: widget.id));
          if (res == true) _fetchDocument();
        }, icon: Icon(Icons.add_circle_outline)),
        SizedBox(width: 1.2,)
      ],),

      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
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
                  horizontal: 12,
                ),
                itemCount: _data!.length,
                itemBuilder: (ctx, index) {
                  final item = _data![index];
                  final full = _fullUrl(item['url'] ?? "");
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.blue, width: 1.2),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['user_id']),
                          Text(item['created_at']),
                        ],
                      ),
                      trailing: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
