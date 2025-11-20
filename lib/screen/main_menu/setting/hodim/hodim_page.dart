import 'package:flutter/material.dart';
class HodimPage extends StatefulWidget {
  const HodimPage({super.key});

  @override
  State<HodimPage> createState() => _HodimPageState();
}

class _HodimPageState extends State<HodimPage> with SingleTickerProviderStateMixin {
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
    return const Placeholder();
  }
}
