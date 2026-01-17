import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/product.dart';
import 'package:poultry_accounting/domain/repositories/product_repository.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';

class ProductRepositoryImpl implements ProductRepository {
  final db.AppDatabase database;

  ProductRepositoryImpl(this.database);

  @override
  Future<List<Product>> getAllProducts() async {
    final rows = await database.select(database.products).get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<Product?> getProductById(int id) async {
    final query = database.select(database.products)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<int> createProduct(Product product) async {
    return await database.into(database.products).insert(
      db.ProductTableCompanion.insert(
        name: product.name,
        unitType: product.unitType.code,
        isWeighted: Value(product.isWeighted),
        defaultPrice: Value(product.defaultPrice),
        description: Value(product.description),
      ),
    );
  }

  @override
  Future<void> updateProduct(Product product) async {
    await (database.update(database.products)..where((t) => t.id.equals(product.id!))).write(
      db.ProductTableCompanion(
        name: Value(product.name),
        unitType: Value(product.unitType.code),
        isWeighted: Value(product.isWeighted),
        defaultPrice: Value(product.defaultPrice),
        description: Value(product.description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteProduct(int id) async {
    await (database.update(database.products)..where((t) => t.id.equals(id))).write(
      db.ProductTableCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<List<Product>> getActiveProducts() async {
    final query = database.select(database.products)..where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  Product _mapToEntity(db.ProductTable row) {
    return Product(
      id: row.id,
      name: row.name,
      unitType: UnitType.fromCode(row.unitType),
      isWeighted: row.isWeighted,
      defaultPrice: row.defaultPrice,
      description: row.description,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
  
  @override
  Future<List<Product>> searchProducts(String query) async {
    final results = await (database.select(database.products)..where((t) => t.name.like('%$query%'))).get();
    return results.map(_mapToEntity).toList();
  }
}
