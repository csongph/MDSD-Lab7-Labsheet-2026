import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing_draft.dart';
import '../services/gemini_vision_service.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  // ── Prompt สำหรับส่วนที่ 6: เปลี่ยนข้อความระหว่าง ''' กับ ''' เพื่อทดสอบ AI Safety ──
  // หลังทดสอบแล้ว ให้เปลี่ยนกลับเป็น Prompt เดิมทุกครั้ง
  static const String _prompt = '''
คุณคือผู้ช่วยวิเคราะห์ภาพสินค้าออนไลน์
อ่านภาพสินค้าอย่างละเอียด แล้วให้ผลลัพธ์เป็น JSON เท่านั้น
โดยมีโครงสร้างดังนี้:
{
  "title": "ชื่อสินค้า",
  "category": "ประเภทสินค้า",
  "description": "คำอธิบายสั้น ๆ ของสินค้า"
}

กติกาให้ปฏิบัติตามดังนี้:
1. title ต้องเป็นชื่อสินค้าที่เหมาะสมและสั้น กระชับ
2. category ต้องเป็นประเภทสินค้า เช่น เสื้อผ้า, เครื่องใช้ไฟฟ้า, อุปกรณ์กีฬา, หนังสือ, ของใช้ภายในบ้าน, เครื่องประดับ, อื่น ๆ
3. description ต้องเขียนเป็นข้อความที่อธิบายสินค้าแบบเป็นกันเองและสั้น ๆ
4. ตอบเฉพาะ JSON เท่านั้น ห้ามมีคำอธิบายเพิ่มเติม ไม่ต้องมี ```json
''';

  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      return;
    }

    final imageBytes = await pickedFile.readAsBytes();

    setState(() {
      _selectedImageBytes = imageBytes;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> analyzeProductImage() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้าก่อน')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });

    try {
      final draft = await GeminiVisionService().analyzeProductImage(
        _selectedImageBytes!,
        _prompt,
      );

      _titleController.text = draft.title;
      _categoryController.text = draft.category;
      _descriptionController.text = draft.description;

      setState(() {
        _isAnalyzing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI วิเคราะห์ภาพสินค้าเรียบร้อยแล้ว')),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  void _confirmListing() {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || category.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทุกช่องก่อนยืนยัน')),
      );
      return;
    }

    // ร่างประกาศฉบับสุดท้ายที่ผู้ใช้ตรวจทานและยืนยันแล้ว
    // (ยังไม่บันทึกถาวร – รอ Local Database สัปดาห์ที่ 8)
    // ignore: unused_local_variable
    final finalDraft = ListingDraft(
      title: title,
      category: category,
      description: description,
    );

    setState(() {
      _selectedImageBytes = null;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงประกาศขาย')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedImageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _selectedImageBytes!,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, size: 72, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : analyzeProductImage,
              icon: _isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.smart_toy_outlined),
              label: Text(
                _isAnalyzing
                    ? 'AI กำลังวิเคราะห์ภาพสินค้า...'
                    : 'ให้ AI ช่วยแนะนำ',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ข้อมูลร่างประกาศ (ตรวจทานและแก้ไขก่อนยืนยัน)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อประกาศ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'คำบรรยาย',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _confirmListing,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('ยืนยันร่างประกาศ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
