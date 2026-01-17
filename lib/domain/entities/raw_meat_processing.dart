import 'package:equatable/equatable.dart';

class RawMeatProcessing extends Equatable {
  final int? id;
  final String batchNumber;
  final double grossWeight;
  final double basketWeight;
  final int basketCount;
  final double netWeight;
  final int? supplierId;
  final DateTime processingDate;
  final String? notes;
  final int createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RawMeatProcessing({
    this.id,
    required this.batchNumber,
    required this.grossWeight,
    required this.basketWeight,
    required this.basketCount,
    required this.netWeight,
    this.supplierId,
    required this.processingDate,
    this.notes,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        batchNumber,
        grossWeight,
        basketWeight,
        basketCount,
        netWeight,
        supplierId,
        processingDate,
        notes,
        createdBy,
        createdAt,
        updatedAt,
      ];

  RawMeatProcessing copyWith({
    int? id,
    String? batchNumber,
    double? grossWeight,
    double? basketWeight,
    int? basketCount,
    double? netWeight,
    int? supplierId,
    DateTime? processingDate,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RawMeatProcessing(
      id: id ?? this.id,
      batchNumber: batchNumber ?? this.batchNumber,
      grossWeight: grossWeight ?? this.grossWeight,
      basketWeight: basketWeight ?? this.basketWeight,
      basketCount: basketCount ?? this.basketCount,
      netWeight: netWeight ?? this.netWeight,
      supplierId: supplierId ?? this.supplierId,
      processingDate: processingDate ?? this.processingDate,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
