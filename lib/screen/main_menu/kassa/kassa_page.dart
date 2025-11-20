import 'package:flutter/material.dart';
class KassaPage extends StatefulWidget {
  const KassaPage({super.key});

  @override
  State<KassaPage> createState() => _KassaPageState();
}

class _KassaPageState extends State<KassaPage> with SingleTickerProviderStateMixin {
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
      appBar: AppBar(
        title: Text("Kassa"),
        actions: [
          SizedBox(width: 8.0,)
        ],
      ),
    );
  }
}
