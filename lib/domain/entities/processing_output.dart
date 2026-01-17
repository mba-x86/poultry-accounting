import 'package:equatable/equatable.dart';

class ProcessingOutput extends Equatable {
  final int? id;
  final int processingId;
  final int productId;
  final double quantity;
  final double yieldPercentage;
  final DateTime? createdAt;

  const ProcessingOutput({
    this.id,
    required this.processingId,
    required this.productId,
    required this.quantity,
    required this.yieldPercentage,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, processingId, productId, quantity, yieldPercentage, createdAt];

  ProcessingOutput copyWith({
    int? id,
    int? processingId,
    int? productId,
    double? quantity,
    double? yieldPercentage,
    DateTime? createdAt,
  }) {
    return ProcessingOutput(
      id: id ?? this.id,
      processingId: processingId ?? this.processingId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      yieldPercentage: yieldPercentage ?? this.yieldPercentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
