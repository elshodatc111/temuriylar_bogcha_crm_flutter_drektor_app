import 'package:flutter/material.dart';
class HodimShowPage extends StatefulWidget {
  final int id;
  const HodimShowPage({super.key, required this.id});

  @override
  State<HodimShowPage> createState() => _HodimShowPageState();
}

class _HodimShowPageState extends State<HodimShowPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}
