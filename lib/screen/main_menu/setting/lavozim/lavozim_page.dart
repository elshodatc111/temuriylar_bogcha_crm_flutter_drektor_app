import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class LavozimPage extends StatefulWidget {
  const LavozimPage({super.key});

  @override
  State<LavozimPage> createState() => _LavozimPageState();
}

class _LavozimPageState extends State<LavozimPage> {
  final GetStorage _storage = GetStorage();

  bool _isLoading = true;
  String _error = '';
  List<dynamic> _positions = [];

  @override
  void initState() {
    super.initState();
    _fetchPositions();
  }

  Future<void> _fetchPositions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final token = _storage.read('token');
    if (token == null || token.toString().isEmpty) {
      setState(() {
        _error = "Token topilmadi. Qayta login qiling!";
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse("${ApiConst.apiUrl}/get-position");

      final resp = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);

        setState(() {
          _positions = data["position"] ?? [];
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

  Future<void> _refresh() async => _fetchPositions();

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lavozimlar"),
      ),

      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primary),
            const SizedBox(height: 12),
            const Text("Ma'lumotlar yuklanmoqda..."),
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
              onPressed: _fetchPositions,
              icon: const Icon(Icons.refresh),
              label: const Text("Qayta urinish"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: _positions.length,
          itemBuilder: (ctx, i) {
            final item = _positions[i];

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.blue),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.work_outline,
                      color: primary, size: 24),
                ),
                title: Text(
                  item["name"].toString().toUpperCase(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primary),
                ),
                subtitle: Text(
                  item["category"] ?? "",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
