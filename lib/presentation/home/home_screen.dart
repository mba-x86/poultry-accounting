import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/presentation/admin/settings_screen.dart';
import 'package:poultry_accounting/presentation/customers/customer_list_screen.dart';
import 'package:poultry_accounting/presentation/expenses/expense_list_screen.dart';
import 'package:poultry_accounting/presentation/inventory/stock_dashboard_screen.dart';
import 'package:poultry_accounting/presentation/partnership/partnership_screen.dart';
import 'package:poultry_accounting/presentation/payments/payment_list_screen.dart';
import 'package:poultry_accounting/presentation/pricing/daily_pricing_screen.dart';
import 'package:poultry_accounting/presentation/processing/raw_meat_processing_screen.dart';
import 'package:poultry_accounting/presentation/products/product_list_screen.dart';
import 'package:poultry_accounting/presentation/purchases/purchase_list_screen.dart';
import 'package:poultry_accounting/presentation/reports/customer_statement_screen.dart';
import 'package:poultry_accounting/presentation/reports/reports_screen.dart';
import 'package:poultry_accounting/presentation/sales/sales_invoice_list_screen.dart';
import 'package:poultry_accounting/presentation/suppliers/supplier_list_screen.dart';
import 'package:poultry_accounting/core/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsFuture = ref.watch(reportRepositoryProvider).getDashboardMetrics();
    final invoicesAsync = ref.watch(invoicesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام محاسبة الدواجن - لوحة التحكم'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.account_balance,
                      size: 150,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white, size: 35),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'نظام الدواجن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ref.watch(authProvider).user?.fullName ?? 'المسؤول',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(Icons.dashboard, 'لوحة التحكم', () {
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.analytics, 'التقارير التحليلية', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                  }),
                  _buildDrawerItem(Icons.contact_page, 'كشف حساب عميل', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerStatementScreen()));
                  }),
                  _buildDrawerItem(Icons.people, 'العملاء', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen()));
                  }),
                  _buildDrawerItem(Icons.inventory, 'المخزون', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StockDashboardScreen()));
                  }),
                  _buildDrawerItem(Icons.shopping_bag, 'الأصناف (المنتجات)', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                  }),
                  _buildDrawerItem(Icons.local_shipping, 'الموردين', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierListScreen()));
                  }),
                  _buildDrawerItem(Icons.shopping_cart, 'المشتريات (الوارد)', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseListScreen()));
                  }),
                  _buildDrawerItem(Icons.description, 'الفواتير (المبيعات)', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesInvoiceListScreen()));
                  }),
                  _buildDrawerItem(Icons.payments, 'المدفوعات', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentListScreen()));
                  }),
                  _buildDrawerItem(Icons.money_off, 'المصروفات', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
                  }),
                  const Divider(indent: 16, endIndent: 16),
                  _buildDrawerItem(Icons.calculate, 'تجهيز الخام (الوزن والنسب)', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RawMeatProcessingScreen()));
                  }),
                  _buildDrawerItem(Icons.price_change, 'التسعيرة اليومية', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyPricingScreen()));
                  }),
                  _buildDrawerItem(Icons.handshake, 'أرباح الشركاء', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnershipScreen()));
                  }),
                  _buildDrawerItem(Icons.settings, 'الإعدادات والنسخ الاحتياطي', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.red.shade50,
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نظرة عامة (اليوم)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: metricsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('خطأ: ${snapshot.error}'); // Simple error handling
                }
                final data = snapshot.data!;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('إجمالي المبيعات', '${data.todaySales.toStringAsFixed(2)} ₪', Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSummaryCard('إجمالي التحصيل', '${data.todayReceipts.toStringAsFixed(2)} ₪', Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('الذمم المستحقة', '${data.totalOutstanding.toStringAsFixed(2)} ₪', Colors.orange)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSummaryCard('المصروفات', '${data.todayExpenses.toStringAsFixed(2)} ₪', Colors.red)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'آخر الفواتير',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            invoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return const Text('لا توجد فواتير حديثة');
                }
                // Take last 5 invoices
                final recentInvoices = invoices.take(5).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentInvoices.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final invoice = recentInvoices[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.receipt, color: Colors.white),
                      ),
                      title: Text('فاتورة رقم #${invoice.id}'), // Or use invoiceNumber if available
                      subtitle: Text('التاريخ: ${invoice.invoiceDate.toString().split(' ')[0]}'),
                      trailing: Text(
                        '${invoice.total.toStringAsFixed(2)} ₪',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('خطأ: $err'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesInvoiceListScreen()));
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('فاتورة جديدة'),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: color ?? Colors.green.shade700, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
