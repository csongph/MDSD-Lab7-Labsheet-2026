import 'package:flutter/foundation.dart';
import 'item.dart';

class CartModel extends ChangeNotifier {
  final List<Item> _items = [];

  List<Item> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.price);

  void add(Item item) {
    _items.add(item);
    notifyListeners();
  }

  void remove(Item item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}