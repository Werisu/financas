import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/services/csv_import_service.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportCsvScreen extends ConsumerStatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends ConsumerState<ImportCsvScreen> {
  final _service = CsvImportService();
  List<List<String>> _rows = [];
  List<String> _headers = [];
  List<ParsedCsvExpense> _parsed = [];
  String? _cardId;
  bool _hasHeader = true;
  String? _fileName;
  int _dateIndex = 0;
  int _descriptionIndex = 1;
  int _amountIndex = 2;
  bool _expandInstallments = true;
  late DateTime _statementDueMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _statementDueMonth = DateTime(now.year, now.month);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ler o arquivo.')),
        );
      }
      return;
    }

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final rows = _service.parseCsv(content);
    if (rows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV vazio ou inválido.')),
        );
      }
      return;
    }

    final headers = rows.first;
    final detected = _service.detectMapping(headers);

    setState(() {
      _fileName = file.name;
      _rows = rows;
      _headers = headers;
      _hasHeader = true;
      _dateIndex = detected?.dateIndex ?? 0;
      _descriptionIndex = detected?.descriptionIndex ?? 1;
      _amountIndex = detected?.amountIndex ?? 2;
      _rebuildParsed();
    });
  }

  void _rebuildParsed() {
    final categories = ref.read(categoriesProvider);
    final mapping = CsvColumnMapping(
      dateIndex: _dateIndex,
      descriptionIndex: _descriptionIndex,
      amountIndex: _amountIndex,
    );
    _parsed = _service.mapRows(
      rows: _rows,
      mapping: mapping,
      categories: categories,
      hasHeader: _hasHeader,
    );
  }

  Future<void> _confirmImport() async {
    if (_parsed.isEmpty) return;
    if (_cardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o cartão desta fatura antes de importar.'),
        ),
      );
      return;
    }

    final expenses = _service.toExpenses(
      parsed: _parsed,
      cardId: _cardId,
      statementDueMonth: _statementDueMonth,
      expandInstallments: _expandInstallments,
    );
    await ref.read(expensesProvider.notifier).saveAll(expenses);

    // Ajusta a visão para a fatura importada.
    ref.read(invoiceViewProvider.notifier).state = true;
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(_statementDueMonth.year, _statementDueMonth.month);
    ref.read(expenseFilterCardProvider.notifier).state = _cardId;

    if (!mounted) return;
    final extra = expenses.length - _parsed.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          extra > 0
              ? '${expenses.length} gastos na fatura de ${capitalize(monthYearFormat.format(_statementDueMonth))} (+$extra futuras).'
              : '${expenses.length} gastos na fatura de ${capitalize(monthYearFormat.format(_statementDueMonth))}.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final cards = ref.watch(cardsProvider);

    String categoryName(String id) {
      final match = categories.where((c) => c.id == id);
      return match.isEmpty ? 'Outros' : match.first.name;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Importar fatura CSV')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como preparar o CSV',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Importe a fatura exportada do banco. '
                        'O app detecta as colunas e sugere categorias pelas descrições.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Colunas obrigatórias',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      const _CsvColumnTip(
                        title: 'Data',
                        detail:
                            'Nomes: Data, Date\nFormatos: 15/07/2026, 15-07-2026, 2026-07-15',
                      ),
                      const SizedBox(height: 8),
                      const _CsvColumnTip(
                        title: 'Descrição',
                        detail:
                            'Nomes: Descrição, Estabelecimento, Lançamento, Histórico, Memo, Merchant',
                      ),
                      const SizedBox(height: 8),
                      const _CsvColumnTip(
                        title: 'Valor',
                        detail:
                            'Nomes: Valor, Amount, Value, R\$\nExemplos: 32,50 | 1.234,56 | 32.50',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Exemplo',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SelectableText(
                          'Data;Descrição;Valor\n'
                          '15/07/2026;UBER *TRIP SAO PAULO;32,50\n'
                          '16/07/2026;DROGASIL FILIAL 102;89,90',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aceita ; ou , como separador. A data do CSV é a da compra '
                        '(ex.: 06/03 numa parcela). O valor entra na fatura que você '
                        'escolher abaixo (ex.: vencimento em agosto).\n\n'
                        'Parcelas futuras: se vier PARC 02/05, o app cria as próximas '
                        'faturas. PARC 05/05 é a última — só soma nesta fatura.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: Text(_fileName == null
                            ? 'Escolher arquivo CSV'
                            : 'Trocar arquivo'),
                      ),
                      if (_fileName != null) ...[
                        const SizedBox(height: 8),
                        Text('Arquivo: $_fileName'),
                      ],
                    ],
                  ),
                ),
              ),
              if (_rows.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Primeira linha é cabeçalho'),
                          value: _hasHeader,
                          onChanged: (value) {
                            setState(() {
                              _hasHeader = value;
                              _rebuildParsed();
                            });
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Gerar parcelas nas próximas faturas'),
                          subtitle: const Text(
                            'Ex.: PARC 02/05 cria lançamentos nas faturas seguintes',
                          ),
                          value: _expandInstallments,
                          onChanged: (value) {
                            setState(() => _expandInstallments = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          value: _cardId,
                          decoration: const InputDecoration(
                            labelText: 'Cartão desta fatura *',
                            helperText: 'Obrigatório para amarrar o valor à fatura correta',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Selecione...'),
                            ),
                            ...cards.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.displayName),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _cardId = value),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Vencimento desta fatura *'),
                          subtitle: Text(
                            capitalize(monthYearFormat.format(_statementDueMonth)),
                          ),
                          trailing: const Icon(Icons.calendar_month_outlined),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _statementDueMonth,
                              firstDate: DateTime(2018),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                              locale: const Locale('pt', 'BR'),
                              helpText: 'Mês de vencimento da fatura',
                            );
                            if (picked != null) {
                              setState(() {
                                _statementDueMonth =
                                    DateTime(picked.year, picked.month);
                              });
                            }
                          },
                        ),
                        Text(
                          'Ex.: fecha 29/07 e vence 05/08 → escolha agosto/2026. '
                          'Assim o PARC05/05 de 332,45 entra na fatura de agosto, '
                          'mesmo com data de compra em março.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        _columnDropdown(
                          label: 'Coluna de data',
                          value: _dateIndex,
                          onChanged: (value) {
                            setState(() {
                              _dateIndex = value!;
                              _rebuildParsed();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _columnDropdown(
                          label: 'Coluna de descrição',
                          value: _descriptionIndex,
                          onChanged: (value) {
                            setState(() {
                              _descriptionIndex = value!;
                              _rebuildParsed();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _columnDropdown(
                          label: 'Coluna de valor',
                          value: _amountIndex,
                          onChanged: (value) {
                            setState(() {
                              _amountIndex = value!;
                              _rebuildParsed();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final invoiceTotal = _parsed.fold<double>(
                      0,
                      (sum, item) => sum + item.amount,
                    );
                    final futureCount = _expandInstallments
                        ? _service.countFutureInstallments(_parsed)
                        : 0;
                    final futureTotal = _expandInstallments
                        ? _parsed.fold<double>(0, (sum, item) {
                            final info = _service.installments
                                .parseFromDescription(item.description);
                            if (info != null && info.hasFuture) {
                              return sum + (item.amount * info.remaining);
                            }
                            final times = _service.installments
                                .parseTimesOnly(item.description);
                            if (times != null) {
                              return sum + (item.amount * (times - 1));
                            }
                            return sum;
                          })
                        : 0.0;
                    final scheme = Theme.of(context).colorScheme;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          futureCount > 0
                              ? 'Pré-visualização (${_parsed.length} na fatura + $futureCount parcelas futuras)'
                              : 'Pré-visualização (${_parsed.length} lançamentos)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Card(
                          color: scheme.primary.withValues(alpha: 0.08),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Total desta fatura',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(invoiceTotal),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${_parsed.length} lançamento(s) no arquivo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                                if (futureCount > 0) ...[
                                  const Divider(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Parcelas futuras geradas',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      Text(formatCurrency(futureTotal)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total geral (fatura + futuras)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(
                                          invoiceTotal + futureTotal,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (_parsed.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nenhuma linha válida. Ajuste o mapeamento das colunas.',
                      ),
                    ),
                  )
                else
                  ...List.generate(_parsed.length.clamp(0, 40), (index) {
                    final item = _parsed[index];
                    final info = _service.installments
                        .parseFromDescription(item.description);
                    final times =
                        _service.installments.parseTimesOnly(item.description);
                    final futureHint = !_expandInstallments
                        ? null
                        : info != null && info.hasFuture
                            ? 'Gera +${info.remaining} parcela(s)'
                            : info != null && !info.hasFuture
                                ? 'Última parcela'
                                : times != null
                                    ? 'Gera +${times - 1} parcela(s)'
                                    : null;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.description),
                        subtitle: Text(
                          [
                            formatDate(item.date),
                            categoryName(item.suggestedCategoryId),
                            ?futureHint,
                          ].join(' · '),
                        ),
                        trailing: SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<String>(
                            value: item.suggestedCategoryId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            items: categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(
                                () => item.suggestedCategoryId = value,
                              );
                            },
                          ),
                        ),
                        leading: Text(
                          formatCurrency(item.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  }),
                if (_parsed.length > 40)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Mostrando 40 de ${_parsed.length} na lista abaixo. '
                      'A soma e a importação usam os ${_parsed.length} registros.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _parsed.isEmpty ? null : _confirmImport,
                  icon: const Icon(Icons.download_done),
                  label: Text(() {
                    final invoiceTotal = _parsed.fold<double>(
                      0,
                      (sum, item) => sum + item.amount,
                    );
                    final futureCount = _expandInstallments
                        ? _service.countFutureInstallments(_parsed)
                        : 0;
                    final count = _parsed.length + futureCount;
                    return 'Importar $count gastos · ${formatCurrency(invoiceTotal)}';
                  }()),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _columnDropdown({
    required String label,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    final count = _headers.isNotEmpty ? _headers.length : 0;
    return DropdownButtonFormField<int>(
      value: value < count ? value : 0,
      decoration: InputDecoration(labelText: label),
      items: List.generate(count, (index) {
        final title = _hasHeader ? _headers[index] : 'Coluna ${index + 1}';
        return DropdownMenuItem(
          value: index,
          child: Text('$index · $title'),
        );
      }),
      onChanged: onChanged,
    );
  }
}

class _CsvColumnTip extends StatelessWidget {
  const _CsvColumnTip({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
