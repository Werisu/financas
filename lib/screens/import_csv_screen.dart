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
    final expenses = _service.toExpenses(parsed: _parsed, cardId: _cardId);
    await ref.read(expensesProvider.notifier).saveAll(expenses);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${expenses.length} gastos importados.')),
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
                      const Text(
                        'Importe a fatura exportada do banco (CSV). '
                        'O app tenta detectar as colunas e sugerir categorias pelas descrições.',
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
                        DropdownButtonFormField<String?>(
                          value: _cardId,
                          decoration: const InputDecoration(
                            labelText: 'Cartão da fatura',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Nenhum'),
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
                Text(
                  'Pré-visualização (${_parsed.length} lançamentos)',
                  style: Theme.of(context).textTheme.titleMedium,
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.description),
                        subtitle: Text(
                          '${formatDate(item.date)} · ${categoryName(item.suggestedCategoryId)}',
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
                      'Mostrando 40 de ${_parsed.length}. Todos serão importados.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _parsed.isEmpty ? null : _confirmImport,
                  icon: const Icon(Icons.download_done),
                  label: Text('Importar ${_parsed.length} gastos'),
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
