import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/data/database/database.dart';
import 'package:poultry_accounting/data/repositories/repositories.dart';
import 'package:poultry_accounting/domain/repositories/i_processing_repository.dart';
import 'package:poultry_accounting/domain/repositories/i_price_repository.dart';
import 'package:poultry_accounting/domain/repositories/i_partner_repository.dart';
import 'package:poultry_accounting/domain/repositories/i_cash_repository.dart';
import 'package:poultry_accounting/domain/repositories/product_repository.dart';
import 'package:poultry_accounting/domain/repositories/customer_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final processingRepositoryProvider = Provider<IProcessingRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProcessingRepositoryImpl(db);
});

final priceRepositoryProvider = Provider<IPriceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductPriceRepositoryImpl(db);
});

final partnerRepositoryProvider = Provider<IPartnerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PartnerRepositoryImpl(db);
});

final cashRepositoryProvider = Provider<ICashRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CashRepositoryImpl(db);
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InvoiceRepositoryImpl(db);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepositoryImpl(db);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomerRepositoryImpl(db);
});
