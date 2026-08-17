import '../../../features/advances/domain/models/advance_request.dart';
import '../../../features/advances/domain/models/expense_report.dart';
import '../seeds/employee_seed.dart';

/// Seed advance requests and expense reports for the mock employee.
class AdvanceSeeds {
  static const String _empId = EmployeeSeed.id;

  static List<AdvanceRequest> get advances => [
        AdvanceRequest(
          id: 'ADV-102',
          employeeId: _empId,
          amount: 2000,
          reason: 'مصاريف عمل ومشتريات المشروع',
          details: 'سُلفة عاجلة لتغطية مصاريف المشروع الجديد',
          installments: 1,
          createdAt: DateTime(2026, 8, 10),
          status: AdvanceStatus.paid,
          approvedAt: DateTime(2026, 8, 11),
        ),
        AdvanceRequest(
          id: 'ADV-103',
          employeeId: _empId,
          amount: 1500,
          reason: 'مصاريف السفر للمؤتمر',
          details: 'تغطية تكاليف السفر والإقامة',
          installments: 2,
          createdAt: DateTime(2026, 8, 15),
          status: AdvanceStatus.approved,
          approvedAt: DateTime(2026, 8, 16),
        ),
        AdvanceRequest(
          id: 'ADV-104',
          employeeId: _empId,
          amount: 500,
          reason: 'مصاريف طارئة',
          details: null,
          installments: 1,
          createdAt: DateTime(2026, 8, 17),
          status: AdvanceStatus.pending,
        ),
      ];

  static List<ExpenseReport> get expenseReports => [
        ExpenseReport(
          id: 'EXP-201',
          employeeId: _empId,
          advanceId: 'ADV-102',
          totalAmount: 1850,
          notes: 'إجمالي المصروفات الفعلية من السُلفة البالغة 2000 جنيه، والمتبقي 150 جنيه',
          submittedAt: DateTime(2026, 8, 14),
          items: [
            ExpenseItem(
              id: 'EXPI-001',
              description: 'شراء معدات تقنية',
              amount: 1200,
              date: DateTime(2026, 8, 12),
              invoiceNumber: 'INV-001',
            ),
            ExpenseItem(
              id: 'EXPI-002',
              description: 'اجتماع مع العملاء',
              amount: 650,
              date: DateTime(2026, 8, 13),
            ),
          ],
        ),
      ];
}
