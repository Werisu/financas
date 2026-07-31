import 'package:financas/data/category_seeds.dart';
import 'package:financas/models/expense.dart';
import 'package:financas/services/category_suggestion_service.dart';
import 'package:financas/services/csv_import_service.dart';
import 'package:financas/services/installment_service.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sugere categoria por palavra-chave', () {
    final categories = CategorySeeds.defaults();
    final service = CategorySuggestionService();

    expect(
      service.suggestCategoryId('UBER *TRIP SAO PAULO', categories),
      'cat_transportes',
    );
    expect(
      service.suggestCategoryId('DROGASIL 1234', categories),
      'cat_saude',
    );
    expect(
      service.suggestCategoryId('Compra aleatoria XYZ', categories),
      'cat_outros',
    );
  });

  test('parseia valores brasileiros', () {
    expect(parseBrazilianAmount('R\$ 1.234,56'), 1234.56);
    expect(parseBrazilianAmount('45,90'), 45.90);
    expect(parseBrazilianAmount('100.50'), 100.50);
  });

  test('importa CSV com ponto e vírgula', () {
    const content = '''
Data;Descrição;Valor
15/07/2026;UBER *TRIP SAO PAULO;32,50
16/07/2026;DROGASIL FILIAL 102;89,90
''';
    final service = CsvImportService();
    final categories = CategorySeeds.defaults();
    final rows = service.parseCsv(content);
    final mapping = service.detectMapping(rows.first)!;
    final parsed = service.mapRows(
      rows: rows,
      mapping: mapping,
      categories: categories,
    );

    expect(parsed.length, 2);
    expect(parsed.first.suggestedCategoryId, 'cat_transportes');
    expect(parsed.last.suggestedCategoryId, 'cat_saude');
    expect(parsed.first.amount, 32.5);
  });

  test('detecta e expande parcelas futuras', () {
    final service = InstallmentService();
    final info = service.parseFromDescription('ROMULOFERREIRAPARC02/05');
    expect(info?.current, 2);
    expect(info?.total, 5);
    expect(info?.remaining, 3);

    final expanded = service.expandExpense(
      base: Expense(
        id: '1',
        description: 'ROMULOFERREIRAPARC02/05',
        amount: 332.45,
        date: DateTime(2026, 3, 6),
        categoryId: 'cat_outros',
      ),
    );

    expect(expanded.length, 4);
    expect(expanded.map((e) => e.billingMonth.month).toList(), [3, 4, 5, 6]);
  });

  test('não remove linhas iguais do CSV na expansão', () {
    final service = InstallmentService();
    final due = DateTime(2026, 8);
    final rows = [
      Expense(
        id: 'a',
        description: 'ROMULOFERREIRAPARC05/05',
        amount: 332.45,
        date: DateTime(2026, 3, 6),
        categoryId: 'cat_outros',
        statementDueMonth: due,
      ),
      Expense(
        id: 'b',
        description: 'ROMULOFERREIRAPARC05/05',
        amount: 332.45,
        date: DateTime(2026, 3, 9),
        categoryId: 'cat_outros',
        statementDueMonth: due,
      ),
      Expense(
        id: 'c',
        description: 'ROMULOFERREIRAPARC05/05',
        amount: 110.82,
        date: DateTime(2026, 3, 20),
        categoryId: 'cat_outros',
        statementDueMonth: due,
      ),
    ];

    final expanded = service.expandMany(rows);
    expect(expanded.length, 3);
    expect(
      expanded.fold<double>(0, (sum, e) => sum + e.amount),
      closeTo(332.45 + 332.45 + 110.82, 0.001),
    );
  });
}
