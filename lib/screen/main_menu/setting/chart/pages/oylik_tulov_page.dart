import 'package:flutter/material.dart';
class OylikTulovPage extends StatefulWidget {
  const OylikTulovPage({super.key});

  @override
  State<OylikTulovPage> createState() => _OylikTulovPageState();
}

class _OylikTulovPageState extends State<OylikTulovPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Oylik tulovlar"),),
      body: Center(
        child: Text("Kutilmoqda..."),
      ),
    );
  }
}
