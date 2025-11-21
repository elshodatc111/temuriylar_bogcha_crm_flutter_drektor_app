 import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../const/api_const.dart';
import './ish_haqi_page.dart';
import './password_update.dart';
import '../splash_page/splash_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final box = GetStorage();
  bool _isLoggingOut = false;
  final String baseUrl = ApiConst.apiUrl;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Future<void> _sendLogoutRequest(String? token) async {
    if (token == null || token.isEmpty) return;
    final uri = Uri.parse('$baseUrl/logout');
    try {
      http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).then((response) {}).catchError((err) {});
    } catch (e) {}
  }
  Future<void> _performLogoutAndNavigate() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    final token = box.read<String>('token');
    _sendLogoutRequest(token);
    try {
      await box.erase();
    } catch (e) {
      try {
        await box.remove('token');
        await box.remove('user');
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashPage()),(route) => false,);
  }
  @override
  Widget build(BuildContext context) {
    final user = box.read('user');
    final int id = user['id'];
    final String name = user != null && user is Map ? (user['name'] ?? ' ') : ' ';
    final String phone = user != null && user is Map ? (user['phone'] ?? ' ') : ' ';
    final String position = user != null && user is Map ? (user['position'] ?? ' ') : ' ';
    return  Scaffold(
      appBar: AppBar(
        title: Text("Profil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 44,
              child: Icon(Icons.person,color: Colors.white,size: 52,),
            ),
            SizedBox(height: 8.0,),
            Text("$name ($position)",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
            SizedBox(height: 2.0,),
            Text(phone),
            const SizedBox(height: 20),
            InkWell(onTap:(){Get.to(()=>PasswordUpdate(id: id, name: name));},child: _itemMenu("Parolni yangilash","Shaxsiy parolni yangilash")),
            InkWell(onTap:(){Get.to(()=>IshHaqiPage(id: id, name: name));},child: _itemMenu("Davomad, To'lovlar","Davomad, To'langan ish haqi")),
            Spacer(),
            _logoutItem(name: name, phone: phone),
          ],
        ),
      ),
    );
  }
  Widget _itemMenu(String title, String subtitle){
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8,horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.blue)
      ),
      child: ListTile(
        title: Text("$title",style: TextStyle(fontWeight: FontWeight.w500),),
        subtitle: Text("$subtitle"),
        trailing: Icon(Icons.chevron_right,color: Colors.blue,),
      ),
    );
  }

  Widget _logoutItem({required String name, required String phone}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: _isLoggingOut
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.red),
                  ),
                  SizedBox(width: 8),
                  Text('Chiqish...'),
                ],
              )
                  : const Text('Chiqish', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return Dialog(
                      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 180),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Hisobdan chiqish',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Hisobdan chiqishni xohlaysizmi?',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: const BorderSide(color: Colors.grey),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text("Bekor qilish", style: TextStyle(color: Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      "Ha",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
                if (confirmed == true) {
                  await _performLogoutAndNavigate();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
