import 'package:poultry_accounting/domain/entities/stock_conversion.dart';

abstract class StockConversionRepository {
  Future<List<StockConversion>> getAllConversions();
  
  Future<StockConversion?> getConversionById(int id);
  
  Future<List<StockConversionItem>> getItemsByConversionId(int conversionId);

  /// Performs the conversion:
  /// 1. Deducts [sourceQuantity] of [sourceProductId] from inventory.
  /// 2. Creates a conversion record.
  /// 3. Adds [items] to inventory (as new batches).
  /// Returns the ID of the created conversion.
  Future<int> convertStock({
    required StockConversion conversion,
    required List<StockConversionItem> items,
  });
}
