import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/raw_meat_processing.dart';
import 'package:poultry_accounting/domain/entities/processing_output.dart';
import 'package:poultry_accounting/domain/repositories/i_processing_repository.dart';

class ProcessingRepositoryImpl implements IProcessingRepository {
  final db.AppDatabase database;

  ProcessingRepositoryImpl(this.database);

  @override
  Future<List<RawMeatProcessing>> getAllProcessings() async {
    final results = await database.select(database.rawMeatProcessings).get();
    return results.map(_mapToRawEntity).toList();
  }

  @override
  Future<RawMeatProcessing?> getProcessingById(int id) async {
    final query = database.select(database.rawMeatProcessings)..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null ? _mapToRawEntity(result) : null;
  }

  @override
  Future<int> createProcessing(RawMeatProcessing processing, List<ProcessingOutput> outputs) async {
    return await database.transaction(() async {
      final id = await database.into(database.rawMeatProcessings).insert(
        db.RawMeatProcessingTableCompanion.insert(
          batchNumber: processing.batchNumber,
          grossWeight: processing.grossWeight,
          basketWeight: processing.basketWeight,
          basketCount: processing.basketCount,
          netWeight: processing.netWeight,
          supplierId: Value(processing.supplierId),
          processingDate: processing.processingDate,
          notes: Value(processing.notes),
          createdBy: processing.createdBy,
        ),
      );

      for (final output in outputs) {
        await database.into(database.processingOutputs).insert(
          db.ProcessingOutputTableCompanion.insert(
            processingId: id,
            productId: output.productId,
            quantity: output.quantity,
            yieldPercentage: output.yieldPercentage,
          ),
        );
      }
      return id;
    });
  }

  @override
  Future<void> updateProcessing(RawMeatProcessing processing, List<ProcessingOutput> outputs) async {
    await database.transaction(() async {
      await (database.update(database.rawMeatProcessings)..where((t) => t.id.equals(processing.id!))).write(
        db.RawMeatProcessingTableCompanion(
          grossWeight: Value(processing.grossWeight),
          basketWeight: Value(processing.basketWeight),
          basketCount: Value(processing.basketCount),
          netWeight: Value(processing.netWeight),
          notes: Value(processing.notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // Delete old outputs and replace with new ones
      await (database.delete(database.processingOutputs)..where((t) => t.processingId.equals(processing.id!))).go();
      
      for (final output in outputs) {
        await database.into(database.processingOutputs).insert(
          db.ProcessingOutputTableCompanion.insert(
            processingId: processing.id!,
            productId: output.productId,
            quantity: output.quantity,
            yieldPercentage: output.yieldPercentage,
          ),
        );
      }
    });
  }

  @override
  Future<void> deleteProcessing(int id) async {
    await (database.delete(database.rawMeatProcessings)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<ProcessingOutput>> getOutputsByProcessingId(int processingId) async {
    final query = database.select(database.processingOutputs)..where((t) => t.processingId.equals(processingId));
    final results = await query.get();
    return results.map(_mapToOutputEntity).toList();
  }

  RawMeatProcessing _mapToRawEntity(db.RawMeatProcessingTable row) {
    return RawMeatProcessing(
      id: row.id,
      batchNumber: row.batchNumber,
      grossWeight: row.grossWeight,
      basketWeight: row.basketWeight,
      basketCount: row.basketCount,
      netWeight: row.netWeight,
      supplierId: row.supplierId,
      processingDate: row.processingDate,
      notes: row.notes,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  ProcessingOutput _mapToOutputEntity(db.ProcessingOutputTable row) {
    return ProcessingOutput(
      id: row.id,
      processingId: row.processingId,
      productId: row.productId,
      quantity: row.quantity,
      yieldPercentage: row.yieldPercentage,
      createdAt: row.createdAt,
    );
  }
}
