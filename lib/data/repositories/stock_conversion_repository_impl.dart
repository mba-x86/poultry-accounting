import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/stock_conversion.dart';
import 'package:poultry_accounting/domain/repositories/stock_conversion_repository.dart';

class StockConversionRepositoryImpl implements StockConversionRepository {
  StockConversionRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<StockConversion>> getAllConversions() async {
    final rows = await database.select(database.stockConversions).get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<StockConversion?> getConversionById(int id) async {
    final row = await (database.select(database.stockConversions)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<List<StockConversionItem>> getItemsByConversionId(int conversionId) async {
    final rows = await (database.select(database.stockConversionItems)..where((t) => t.conversionId.equals(conversionId))).get();
    return rows.map(_mapItemToEntity).toList();
  }

  @override
  Future<int> convertStock({
    required StockConversion conversion,
    required List<StockConversionItem> items,
  }) async {
    return database.transaction(() async {
      // 1. Create Conversion Record
      final conversionId = await database.into(database.stockConversions).insert(
        db.StockConversionsCompanion.insert(
          conversionDate: conversion.conversionDate,
          sourceProductId: conversion.sourceProductId,
          sourceQuantity: conversion.sourceQuantity,
          batchNumber: Value(conversion.batchNumber),
          notes: Value(conversion.notes),
          createdBy: conversion.createdBy,
        ),
      );

      // 2. Reduce Stock of Source Product (FIFO)
      double remainingToDeduct = conversion.sourceQuantity;
      
      // Get all available batches for source product, ordered by purchase date (FIFO)
      final batches = await (database.select(database.inventoryBatches)
        ..where((t) => t.productId.equals(conversion.sourceProductId))
        ..where((t) => t.remainingQuantity.isBiggerThanValue(0))
        ..orderBy([(t) => OrderingTerm.asc(t.purchaseDate)]))
        .get();

      double weightedCostSum = 0;
      double totalDeducted = 0;

      for (final batch in batches) {
        if (remainingToDeduct <= 0) break;

        double deductAmount = 0;
        if (batch.remainingQuantity >= remainingToDeduct) {
          deductAmount = remainingToDeduct;
          
          await (database.update(database.inventoryBatches)..where((t) => t.id.equals(batch.id))).write(
            db.InventoryBatchesCompanion(
              remainingQuantity: Value(batch.remainingQuantity - deductAmount),
            ),
          );
          remainingToDeduct = 0;
        } else {
          deductAmount = batch.remainingQuantity;
          
          await (database.update(database.inventoryBatches)..where((t) => t.id.equals(batch.id))).write(
            db.InventoryBatchesCompanion(
              remainingQuantity: const Value(0),
            ),
          );
          remainingToDeduct -= deductAmount;
        }

        weightedCostSum += (deductAmount * batch.unitCost);
        totalDeducted += deductAmount;
      }

      if (remainingToDeduct > 0.01) {
        throw Exception('لا يوجد مخزون كافٍ من المنتج المختار لإجراء التحويل.');
      }

      // Calculate average unit cost of the source material used
      final averageSourceUnitCost = totalDeducted > 0 ? (weightedCostSum / totalDeducted) : 0.0;
      final totalSourceCost = weightedCostSum;

      // 3. Add Items & Create New Batches
      // Distribute the total source cost to the outputs based on their weight relative to total output weight? 
      // OR mostly, we assume cost matches weight distribution if prices are similar, but better to distribute cost.
      // Standard practice: Cost of Output = (Output Weight / Total Output Weight) * Total Source Cost
      // BUT if there is waste (bone/shrinkage), the cost per kg of output goes UP.
      
      double totalOutputWeight = items.fold(0, (sum, item) => sum + item.quantity);
      
      for (final item in items) {
        // Yield % logic if needed
        
        // Calculate Cost Allocation
        // If 50kg Whole ($500 cost) -> 20kg Breast + 20kg Thigh + 10kg Waste
        // Cost of Breast = (20 / 40) * 500 = $250? (Assuming waste has 0 value)
        // Or if waste is not an item, totalOutputWeight is 40.
        // Unit Cost Breast = $250 / 20kg = $12.5/kg. (Source was $10/kg).
        
        double assignedCost = 0;
        if (totalOutputWeight > 0) {
           assignedCost = (item.quantity / totalOutputWeight) * totalSourceCost;
        }
        
        double outputUnitCost = item.quantity > 0 ? (assignedCost / item.quantity) : 0;

        await database.into(database.stockConversionItems).insert(
          db.StockConversionItemsCompanion.insert(
            conversionId: conversionId,
            productId: item.productId,
            quantity: item.quantity,
            yieldPercentage: item.yieldPercentage,
            unitCost: outputUnitCost,
          ),
        );

        // Add to Inventory
        await database.into(database.inventoryBatches).insert(
          db.InventoryBatchesCompanion.insert(
            productId: item.productId,
            processingId: Value(conversionId), // Overloading processingId or should add conversionId? For now reusing field logic or just null and use batchNumber
            quantity: item.quantity,
            remainingQuantity: item.quantity,
            unitCost: outputUnitCost,
            purchaseDate: conversion.conversionDate,
            batchNumber: Value('CONV-$conversionId-${item.productId}'),
          ),
        );
      }

      return conversionId;
    });
  }

  StockConversion _mapToEntity(db.StockConversionTable row) {
    return StockConversion(
      id: row.id,
      conversionDate: row.conversionDate,
      sourceProductId: row.sourceProductId,
      sourceQuantity: row.sourceQuantity,
      batchNumber: row.batchNumber,
      notes: row.notes,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
    );
  }

  StockConversionItem _mapItemToEntity(db.StockConversionItemTable row) {
    return StockConversionItem(
      id: row.id,
      conversionId: row.conversionId,
      productId: row.productId,
      quantity: row.quantity,
      yieldPercentage: row.yieldPercentage,
      unitCost: row.unitCost,
    );
  }
}
