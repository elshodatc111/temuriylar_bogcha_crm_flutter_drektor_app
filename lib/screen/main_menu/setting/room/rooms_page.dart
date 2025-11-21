import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/room/create_room_page.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final GetStorage _storage = GetStorage();
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _rooms = [];

  int _deletingId = -1; // faqat bosilgan tugmani loading qilish uchun

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
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
      final uri = Uri.parse("${ApiConst.apiUrl}/rooms");

      final resp = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);

        setState(() {
          _rooms = body["rooms"] ?? [];
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

  Future<void> _refresh() async => _fetchRooms();

  /// ------------------------- XONA O‘CHIRISH FUNKSIYASI --------------------------
  Future<void> _deleteRoom(int id) async {
    final token = _storage.read("token");
    if (token == null) return;

    setState(() => _deletingId = id);

    try {
      final uri = Uri.parse("${ApiConst.apiUrl}/room-delete");

      final resp = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {"id": id.toString()},
      );

      if (resp.statusCode == 200) {
        Get.snackbar(
          "Muvaffaqiyat",
          "Xona o‘chirildi",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        await _fetchRooms();
      } else {
        Get.snackbar(
          "Xato",
          "Server xatosi: ${resp.statusCode}",
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.snackbar("Xato", "So‘rov xatosi: $e",
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800);
    }

    setState(() => _deletingId = -1);
  }

  /// ---------------------- O‘CHIRISH TASDIQLASH DIALOGI -------------------------
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("O‘chirish"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            side: BorderSide(color: Colors.black,width: 1.2)
          ),
          content: const Text("Rostdan ham ushbu xonani o‘chirmoqchimisiz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Bekor qilish"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // dialog yopiladi
                _deleteRoom(id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("O‘chirish",style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xonalar"),
        actions: [
          IconButton(
            onPressed: () async {
              final res = await Get.to(() => const CreateRoomPage());
              if (res == true) _fetchRooms();
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.black),
            const SizedBox(height: 12),
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
              onPressed: _fetchRooms,
              icon: const Icon(Icons.refresh),
              label: const Text("Qayta urinish"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            )
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: _rooms.length,
          itemBuilder: (ctx, i) {
            final room = _rooms[i];

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.meeting_room, color: Colors.blue, size: 26),
                ),

                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      room["name"] ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      room["created_at"] ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    )
                  ],
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Hajmi: ${room["size"]} m2",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Row(
                          children: [
                            Icon(Icons.person,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              room["user"] ?? "-",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room["about"] ?? "",
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),

                trailing: (_deletingId == room["id"])
                    ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.red,
                    strokeWidth: 2,
                  ),
                )
                    : IconButton(
                  onPressed: () => _confirmDelete(room["id"]),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
