import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final dateFormat = DateFormat('dd/MM/yyyy');
final monthYearFormat = DateFormat('MMMM yyyy', 'pt_BR');
final shortMonthFormat = DateFormat('MMM/yy', 'pt_BR');

String formatCurrency(double value) => currencyFormat.format(value);

String formatDate(DateTime date) => dateFormat.format(date);

String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

DateTime monthStart(DateTime date) => DateTime(date.year, date.month);

DateTime monthEnd(DateTime date) => DateTime(date.year, date.month + 1, 0, 23, 59, 59);

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

double? parseBrazilianAmount(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;
  text = text.replaceAll(RegExp(r'[R$\s]'), '');
  if (text.contains(',') && text.contains('.')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (text.contains(',')) {
    text = text.replaceAll(',', '.');
  }
  return double.tryParse(text);
}

DateTime? parseFlexibleDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final formats = [
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd/MM/yy'),
  ];
  for (final format in formats) {
    try {
      return format.parseStrict(text);
    } catch (_) {}
  }
  return DateTime.tryParse(text);
}
