import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../const/api_const.dart';
import '../../screen/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoAnimation;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final MaskTextInputFormatter _phoneMask = MaskTextInputFormatter(
    mask: "## ### ####",
    filter: {"#": RegExp(r"[0-9]")},
    type: MaskAutoCompletionType.lazy,
  );
  final String baseUrl = ApiConst.apiUrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final raw = _phoneMask.getUnmaskedText();
    if (raw.length != 9) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefon raqam to‘liq emas')),
      );
      return;
    }
    final String phoneForApi = "+998$raw";
    final String password = _passwordCtrl.text.trim();
    await GetStorage.init();
    final Uri uri = Uri.parse('$baseUrl/login');
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'phone': phoneForApi, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 401) {
        setState(() => _isLoading = false);
        Get.rawSnackbar(
          message: "Telefon raqam yoki parol noto‘g‘ri",
          backgroundColor: Colors.red,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
        );
      } else if (response.statusCode == 403) {
        setState(() => _isLoading = false);
        Get.rawSnackbar(
          message:
              "Siz tizimga kirishga bloklangansiz. Administrator bilan bog'laning.",
          backgroundColor: Colors.red,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
        );
      } else if (response.statusCode == 404) {
        setState(() => _isLoading = false);
        Get.rawSnackbar(
          message: "Tizimga kirishga sizga ruxsat berilmagan.",
          backgroundColor: Colors.red,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
        );
      } else if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final bool? status = body['status'] as bool?;
        final String? token = body['token'] as String?;
        if (body['user']['position'] == 'admin' || body['user']['position'] == 'direktor' || body['user']['position'] == 'metodist' || body['user']['position'] == 'meneger') {
          if (status == true && token != null && token.isNotEmpty) {
            final box = GetStorage();
            await box.write('token', token);
            if (body['user'] != null) {
              await box.write('user', body['user']);
            }
            if (!mounted) return;
            Get.rawSnackbar(
              message: "Tizimga muvaffaqiyatli kirdingiz",
              backgroundColor: Colors.green,
              margin: const EdgeInsets.all(12),
              borderRadius: 8,
              snackPosition: SnackPosition.TOP,
            );
            setState(() => _isLoading = false);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainPage()),
            );
            return;
          } else {
            setState(() => _isLoading = false);
            final errMsg = body['message'] ??
                'Login muvaffaqiyatsiz. Maʼlumotlarni tekshiring.';
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(errMsg)));
            return;
          }
        }else{
          setState(() => _isLoading = false);
          Get.rawSnackbar(
            message: "Bu tizimga kirishga sizga ruxsat berilmagan",
            backgroundColor: Colors.red,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
            snackPosition: SnackPosition.TOP,
          );
          return ;
        }
      } else {
        setState(() => _isLoading = false);
        String err = 'Server xatosi: ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            err = body['message'];
          }
        } catch (_) {}
        if (!mounted) return;
        Get.rawSnackbar(
          message: "$err",
          backgroundColor: Colors.red,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
    } on TimeoutException catch (_) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      Get.rawSnackbar(
        message: "So‘rov vaqti tugadi. Internet aloqasini tekshiring",
        backgroundColor: Colors.red,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        snackPosition: SnackPosition.TOP,
      );
      return;
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      Get.rawSnackbar(
        message: "Xatolik. Internetga ulanishni tekshiring.",
        backgroundColor: Colors.red,
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
  }

  String? _validatePhone(String? v) {
    final raw = _phoneMask.getUnmaskedText();
    if (raw.length != 9) {
      return "Telefon raqamni 90 123 4567 shaklida kiriting";
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return "Parol kiriting";
    if (v.length < 8) return "Parol kamida 8 ta belgi bo‘lsin";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 36.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 300),
                const SizedBox(height: 8),
                const Text(
                  "KIRISH",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.number,
                        validator: _validatePhone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _phoneMask,
                        ],
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 24.0, top: 0),
                            child: Text("+998",style: TextStyle(fontWeight: FontWeight.w600,color: Colors.grey,fontSize: 16,),),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 12,),
                          hintText: "90 123 4567",
                          labelText: "Telefon raqam",
                          filled: true,
                          focusColor: Colors.blue,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: const BorderSide(color: Colors.blue,width: 2.5),),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: const BorderSide(color: Colors.blue,width: 0.5),),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: const BorderSide(color: Colors.blue),),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: "Parol kiriting",
                          labelText: "Parol",
                          filled: true,
                          fillColor: Colors.grey[100],
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword? Icons.visibility_off: Icons.visibility,),
                            onPressed: () => setState(() {_obscurePassword = !_obscurePassword;}),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: const BorderSide(color: Colors.transparent,),),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: const BorderSide(color: Colors.blue,width: 0.5),),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: const BorderSide(color: Colors.blue),),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.blue,
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  "Kirish",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
