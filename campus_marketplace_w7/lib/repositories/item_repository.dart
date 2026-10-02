import '../models/item.dart';

abstract class ItemRepository {
  Future<List<Item>> getItems();
}