import 'package:flutter/material.dart';
class TkunPage extends StatefulWidget {
  const TkunPage({super.key});

  @override
  State<TkunPage> createState() => _TkunPageState();
}

class _TkunPageState extends State<TkunPage> with SingleTickerProviderStateMixin {
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
        title: Text("Yaqinlashayotgan tug'ilgan kunlar"),
      ),
    );
  }
}
