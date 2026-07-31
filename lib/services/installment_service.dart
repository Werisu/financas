import 'package:financas/models/expense.dart';
import 'package:uuid/uuid.dart';

class InstallmentInfo {
  const InstallmentInfo({
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  bool get hasFuture => current < total;
  int get remaining => (total - current).clamp(0, total);
}

class InstallmentService {
  InstallmentService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  static final _parcPattern = RegExp(
    r'parc(?:ela)?\.?\s*0*(\d{1,2})\s*/\s*0*(\d{1,2})',
    caseSensitive: false,
  );

  static final _slashPattern = RegExp(
    r'(?<![0-9])0*(\d{1,2})\s*/\s*0*(\d{1,2})(?![0-9])',
  );

  static final _labelPattern = RegExp(
    r'parc(?:ela)?\.?\s*\d{1,2}\s*/\s*\d{1,2}|\b\d{1,2}\s*/\s*\d{1,2}\b',
    caseSensitive: false,
  );

  static final _timesPattern = RegExp(
    r'(?<![0-9])(\d{1,2})\s*x\b',
    caseSensitive: false,
  );

  InstallmentInfo? parseFromDescription(String description) {
    final match =
        _parcPattern.firstMatch(description) ?? _slashPattern.firstMatch(description);
    if (match == null) return null;
    final current = int.tryParse(match.group(1) ?? '');
    final total = int.tryParse(match.group(2) ?? '');
    if (current == null || total == null) return null;
    if (current < 1 || total < 2 || current > total || total > 48) return null;
    return InstallmentInfo(current: current, total: total);
  }

  /// Detecta "5x" / "12x" sem número da parcela atual.
  int? parseTimesOnly(String description) {
    if (parseFromDescription(description) != null) return null;
    final match = _timesPattern.firstMatch(description);
    if (match == null) return null;
    final total = int.tryParse(match.group(1) ?? '');
    if (total == null || total < 2 || total > 48) return null;
    return total;
  }

  String descriptionForInstallment(
    String original,
    int number,
    int total,
  ) {
    final paddedCurrent = number.toString().padLeft(2, '0');
    final paddedTotal = total.toString().padLeft(2, '0');
    final label = 'PARC$paddedCurrent/$paddedTotal';
    if (_labelPattern.hasMatch(original)) {
      return original.replaceFirst(_labelPattern, label);
    }
    return '$original $label'.trim();
  }

  DateTime addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = date.day.clamp(1, DateTime(year, month + 1, 0).day);
    return DateTime(year, month, day);
  }

  /// Gera a parcela atual + as futuras faltantes.
  List<Expense> expandExpense({
    required Expense base,
    int? forceTotalInstallments,
  }) {
    final fromDescription = parseFromDescription(base.description);
    final timesOnly = parseTimesOnly(base.description);

    late final int current;
    late final int total;

    if (forceTotalInstallments != null && forceTotalInstallments > 1) {
      current = base.installmentNumber ?? 1;
      total = forceTotalInstallments;
    } else if (fromDescription != null) {
      current = fromDescription.current;
      total = fromDescription.total;
    } else if (timesOnly != null) {
      current = 1;
      total = timesOnly;
    } else {
      return [base];
    }

    if (total < 2) return [base];

    final groupId = base.installmentGroupId ?? _uuid.v4();
    final expenses = <Expense>[];

    for (var number = current; number <= total; number++) {
      final monthsAhead = number - current;
      final hasStatement = base.statementDueMonth != null;
      final statementDue = hasStatement
          ? addMonths(
              DateTime(
                base.statementDueMonth!.year,
                base.statementDueMonth!.month,
              ),
              monthsAhead,
            )
          : null;
      // Com fatura: mantém a data da compra original e avança o vencimento.
      // Sem fatura: avança a data do lançamento mês a mês.
      final date =
          hasStatement ? base.date : addMonths(base.date, monthsAhead);

      expenses.add(
        Expense(
          id: number == current ? base.id : _uuid.v4(),
          description:
              descriptionForInstallment(base.description, number, total),
          amount: base.amount,
          date: date,
          categoryId: base.categoryId,
          cardId: base.cardId,
          origin: base.origin,
          installmentGroupId: groupId,
          installmentNumber: number,
          installmentTotal: total,
          statementDueMonth: statementDue,
        ),
      );
    }

    return expenses;
  }

  List<Expense> expandMany(List<Expense> expenses) {
    final result = <Expense>[];
    final futureKeys = <String>{};

    for (final expense in expenses) {
      final expanded = expandExpense(base: expense);
      if (expanded.isEmpty) continue;

      // Sempre mantém o lançamento original do CSV (não deduplica linhas da fatura).
      result.add(expanded.first);

      // Só evita duplicar parcelas FUTURAS geradas automaticamente.
      for (var i = 1; i < expanded.length; i++) {
        final item = expanded[i];
        final key = _futureDedupeKey(item);
        if (futureKeys.contains(key)) continue;
        futureKeys.add(key);
        result.add(item);
      }
    }
    return result;
  }

  String _futureDedupeKey(Expense expense) {
    final billing = expense.billingMonth;
    return '${expense.installmentGroupId}|${billing.year}-${billing.month}|${expense.installmentNumber}|${expense.amount.toStringAsFixed(2)}';
  }
}
