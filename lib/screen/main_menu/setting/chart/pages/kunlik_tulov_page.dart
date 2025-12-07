import 'package:flutter/material.dart';
class KunlikTulovPage extends StatefulWidget {
  const KunlikTulovPage({super.key});

  @override
  State<KunlikTulovPage> createState() => _KunlikTulovPageState();
}

class _KunlikTulovPageState extends State<KunlikTulovPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kunlik to'lovlar"),),
      body: Center(
        child: Text("Kutilmoqda..."),
      ),
    );
  }
}
