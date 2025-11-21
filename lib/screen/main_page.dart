import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:temuriylar_crm_app_admin/screen/main_menu/setting/setting_page.dart';
import '../../../../../screen/main_menu/child/child_page.dart';
import '../../../../../screen/main_menu/group/group_page.dart';
import '../../../../../screen/main_menu/kassa/kassa_page.dart';
import '../../../../../screen/profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    ChildPage(),
    GroupPage(),
    KassaPage(),
    SettingPage(),
  ];
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

  void _onTap(int idx) {
    setState(() {
      _currentIndex = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Colors.blue;
    const TextStyle labelStyle = TextStyle(fontSize: 12, color: Colors.white);

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 70,
        backgroundColor: Colors.transparent,
        color: primary,
        buttonBackgroundColor: Colors.blue,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: _onTap,
        items: <CurvedNavigationBarItem>[
          CurvedNavigationBarItem(
            child: const Icon(Icons.child_care_outlined, size: 22, color: Colors.white),
            label: 'Bolalar',
            labelStyle: labelStyle,
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.group_outlined, size: 22, color: Colors.white),
            label: 'Guruhlar',
            labelStyle: labelStyle,
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.account_balance_wallet_outlined, size: 22, color: Colors.white),
            label: 'Kassa',
            labelStyle: labelStyle,
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.settings_outlined, size: 22, color: Colors.white),
            label: 'Sozlamalar',
            labelStyle: labelStyle,
          ),
        ],
      ),
    );
  }
}
