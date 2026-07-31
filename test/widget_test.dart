import 'package:financas/data/category_seeds.dart';
import 'package:financas/services/category_suggestion_service.dart';
import 'package:financas/services/csv_import_service.dart';
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
}
