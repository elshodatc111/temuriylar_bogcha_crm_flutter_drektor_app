import 'package:flutter/material.dart';
class MoliyaChartPage extends StatefulWidget {
  const MoliyaChartPage({super.key});

  @override
  State<MoliyaChartPage> createState() => _MoliyaChartPageState();
}

class _MoliyaChartPageState extends State<MoliyaChartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Moliya Statistikasi"),
      ),
      body: Center(
        child: Text("Kutilmoqda..."),
      ),
    );
  }
}
