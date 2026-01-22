import 'package:equatable/equatable.dart';

class Salary extends Equatable {
  const Salary({
    required this.amount,
    required this.salaryDate,
    required this.employeeName,
    this.id,
    this.notes,
    this.createdBy,
  });

  final int? id;
  final double amount;
  final DateTime salaryDate;
  final String employeeName;
  final String? notes;
  final int? createdBy;

  @override
  List<Object?> get props => [
        id,
        amount,
        salaryDate,
        employeeName,
        notes,
        createdBy,
      ];

  Salary copyWith({
    int? id,
    double? amount,
    DateTime? salaryDate,
    String? employeeName,
    String? notes,
    int? createdBy,
  }) {
    return Salary(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      salaryDate: salaryDate ?? this.salaryDate,
      employeeName: employeeName ?? this.employeeName,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
