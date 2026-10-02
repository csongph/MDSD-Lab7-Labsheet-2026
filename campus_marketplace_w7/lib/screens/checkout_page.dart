import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('ตะกร้าสินค้า')),
      body: cart.items.isEmpty
          ? const Center(child: Text('ยังไม่มีสินค้าในตะกร้า'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        leading: Image.network(
                          item.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                        title: Text(item.title),
                        subtitle: Text('${item.price} บาท'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => context.read<CartModel>().remove(item),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'รวมทั้งหมด: ${cart.totalPrice.toStringAsFixed(2)} บาท',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: cart.items.isEmpty ? null : () => cart.clear(),
                        child: const Text('ล้างตะกร้า'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}