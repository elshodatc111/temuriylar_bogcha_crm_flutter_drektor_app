import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_storage/get_storage.dart';
import '../../../const/api_const.dart';
import '../connected_page/connected_page.dart';
import '../login_page/login_page.dart';
import '../main_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _start();
  }
  Future<void> _start() async {
    _controller.forward();
    await GetStorage.init();
    await Future.delayed(const Duration(milliseconds: 700));
    await _checkAndNavigate();
  }
  Future<void> _checkAndNavigate() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _goToConnectedPage();
      return;
    }
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        _goToConnectedPage();
        return;
      }
    } on SocketException catch (_) {
      _goToConnectedPage();
      return;
    } on TimeoutException catch (_) {
      _goToConnectedPage();
      return;
    } catch (_) {
      _goToConnectedPage();
      return;
    }
    final box = GetStorage();
    final token = box.read<String>('token');

    if (token == null || token.isEmpty) {
      _goToLoginPage();
      return;
    }
    final uri = Uri.parse('${ApiConst.apiUrl}/check-token');

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        _goToMainPage();
      } else {
        _goToLoginPage();
      }
    } on SocketException catch (_) {
      _goToConnectedPage();
    } on TimeoutException catch (_) {
      _goToLoginPage();
    } catch (e) {
      _goToLoginPage();
    }
  }

  void _goToConnectedPage() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ConnectedPage()),
    );
  }

  void _goToLoginPage() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _goToMainPage() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Oddiy responsive layout
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                // Loading indicator
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

