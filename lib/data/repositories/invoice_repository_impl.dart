import 'package:drift/drift.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:poultry_accounting/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final db.AppDatabase database;

  InvoiceRepositoryImpl(this.database);

  @override
  Future<List<Invoice>> getAllInvoices({
    InvoiceStatus? status,
    int? customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = database.select(database.salesInvoices);
    
    if (status != null) {
      query.where((t) => t.status.equals(status.code));
    }
    if (customerId != null) {
      query.where((t) => t.customerId.equals(customerId));
    }
    if (fromDate != null) {
      query.where((t) => t.invoiceDate.isAtLeastValue(fromDate));
    }
    if (toDate != null) {
      query.where((t) => t.invoiceDate.isAtMostValue(toDate));
    }
    
    final rows = await query.get();
    final List<Invoice> invoices = [];
    
    for (final row in rows) {
      final items = await _getInvoiceItems(row.id);
      invoices.add(_mapToEntity(row, items));
    }
    
    return invoices;
  }

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    final query = database.select(database.salesInvoices)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    
    final items = await _getInvoiceItems(row.id);
    return _mapToEntity(row, items);
  }

  @override
  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    final query = database.select(database.salesInvoices)..where((t) => t.invoiceNumber.equals(invoiceNumber));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    
    final items = await _getInvoiceItems(row.id);
    return _mapToEntity(row, items);
  }

  @override
  Future<int> createInvoice(Invoice invoice) async {
    return await database.transaction(() async {
      final id = await database.into(database.salesInvoices).insert(
        db.SalesInvoiceTableCompanion.insert(
          invoiceNumber: invoice.invoiceNumber,
          customerId: invoice.customerId,
          invoiceDate: invoice.invoiceDate,
          status: invoice.status.code,
          subtotal: Value(invoice.subtotal),
          discount: Value(invoice.discount),
          tax: Value(invoice.tax),
          total: Value(invoice.total),
          paidAmount: Value(invoice.paidAmount),
          notes: Value(invoice.notes),
          createdBy: Value(invoice.createdBy ?? 1),
        ),
      );

      for (final item in invoice.items) {
        await database.into(database.salesInvoiceItems).insert(
          db.SalesInvoiceItemTableCompanion.insert(
            invoiceId: id,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            costAtSale: item.costAtSale,
            discount: Value(item.discount),
            total: item.total,
          ),
        );
      }
      return id;
    });
  }

  @override
  Future<void> updateInvoice(Invoice invoice) async {
    if (invoice.id == null) return;
    
    await database.transaction(() async {
      await (database.update(database.salesInvoices)..where((t) => t.id.equals(invoice.id!))).write(
        db.SalesInvoiceTableCompanion(
          customerId: Value(invoice.customerId),
          invoiceDate: Value(invoice.invoiceDate),
          subtotal: Value(invoice.subtotal),
          discount: Value(invoice.discount),
          tax: Value(invoice.tax),
          total: Value(invoice.total),
          paidAmount: Value(invoice.paidAmount),
          notes: Value(invoice.notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Re-insert items
      await (database.delete(database.salesInvoiceItems)..where((t) => t.invoiceId.equals(invoice.id!))).go();
      for (final item in invoice.items) {
        await database.into(database.salesInvoiceItems).insert(
          db.SalesInvoiceItemTableCompanion.insert(
            invoiceId: invoice.id!,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            costAtSale: item.costAtSale,
            discount: Value(item.discount),
            total: item.total,
          ),
        );
      }
    });
  }

  @override
  Future<void> confirmInvoice(int invoiceId, int userId) async {
    await (database.update(database.salesInvoices)..where((t) => t.id.equals(invoiceId))).write(
      db.SalesInvoiceTableCompanion(
        status: Value(InvoiceStatus.confirmed.code),
        confirmedAt: Value(DateTime.now()),
        confirmedBy: Value(userId),
      ),
    );
  }

  @override
  Future<void> cancelInvoice(int invoiceId, int userId) async {
    await (database.update(database.salesInvoices)..where((t) => t.id.equals(invoiceId))).write(
      db.SalesInvoiceTableCompanion(
        status: Value(InvoiceStatus.cancelled.code),
      ),
    );
  }

  @override
  Future<void> deleteInvoice(int id) async {
    await (database.update(database.salesInvoices)..where((t) => t.id.equals(id))).write(
      db.SalesInvoiceTableCompanion(
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<String> generateInvoiceNumber() async {
    final count = await database.salesInvoices.id.count().getSingle();
    final year = DateTime.now().year.toString().substring(2);
    return 'INV-$year-${(count + 1).toString().padLeft(5, '0')}';
  }

  @override
  Future<double> getTotalRevenue({DateTime? fromDate, DateTime? toDate}) async {
    final totalExp = database.salesInvoices.total.sum();
    final query = database.selectOnly(database.salesInvoices)..addColumns([totalExp]);
    query.where(database.salesInvoices.status.equals(InvoiceStatus.confirmed.code));
    
    if (fromDate != null) query.where(database.salesInvoices.invoiceDate.isAtLeastValue(fromDate));
    if (toDate != null) query.where(database.salesInvoices.invoiceDate.isAtMostValue(toDate));
    
    final result = await query.getSingle();
    return result.read(totalExp) ?? 0.0;
  }

  @override
  Future<double> getTotalProfit({DateTime? fromDate, DateTime? toDate}) async {
    // Basic implementation, in real app would involve COGS
    final totalRevenue = await getTotalRevenue(fromDate: fromDate, toDate: toDate);
    // Rough estimate or detailed subquery needed for real profit
    return totalRevenue * 0.1; // Placeholder
  }

  @override
  Future<List<Invoice>> getUnpaidInvoices(int customerId) async {
    final query = database.select(database.salesInvoices)
      ..where((t) => t.customerId.equals(customerId) & 
                     t.status.equals(InvoiceStatus.confirmed.code) &
                     t.total.isBiggerThan(t.paidAmount));
    
    final rows = await query.get();
    final List<Invoice> invoices = [];
    for (final row in rows) {
      final items = await _getInvoiceItems(row.id);
      invoices.add(_mapToEntity(row, items));
    }
    return invoices;
  }

  @override
  Future<void> updatePaidAmount(int invoiceId, double amount) async {
    final invoice = await getInvoiceById(invoiceId);
    if (invoice == null) return;
    
    await (database.update(database.salesInvoices)..where((t) => t.id.equals(invoiceId))).write(
      db.SalesInvoiceTableCompanion(
        paidAmount: Value(invoice.paidAmount + amount),
      ),
    );
  }

  // Helpers
  Future<List<InvoiceItem>> _getInvoiceItems(int invoiceId) async {
    final query = database.select(database.salesInvoiceItems)..where((t) => t.invoiceId.equals(invoiceId));
    final rows = await query.get();
    return rows.map((row) => InvoiceItem(
      id: row.id,
      productId: row.productId,
      productName: 'Product ${row.productId}', // Simplified
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      costAtSale: row.costAtSale,
      discount: row.discount,
    )).toList();
  }

  Invoice _mapToEntity(db.SalesInvoiceTable row, List<InvoiceItem> items) {
    return Invoice(
      id: row.id,
      invoiceNumber: row.invoiceNumber,
      customerId: row.customerId,
      invoiceDate: row.invoiceDate,
      status: InvoiceStatus.fromCode(row.status),
      items: items,
      discount: row.discount,
      tax: row.tax,
      paidAmount: row.paidAmount,
      notes: row.notes,
      createdBy: row.createdBy,
      confirmedAt: row.confirmedAt,
      confirmedBy: row.confirmedBy,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
