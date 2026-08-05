import 'package:financas/providers/finance_providers.dart';
import 'package:financas/screens/card_payment_form_screen.dart';
import 'package:financas/screens/card_payments_screen.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class StatementPaymentPanel extends ConsumerWidget {
  const StatementPaymentPanel({super.key});

  void _openPayments(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Pagamentos de fatura')),
          body: const CardPaymentsScreen(),
        ),
      ),
    );
  }

  void _openPayForm(
    BuildContext context,
    WidgetRef ref, {
    String? cardId,
    double? suggestedAmount,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardPaymentFormScreen(
          initialCardId: cardId ?? ref.read(expenseFilterCardProvider),
          initialStatementMonth: ref.read(selectedMonthProvider),
          suggestedAmount: suggestedAmount,
        ),
      ),
    );
  }

  String _statusLabel(StatementPaymentStatus status) {
    switch (status) {
      case StatementPaymentStatus.open:
        return 'Em aberto';
      case StatementPaymentStatus.partial:
        return 'Parcialmente paga';
      case StatementPaymentStatus.paid:
        return 'Paga';
      case StatementPaymentStatus.overpaid:
        return 'Paga (crédito)';
    }
  }

  Color _statusColor(ColorScheme scheme, StatementPaymentStatus status) {
    switch (status) {
      case StatementPaymentStatus.open:
        return scheme.error;
      case StatementPaymentStatus.partial:
        return scheme.tertiary;
      case StatementPaymentStatus.paid:
      case StatementPaymentStatus.overpaid:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceView = ref.watch(invoiceViewProvider);
    if (!invoiceView) return const SizedBox.shrink();

    final summary = ref.watch(statementPaymentSummaryProvider);
    final byCard = ref.watch(statementPaymentByCardProvider);
    final cards = ref.watch(cardsProvider);
    final cardFilter = ref.watch(expenseFilterCardProvider);
    final scheme = Theme.of(context).colorScheme;

    if (!summary.hasActivity && byCard.isEmpty) {
      return const SizedBox.shrink();
    }

    String cardName(String? id) {
      if (id == null) return 'Todos os cartões';
      final match = cards.where((c) => c.id == id);
      return match.isEmpty ? 'Cartão' : match.first.displayName;
    }

    final statusColor = _statusColor(scheme, summary.status);
    final canPay = cards.isNotEmpty &&
        (cardFilter != null
            ? summary.remaining > 0.009
            : byCard.any((s) => s.remaining > 0.009));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pagamento da fatura',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(summary.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MoneyRow(
                  label: 'Total da fatura',
                  value: summary.statementTotal,
                ),
                const SizedBox(height: 6),
                _MoneyRow(
                  label: 'Já pago',
                  value: summary.paidAmount,
                  valueColor: scheme.primary,
                ),
                const SizedBox(height: 6),
                _MoneyRow(
                  label: summary.remaining < -0.009
                      ? 'Crédito'
                      : 'Restante',
                  value: summary.remaining.abs(),
                  emphasize: true,
                  valueColor: summary.remaining > 0.009
                      ? scheme.error
                      : scheme.primary,
                ),
                if (cardFilter == null && byCard.length > 1) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...byCard.take(4).map((item) {
                    final remaining = item.remaining;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cardName(item.cardId),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            remaining > 0.009
                                ? 'Restam ${formatCurrency(remaining)}'
                                : remaining < -0.009
                                    ? 'Crédito ${formatCurrency(remaining.abs())}'
                                    : 'Quitada',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: remaining > 0.009
                                  ? scheme.error
                                  : scheme.primary,
                            ),
                          ),
                          if (remaining > 0.009)
                            IconButton(
                              tooltip: 'Pagar',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _openPayForm(
                                context,
                                ref,
                                cardId: item.cardId,
                                suggestedAmount: remaining,
                              ),
                              icon: const Icon(Icons.payments_outlined, size: 18),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openPayments(context),
                        child: const Text('Histórico'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canPay
                            ? () => _openPayForm(
                                  context,
                                  ref,
                                  cardId: cardFilter,
                                  suggestedAmount: cardFilter != null &&
                                          summary.remaining > 0
                                      ? summary.remaining
                                      : null,
                                )
                            : null,
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Text(
                          summary.status == StatementPaymentStatus.partial
                              ? 'Pagar restante'
                              : 'Pagar fatura',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final double value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          formatCurrency(value),
          style: GoogleFonts.fraunces(
            fontSize: emphasize ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
