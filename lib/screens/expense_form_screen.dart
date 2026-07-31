import 'package:financas/models/expense.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/services/installment_service.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final Expense? expense;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _installments = InstallmentService();
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late DateTime _date;
  String? _categoryId;
  String? _cardId;
  int _installmentCount = 1;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _description = TextEditingController(text: expense?.description ?? '');
    _amount = TextEditingController(
      text: expense == null
          ? ''
          : expense.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _date = expense?.date ?? DateTime.now();
    _categoryId = expense?.categoryId;
    _cardId = expense?.cardId;
    _installmentCount = expense?.installmentTotal ?? 1;
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final categories = ref.read(categoriesProvider);
    final categoryId = _categoryId ?? categories.first.id;
    final amount = parseBrazilianAmount(_amount.text);
    if (amount == null) return;

    final base = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      description: _description.text.trim(),
      amount: amount,
      date: _date,
      categoryId: categoryId,
      cardId: _cardId,
      origin: widget.expense?.origin ?? ExpenseOrigin.manual,
      installmentGroupId: widget.expense?.installmentGroupId,
      installmentNumber: widget.expense?.installmentNumber,
      installmentTotal: widget.expense?.installmentTotal,
    );

    if (isEditing) {
      await ref.read(expensesProvider.notifier).save(base);
    } else if (_installmentCount > 1) {
      final expanded = _installments.expandExpense(
        base: base,
        forceTotalInstallments: _installmentCount,
      );
      await ref.read(expensesProvider.notifier).saveAll(expanded);
    } else {
      final expanded = _installments.expandExpense(base: base);
      await ref.read(expensesProvider.notifier).saveAll(expanded);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final cards = ref.watch(cardsProvider);
    _categoryId ??= categories.isNotEmpty ? categories.first.id : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar gasto' : 'Novo gasto'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: Supermercado Extra',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Informe a descrição'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amount,
                  decoration: const InputDecoration(
                    labelText: 'Valor da parcela',
                    prefixText: 'R\$ ',
                    helperText: 'Se parcelar, use o valor de cada mês',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  validator: (value) {
                    final parsed = parseBrazilianAmount(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Informe um valor válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data da 1ª parcela'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) =>
                      value == null ? 'Selecione a categoria' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _cardId,
                  decoration: const InputDecoration(labelText: 'Cartão'),
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
                if (!isEditing) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _installmentCount,
                    decoration: const InputDecoration(
                      labelText: 'Parcelar em',
                      helperText:
                          'Gera um lançamento por mês automaticamente',
                    ),
                    items: [
                      for (var i = 1; i <= 24; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(i == 1 ? 'À vista (1x)' : '$i vezes'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _installmentCount = value);
                    },
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(
                    isEditing
                        ? 'Salvar alterações'
                        : _installmentCount > 1
                            ? 'Adicionar $_installmentCount parcelas'
                            : 'Adicionar gasto',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
