import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final db.AppDatabase database;

  CustomerRepositoryImpl(this.database);

  @override
  Future<List<Customer>> getAllCustomers() async {
    final rows = await database.select(database.customers).get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<Customer?> getCustomerById(int id) async {
    final query = database.select(database.customers)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<int> createCustomer(Customer customer) async {
    return await database.into(database.customers).insert(
      db.CustomerTableCompanion.insert(
        name: customer.name,
        phone: Value(customer.phone),
        address: Value(customer.address),
        creditLimit: Value(customer.creditLimit),
        notes: Value(customer.notes),
      ),
    );
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await (database.update(database.customers)..where((t) => t.id.equals(customer.id!))).write(
      db.CustomerTableCompanion(
        name: Value(customer.name),
        phone: Value(customer.phone),
        address: Value(customer.address),
        creditLimit: Value(customer.creditLimit),
        notes: Value(customer.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteCustomer(int id) async {
    await (database.update(database.customers)..where((t) => t.id.equals(id))).write(
      db.CustomerTableCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<List<Customer>> getActiveCustomers() async {
    final query = database.select(database.customers)..where((t) => t.isActive.equals(true) & t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    final results = await (database.select(database.customers)..where((t) => t.name.like('%$query%') | t.phone.like('%$query%'))).get();
    return results.map(_mapToEntity).toList();
  }

  @override
  Future<double> getCustomerBalance(int customerId) async {
    // Basic implementation: Confirmed Invoices - Paid Amount
    final query = database.select(database.salesInvoices)
      ..where((t) => t.customerId.equals(customerId) & t.status.equals('confirmed'));
    final invoices = await query.get();
    double balance = 0;
    for (var inv in invoices) {
      balance += (inv.total - inv.paidAmount);
    }
    return balance;
  }

  @override
  Future<Map<String, dynamic>> getCustomerStatement(int customerId, {DateTime? fromDate, DateTime? toDate}) async {
    return {}; // Placeholder
  }

  @override
  Future<Map<String, double>> getCustomerAging(int customerId) async {
    return {}; // Placeholder
  }

  @override
  Future<bool> isCreditLimitExceeded(int customerId) async {
    final customer = await getCustomerById(customerId);
    if (customer == null) return false;
    final balance = await getCustomerBalance(customerId);
    return balance > customer.creditLimit;
  }

  Customer _mapToEntity(db.CustomerTable row) {
    return Customer(
      id: row.id,
      name: row.name,
      phone: row.phone,
      address: row.address,
      creditLimit: row.creditLimit,
      notes: row.notes,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
