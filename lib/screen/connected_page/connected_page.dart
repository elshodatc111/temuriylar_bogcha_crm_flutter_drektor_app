import 'package:flutter/material.dart';
import '../../screen/splash_page/splash_page.dart';
class ConnectedPage extends StatefulWidget {
  const ConnectedPage({super.key});

  @override
  State<ConnectedPage> createState() => _ConnectedPageState();
}

class _ConnectedPageState extends State<ConnectedPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Internet yo\'q')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Internetga ulanilmadi. Iltimos, tarmoqni tekshiring.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Qayta sinash uchun SplashPage ga qaytish
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SplashPage()),
                );
              },
              child: const Text('Qayta sinash'),
            ),
          ],
        ),
      ),
    );
  }
}
