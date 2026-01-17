import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/product_price.dart';
import 'package:poultry_accounting/domain/repositories/i_price_repository.dart';

class ProductPriceRepositoryImpl implements IPriceRepository {
  final db.AppDatabase database;

  ProductPriceRepositoryImpl(this.database);

  @override
  Future<List<ProductPrice>> getPricesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final query = database.select(database.productPrices)
      ..where((t) => t.date.equals(startOfDay));
    
    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  @override
  Future<ProductPrice?> getLatestPrice(int productId) async {
    final query = database.select(database.productPrices)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
      ..limit(1);
    
    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  @override
  Future<void> updatePrice(ProductPrice price) async {
    await database.into(database.productPrices).insertOnConflictUpdate(
      db.ProductPriceTableCompanion.insert(
        productId: price.productId,
        price: price.price,
        date: price.date,
      ),
    );
  }

  @override
  Future<void> updateMultiplePrices(List<ProductPrice> prices) async {
    await database.batch((batch) {
      for (final price in prices) {
        batch.insert(
          database.productPrices,
          db.ProductPriceTableCompanion.insert(
            productId: price.productId,
            price: price.price,
            date: price.date,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<List<ProductPrice>> getPriceHistory(int productId, DateTime start, DateTime end) async {
    final query = database.select(database.productPrices)
      ..where((t) => t.productId.equals(productId) & t.date.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)]);
    
    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  ProductPrice _mapToEntity(db.ProductPriceTable row) {
    return ProductPrice(
      id: row.id,
      productId: row.productId,
      price: row.price,
      date: row.date,
      createdAt: row.createdAt,
    );
  }
}
