import 'package:financas/models/income.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class IncomeFormScreen extends ConsumerStatefulWidget {
  const IncomeFormScreen({super.key, this.income});

  final Income? income;

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late DateTime _date;
  late String _type;

  bool get isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    final income = widget.income;
    _description = TextEditingController(text: income?.description ?? '');
    _amount = TextEditingController(
      text: income == null
          ? ''
          : income.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _date = income?.date ?? DateTime.now();
    _type = income?.type ?? IncomeTypes.salary;
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseBrazilianAmount(_amount.text);
    if (amount == null) return;

    await ref.read(incomesProvider.notifier).save(
          Income(
            id: widget.income?.id ?? const Uuid().v4(),
            description: _description.text.trim(),
            amount: amount,
            date: _date,
            type: _type,
          ),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar entrada' : 'Nova entrada'),
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
                    hintText: 'Ex.: Salário CLT, corridas Maxim',
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
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
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
                  title: const Text('Data'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: IncomeTypes.all
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(
                    isEditing ? 'Salvar alterações' : 'Adicionar entrada',
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
