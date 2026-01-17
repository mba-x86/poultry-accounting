import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:poultry_accounting/core/constants/app_constants.dart';

part 'database.g.dart';

// ============================================================================
// TABLE DEFINITIONS
// ============================================================================

/// Users table
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get fullName => text().withLength(max: 100)();
  TextColumn get role => text()(); // UserRole enum code
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete
}

/// Customers table
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(max: 20).nullable()();
  TextColumn get address => text().withLength(max: 200).nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(10000.0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete
}

/// Suppliers table
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(max: 20).nullable()();
  TextColumn get address => text().withLength(max: 200).nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Products table
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get unitType => text()(); // UnitType enum code (kg, piece, box)
  BoolColumn get isWeighted => boolean().withDefault(const Constant(true))();
  RealColumn get defaultPrice => real().withDefault(const Constant(0.0))();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Inventory Batches table (for FIFO costing)
class InventoryBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get purchaseInvoiceId => integer().nullable().references(PurchaseInvoices, #id)();
  RealColumn get quantity => real()(); // Quantity in
  RealColumn get remainingQuantity => real()(); // Remaining (for FIFO)
  RealColumn get unitCost => real()(); // Cost at purchase
  DateTimeColumn get purchaseDate => dateTime()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get batchNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Sales Invoices table
class SalesInvoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()(); // Auto-generated
  IntColumn get customerId => integer().references(Customers, #id)();
  DateTimeColumn get invoiceDate => dateTime()();
  TextColumn get status => text()(); // InvoiceStatus enum (draft, confirmed, cancelled)
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  IntColumn get confirmedBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Sales Invoice Items table
class SalesInvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(SalesInvoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get costAtSale => real()(); // CRITICAL: for profit calculation
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get total => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Purchase Invoices table
class PurchaseInvoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  DateTimeColumn get invoiceDate => dateTime()();
  TextColumn get status => text()();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get additionalCosts => real().withDefault(const Constant(0.0))(); // Transport, etc.
  TextColumn get notes => text().nullable()();
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  IntColumn get confirmedBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Purchase Invoice Items table
class PurchaseInvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(PurchaseInvoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
  RealColumn get total => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Payments table (Receipts and Payments)
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get paymentNumber => text().unique()(); // Auto-generated
  TextColumn get type => text()(); // 'receipt' or 'payment'
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  IntColumn get supplierId => integer().nullable().references(Suppliers, #id)();
  RealColumn get amount => real()();
  TextColumn get method => text()(); // PaymentMethod enum (cash, bank, check)
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get referenceNumber => text().nullable()(); // Check number, transfer ref, etc.
  TextColumn get notes => text().nullable()();
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Expense Categories table
class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Expenses table
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(ExpenseCategories, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get description => text().withLength(max: 200)();
  TextColumn get notes => text().nullable()();
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Audit Logs table
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get entityType => text()(); // table name
  IntColumn get entityId => integer()();
  TextColumn get action => text()(); // AuditAction enum (create, update, delete, etc.)
  TextColumn get oldValue => text().nullable()(); // JSON
  TextColumn get newValue => text().nullable()(); // JSON
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

/// Backups table (track backup history)
class Backups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer()(); // in bytes
  BoolColumn get isEncrypted => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ============================================================================
// DATABASE CLASS
// ============================================================================

@DriftDatabase(tables: [
  Users,
  Customers,
  Suppliers,
  Products,
  InventoryBatches,
  SalesInvoices,
  SalesInvoiceItems,
  PurchaseInvoices,
  PurchaseInvoiceItems,
  Payments,
  ExpenseCategories,
  Expenses,
  AuditLogs,
  Backups,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      
      // Seed default data
      await _seedDefaultData();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Handle future migrations
    },
  );

  // Seed default data
  Future<void> _seedDefaultData() async {
    // Create default admin user
    final hashedPassword = 'admin123'; // Will be properly hashed in production
    
    await into(users).insert(
      UsersCompanion.insert(
        username: AppConstants.defaultAdminUsername,
        passwordHash: hashedPassword,
        fullName: 'مدير النظام',
        role: UserRole.admin.code,
      ),
    );

    // Create default expense categories
    final defaultCategories = [
      'وقود',
      'كهرباء',
      'رواتب',
      'صيانة',
      'تبريد',
      'نقل',
      'إيجار',
      'مصاريف إدارية',
    ];

    for (final category in defaultCategories) {
      await into(expenseCategories).insert(
        ExpenseCategoriesCompanion.insert(
          name: category,
        ),
      );
    }
  }
}

// ============================================================================
// DATABASE CONNECTION
// ============================================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    
    return NativeDatabase.createInBackground(file);
  });
}
