import 'package:flutter/material.dart';
class ChildDeletPage extends StatefulWidget {
  final List<dynamic> active_child;
  const ChildDeletPage({super.key, required this.active_child});

  @override
  State<ChildDeletPage> createState() => _ChildDeletPageState();
}

class _ChildDeletPageState extends State<ChildDeletPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guruhdan bola o'chirish"),
      ),
    );
  }
}
