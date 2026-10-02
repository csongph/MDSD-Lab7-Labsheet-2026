// การทดสอบเริ่มต้น (Smoke Test) ของโปรเจกต์นี้
//
// หมายเหตุสำคัญ 2 ข้อ (ทำไมเทสนี้ไม่ pump MyApp() ตรง ๆ)
//
// 1) MyApp (ใน main.dart) อ้างอิง CartModel ผ่าน context.watch<CartModel>()
//    แต่ ChangeNotifierProvider<CartModel> ถูกครอบไว้ "นอก" MyApp ในฟังก์ชัน main()
//    เท่านั้น ไม่ได้อยู่ใน MyApp เอง ตอนเทส pumpWidget(MyApp()) จึงไม่มี Provider
//    ให้ widget หา เกิด ProviderNotFoundException ทันที ในเทสนี้จึงต้องครอบ
//    ChangeNotifierProvider ให้เองตรงนี้ด้วย
//
// 2) MyApp เปิดหน้าแรกด้วย HomePage(repository: ItemRepositoryApi()) ซึ่งเรียก
//    เครือข่ายจริงใน initState() แต่ Flutter จะดักจับ HttpClient ทุกตัวระหว่างรัน
//    widget test แล้วตอบกลับสถานะ 400 เสมอ (ไม่เรียกเครือข่ายจริง) ทำให้ได้ Exception
//    "สถานะ 400" ทุกครั้งโดยไม่เกี่ยวกับ API จริงเลย เทสนี้จึงใช้ repository ปลอม
//    (_FakeItemRepository) ที่ไม่เรียกเครือข่ายแทน เพื่อตรวจสถานะ "กำลังโหลด" ได้แน่นอน
//
// เรื่อง Widget Testing แบบเต็มรูปแบบ (รวมถึงการจำลอง Mock/Fake แบบนี้) จะเรียน
// ละเอียดในสัปดาห์ที่ 10

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_marketplace_w7/models/cart_model.dart';
import 'package:campus_marketplace_w7/models/item.dart';
import 'package:campus_marketplace_w7/repositories/item_repository.dart';
import 'package:campus_marketplace_w7/screens/home_page.dart';

/// Repository ปลอมสำหรับใช้ในการทดสอบนี้เท่านั้น ไม่เรียกเครือข่ายจริง
/// Future ที่คืนไปจะ "ค้าง" อยู่ตลอด (ไม่มีวัน complete) เพื่อให้ทดสอบจับสถานะ
/// "กำลังโหลด" (CircularProgressIndicator) ได้แน่นอนทุกครั้งที่รัน
class _FakeItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() {
    return Completer<List<Item>>().future;
  }
}

void main() {
  testWidgets('แอปเปิดขึ้นมาแสดงชื่อแอปและสถานะกำลังโหลดสินค้า', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          title: 'Campus Marketplace',
          home: HomePage(repository: _FakeItemRepository()),
        ),
      ),
    );

    // ยังไม่ pumpAndSettle เพราะ _FakeItemRepository.getItems() ไม่มีวัน complete
    // (ตั้งใจให้ค้างสถานะ "กำลังโหลด" ไว้) ต้องการแค่ตรวจสอบสถานะเริ่มต้นเท่านั้น
    expect(find.text('Campus Marketplace'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}