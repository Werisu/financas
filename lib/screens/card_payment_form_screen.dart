import 'package:financas/models/card_payment.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class CardPaymentFormScreen extends ConsumerStatefulWidget {
  const CardPaymentFormScreen({
    super.key,
    this.payment,
    this.initialCardId,
    this.initialStatementMonth,
    this.suggestedAmount,
  });

  final CardPayment? payment;
  final String? initialCardId;
  final DateTime? initialStatementMonth;
  final double? suggestedAmount;

  @override
  ConsumerState<CardPaymentFormScreen> createState() =>
      _CardPaymentFormScreenState();
}

class _CardPaymentFormScreenState extends ConsumerState<CardPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late DateTime _date;
  late DateTime _statementMonth;
  String? _cardId;

  bool get isEditing => widget.payment != null;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    final suggested = widget.suggestedAmount;
    _amount = TextEditingController(
      text: payment != null
          ? payment.amount.toStringAsFixed(2).replaceAll('.', ',')
          : (suggested != null && suggested > 0
              ? suggested.toStringAsFixed(2).replaceAll('.', ',')
              : ''),
    );
    _notes = TextEditingController(text: payment?.notes ?? '');
    _date = payment?.date ?? DateTime.now();
    _statementMonth = monthStart(
      payment?.statementMonth ??
          widget.initialStatementMonth ??
          DateTime.now(),
    );
    _cardId = payment?.cardId ?? widget.initialCardId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStatementMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _statementMonth,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Mês de vencimento da fatura',
    );
    if (picked != null) {
      setState(() => _statementMonth = monthStart(picked));
    }
  }

  double _remainingForSelection() {
    final cardId = _cardId;
    if (cardId == null) return 0;
    final expenses = ref.read(expensesProvider);
    final payments = ref.read(cardPaymentsProvider);
    final total = expenses
        .where(
          (e) =>
              e.cardId == cardId &&
              isSameMonth(e.billingMonth, _statementMonth),
        )
        .fold(0.0, (sum, e) => sum + e.amount);
    final paid = payments
        .where(
          (p) =>
              p.cardId == cardId &&
              isSameMonth(p.billingMonth, _statementMonth) &&
              (widget.payment == null || p.id != widget.payment!.id),
        )
        .fold(0.0, (sum, p) => sum + p.amount);
    return total - paid;
  }

  void _fillRemaining() {
    final remaining = _remainingForSelection();
    if (remaining <= 0) return;
    setState(() {
      _amount.text = remaining.toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cardId = _cardId;
    if (cardId == null) return;
    final amount = parseBrazilianAmount(_amount.text);
    if (amount == null) return;

    await ref.read(cardPaymentsProvider.notifier).save(
          CardPayment(
            id: widget.payment?.id ?? const Uuid().v4(),
            cardId: cardId,
            amount: amount,
            date: _date,
            statementMonth: _statementMonth,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          ),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);
    final remaining = _cardId == null ? 0.0 : _remainingForSelection();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar pagamento' : 'Pagar fatura'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<String>(
                  value: _cardId,
                  decoration: const InputDecoration(labelText: 'Cartão'),
                  items: cards
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: cards.isEmpty
                      ? null
                      : (value) => setState(() => _cardId = value),
                  validator: (value) =>
                      value == null ? 'Selecione o cartão' : null,
                ),
                if (cards.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Cadastre um cartão em Mais → Cartões antes de pagar.',
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fatura (vencimento)'),
                  subtitle: Text(
                    capitalize(monthYearFormat.format(_statementMonth)),
                  ),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: _pickStatementMonth,
                ),
                if (_cardId != null) ...[
                  const SizedBox(height: 4),
                  Card(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              remaining > 0.009
                                  ? 'Restante nesta fatura'
                                  : remaining < -0.009
                                      ? 'Crédito (pago a mais)'
                                      : 'Fatura quitada',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            formatCurrency(remaining.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: remaining > 0.009
                                  ? scheme.error
                                  : scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amount,
                  decoration: const InputDecoration(
                    labelText: 'Valor do pagamento',
                    prefixText: 'R\$ ',
                    helperText: 'Pode ser o total ou um valor parcial',
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
                if (remaining > 0.009) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _fillRemaining,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: Text(
                        'Pagar restante (${formatCurrency(remaining)})',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data do pagamento'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickPaymentDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex.: Pix pelo app do banco',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: cards.isEmpty ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(
                    isEditing ? 'Salvar alterações' : 'Registrar pagamento',
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
