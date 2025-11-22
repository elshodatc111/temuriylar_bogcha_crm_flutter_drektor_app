import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:temuriylar_crm_app_admin/const/api_const.dart';

class ChildDocumentCreatePage extends StatefulWidget {
  final int id;
  const ChildDocumentCreatePage({super.key, required this.id});
  @override
  State<ChildDocumentCreatePage> createState() => _ChildDocumentCreatePageState();
}

class _ChildDocumentCreatePageState extends State<ChildDocumentCreatePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  File? _pickedFile;
  bool _loading = false;

  static String baseUrl = ApiConst.apiUrl;
  final box = GetStorage();
  final List<String> _allowedExt = ['png', 'jpg'];
  final int _maxBytes = 4 * 1024 * 1024;
  final String _exampleLocalPath = '/mnt/data/f7ea008d-c498-402a-8acd-cbf058c205dd.png';
  final ImagePicker _imagePicker = ImagePicker();
  @override
  void initState() {
    super.initState();
    try {
      final f = File(_exampleLocalPath);
      if (f.existsSync()) _pickedFile = f;
    } catch (_) {}
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = box.read('token') ?? '';
    return {
      'Accept': 'application/json',
      if (token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? xfile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final int pickedSize = await xfile.length();
      if (pickedSize > _maxBytes) {
        Get.snackbar(
          "Xatolik",
          "Rasm xajmi 4MBdan katta. Kichikroq fayl tanlang.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final String ext = p.extension(xfile.path).replaceFirst('.', '').toLowerCase();
      if (!_allowedExt.contains(ext)) {
        Get.snackbar(
          "Xatolik",
          "Faqat JPG yoki PNG rasm yuklashingiz mumkin.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      setState(() => _pickedFile = File(xfile.path));
    } on PlatformException catch (e) {
      Get.snackbar(
        "Xatolik",
        "Galereyadan rasm olishda xatolik.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      Get.snackbar(
        "Xatolik",
        "Iltimos hujjat rasmini tanlang.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final Uri uri = Uri.parse('$baseUrl/child-create-document');
      final http.MultipartRequest request = http.MultipartRequest('POST', uri);
      final Map<String, String> headers = await _getHeaders();
      request.headers.addAll(headers);
      request.fields['child_id'] = widget.id.toString();
      request.fields['type'] = _selectedType ?? '';
      final String path = _pickedFile!.path;
      final String mimeType = lookupMimeType(path) ?? 'application/octet-stream';
      final List<String> parts = mimeType.split('/');
      final http.MultipartFile multipartFile = await http.MultipartFile.fromPath('file',path,contentType: MediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream'),
        filename: p.basename(path),
      );
      request.files.add(multipartFile);
      final http.StreamedResponse streamed = await request.send().timeout(const Duration(seconds: 120));
      final http.Response response = await http.Response.fromStream(streamed);
      if(response.statusCode==500){
        Get.snackbar(
          "Xatolik",
          "Rasm xajmi 3MBdan katta. Kichikroq hujjat rasmini tanlang.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      if (response.statusCode == 200) {
        Get.snackbar(
          "Movofaqiyatli",
          "Hujjat rasmi yuklandi.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 50), () => Navigator.of(context).pop(true));
        }
      }
    } on TimeoutException {
      Get.snackbar(
        "Xatolik",
        "So'rov vaqti tugadi qaytadan urinib ko'ring.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      if (mounted) Future.delayed(const Duration(milliseconds: 500), () => Navigator.of(context).pop(false));
    } catch (e, st) {
      Get.snackbar(
        "Xatolik",
        "So'rov vaqti tugadi qaytadan urinib ko'ring.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _previewWidget() {
    if (_pickedFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _pickedFile!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
        ),
      );
    }
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
        color: Colors.grey.shade100,
      ),
      child: const Icon(Icons.image, color: Colors.grey, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hujjat yuklash')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue,width: 1.2),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixIcon: const Icon(Icons.description,color: Colors.blue,),
                    labelText: 'Hujjat turi',
                  ),
                  menuMaxHeight: 150,
                  items: [
                    DropdownMenuItem(value: 'guvohnoma', child: Text('Bola guvohnomasi')),
                    DropdownMenuItem(value: 'passport', child: Text('Ota-onasi paspoti')),
                    DropdownMenuItem(value: 'gepatet', child: Text('Gepatet vaksina guvohnomasi')),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Iltimos hujjat turini tanlang' : null,
                  onChanged: (v) => setState(() => _selectedType = v),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _previewWidget(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_pickedFile != null ? p.basename(_pickedFile!.path) : 'Rasm tanlanmagan',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('Galeriyadan tanlang — JPG yoki PNG,\nmaksimal 3 MB dan oshmasin', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library, color: Colors.blue),
                            label: const Text(
                              'Galeriyadan tanlash',
                              style: TextStyle(color: Colors.blue),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.blue,width: 1.2)
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save,color: Colors.white,),
                  label: Text(_loading ? 'Yuklanmoqda...' : 'Saqlash', style: const TextStyle(fontSize: 16,color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
