import 'package:csv/csv.dart';
import 'package:financas/models/category.dart';
import 'package:financas/models/expense.dart';
import 'package:financas/services/category_suggestion_service.dart';
import 'package:financas/utils/formatters.dart';
import 'package:uuid/uuid.dart';

class CsvColumnMapping {
  const CsvColumnMapping({
    required this.dateIndex,
    required this.descriptionIndex,
    required this.amountIndex,
  });

  final int dateIndex;
  final int descriptionIndex;
  final int amountIndex;
}

class ParsedCsvExpense {
  ParsedCsvExpense({
    required this.description,
    required this.amount,
    required this.date,
    required this.suggestedCategoryId,
  });

  String description;
  double amount;
  DateTime date;
  String suggestedCategoryId;
}

class CsvImportService {
  CsvImportService({CategorySuggestionService? suggestionService})
      : _suggestion = suggestionService ?? CategorySuggestionService();

  final CategorySuggestionService _suggestion;
  final _uuid = const Uuid();

  List<List<String>> parseCsv(String content) {
    final normalized =
        content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return [];

    final firstLine = normalized.split('\n').first;
    final fieldDelimiter = _detectDelimiter(firstLine);

    final rows = CsvDecoder(
      fieldDelimiter: fieldDelimiter,
      dynamicTyping: false,
      skipEmptyLines: true,
    ).convert(normalized);

    return rows
        .map((row) => row.map((cell) => cell.toString().trim()).toList())
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
  }

  String _detectDelimiter(String headerLine) {
    final commas = ','.allMatches(headerLine).length;
    final semicolons = ';'.allMatches(headerLine).length;
    return semicolons > commas ? ';' : ',';
  }

  CsvColumnMapping? detectMapping(List<String> header) {
    int? dateIndex;
    int? descriptionIndex;
    int? amountIndex;

    for (var i = 0; i < header.length; i++) {
      final col = header[i].toLowerCase();
      if (dateIndex == null &&
          (col.contains('data') || col.contains('date'))) {
        dateIndex = i;
      } else if (descriptionIndex == null &&
          (col.contains('descri') ||
              col.contains('estabelecimento') ||
              col.contains('lançamento') ||
              col.contains('lancamento') ||
              col.contains('histórico') ||
              col.contains('historico') ||
              col.contains('memo') ||
              col.contains('merchant'))) {
        descriptionIndex = i;
      } else if (amountIndex == null &&
          (col.contains('valor') ||
              col.contains('amount') ||
              col.contains('value') ||
              col.contains('rs') ||
              col == 'r\$')) {
        amountIndex = i;
      }
    }

    if (dateIndex == null || descriptionIndex == null || amountIndex == null) {
      if (header.length >= 3) {
        return CsvColumnMapping(
          dateIndex: dateIndex ?? 0,
          descriptionIndex: descriptionIndex ?? 1,
          amountIndex: amountIndex ?? 2,
        );
      }
      return null;
    }

    return CsvColumnMapping(
      dateIndex: dateIndex,
      descriptionIndex: descriptionIndex,
      amountIndex: amountIndex,
    );
  }

  List<ParsedCsvExpense> mapRows({
    required List<List<String>> rows,
    required CsvColumnMapping mapping,
    required List<Category> categories,
    bool hasHeader = true,
  }) {
    final start = hasHeader ? 1 : 0;
    final result = <ParsedCsvExpense>[];

    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= mapping.amountIndex ||
          row.length <= mapping.dateIndex ||
          row.length <= mapping.descriptionIndex) {
        continue;
      }

      final date = parseFlexibleDate(row[mapping.dateIndex]);
      final amount = parseBrazilianAmount(row[mapping.amountIndex]);
      final description = row[mapping.descriptionIndex].trim();

      if (date == null || amount == null || description.isEmpty) continue;
      if (amount == 0) continue;

      final absolute = amount.abs();
      result.add(
        ParsedCsvExpense(
          description: description,
          amount: absolute,
          date: date,
          suggestedCategoryId:
              _suggestion.suggestCategoryId(description, categories),
        ),
      );
    }

    return result;
  }

  List<Expense> toExpenses({
    required List<ParsedCsvExpense> parsed,
    required String? cardId,
  }) {
    return parsed
        .map(
          (item) => Expense(
            id: _uuid.v4(),
            description: item.description,
            amount: item.amount,
            date: item.date,
            categoryId: item.suggestedCategoryId,
            cardId: cardId,
            origin: ExpenseOrigin.import,
          ),
        )
        .toList();
  }
}
