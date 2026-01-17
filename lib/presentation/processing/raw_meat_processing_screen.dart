import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/domain/entities/raw_meat_processing.dart';
import 'package:poultry_accounting/domain/entities/processing_output.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';

class RawMeatProcessingScreen extends ConsumerStatefulWidget {
  const RawMeatProcessingScreen({super.key});

  @override
  ConsumerState<RawMeatProcessingScreen> createState() => _RawMeatProcessingScreenState();
}

class _RawMeatProcessingScreenState extends ConsumerState<RawMeatProcessingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _grossWeightController = TextEditingController();
  final _basketWeightController = TextEditingController(text: '0.5'); // Default basket weight
  final _basketCountController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  
  double _netWeight = 0.0;
  List<ProcessingOutput> _outputs = [];
  
  @override
  void initState() {
    super.initState();
    _grossWeightController.addListener(_calculateNetWeight);
    _basketWeightController.addListener(_calculateNetWeight);
    _basketCountController.addListener(_calculateNetWeight);
  }

  void _calculateNetWeight() {
    final gross = double.tryParse(_grossWeightController.text) ?? 0.0;
    final basketWeight = double.tryParse(_basketWeightController.text) ?? 0.0;
    final basketCount = int.tryParse(_basketCountController.text) ?? 0;
    
    setState(() {
      _netWeight = gross - (basketWeight * basketCount);
      if (_netWeight < 0) _netWeight = 0;
    });
  }

  @override
  void dispose() {
    _grossWeightController.dispose();
    _basketWeightController.dispose();
    _basketCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدخال توريد خام وتجهيز'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRawInputSection(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildOutputsSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProcessing,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('حفظ العملية', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRawInputSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بيانات المادة الخام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _grossWeightController,
                    decoration: const InputDecoration(labelText: 'الوزن القائم (كغ)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _basketCountController,
                    decoration: const InputDecoration(labelText: 'عدد السلال', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _basketWeightController,
                    decoration: const InputDecoration(labelText: 'وزن السلة الواحدة', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('الوزن الصافي', style: TextStyle(color: Colors.green)),
                        Text(
                          '${_netWeight.toStringAsFixed(2)} كغ',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('الأصناف المستخرجة (الإنتاج)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _showAddOutputDialog,
              icon: const Icon(Icons.add),
              label: const Text('إضافة صنف'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _outputs.length,
          itemBuilder: (context, index) {
            final output = _outputs[index];
            return Card(
              child: ListTile(
                title: Text('صنف رقم: ${output.productId}'), // In production, show product name
                subtitle: Text('الكمية: ${output.quantity} كغ'),
                trailing: Text(
                  'النسبة: ${output.yieldPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _outputs.removeAt(index)),
                ),
              ),
            );
          },
        ),
        if (_outputs.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTotalYieldSummary(),
        ],
      ],
    );
  }

  Widget _buildTotalYieldSummary() {
    final totalQty = _outputs.fold(0.0, (sum, item) => sum + item.quantity);
    final totalYield = _netWeight > 0 ? (totalQty / _netWeight) * 100 : 0.0;
    final waste = _netWeight - totalQty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _summaryRow('إجمالي وزن المخرجات:', '${totalQty.toStringAsFixed(2)} كغ'),
          _summaryRow('إجمالي نسبة التصافي:', '${totalYield.toStringAsFixed(1)}%'),
          _summaryRow('الفاقد / الهالك:', '${waste.toStringAsFixed(2)} كغ', isRed: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black)),
        ],
      ),
    );
  }

  void _showAddOutputDialog() {
    // In a real app, this would show a product picker and quantity input
    // For now, I'll simulate adding a product (e.g. Breasts)
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة صنف منتج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر الصنف (سيتم ربطه بجدول الأصناف)'),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'الوزن (كغ)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              if (qty > 0 && _netWeight > 0) {
                setState(() {
                  _outputs.add(ProcessingOutput(
                    processingId: 0, 
                    productId: 1, // Mock product ID
                    quantity: qty,
                    yieldPercentage: (qty / _netWeight) * 100,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProcessing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إضافة صنف واحد على الأقل')));
      return;
    }

    final repo = ref.read(processingRepositoryProvider);
    final processing = RawMeatProcessing(
      batchNumber: 'BATCH-${DateTime.now().millisecondsSinceEpoch}',
      grossWeight: double.parse(_grossWeightController.text),
      basketWeight: double.parse(_basketWeightController.text),
      basketCount: int.parse(_basketCountController.text),
      netWeight: _netWeight,
      processingDate: DateTime.now(),
      createdBy: 1, // Default admin
    );

    try {
      await repo.createProcessing(processing, _outputs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ العملية بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }
}
