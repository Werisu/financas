import 'package:financas/providers/finance_providers.dart';
import 'package:financas/screens/card_payment_form_screen.dart';
import 'package:financas/utils/formatters.dart';
import 'package:financas/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardPaymentsScreen extends ConsumerWidget {
  const CardPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(monthCardPaymentsProvider);
    final totalPaid = ref.watch(monthCardPaymentsTotalProvider);
    final cards = ref.watch(cardsProvider);
    final scheme = Theme.of(context).colorScheme;

    String cardName(String id) {
      final match = cards.where((c) => c.id == id);
      return match.isEmpty ? 'Cartão removido' : match.first.displayName;
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: MonthSelector(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Card(
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            child: ListTile(
              title: const Text('Pago neste mês de fatura'),
              trailing: Text(
                formatCurrency(totalPaid),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CardPaymentFormScreen(
                      initialCardId: ref.read(expenseFilterCardProvider),
                      initialStatementMonth: ref.read(selectedMonthProvider),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo pagamento'),
            ),
          ),
        ),
        Expanded(
          child: payments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: scheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum pagamento nesta fatura.\n'
                          'Lance o pagamento total ou parcial do cartão.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: payments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CardPaymentFormScreen(payment: payment),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor:
                              scheme.primary.withValues(alpha: 0.15),
                          foregroundColor: scheme.primary,
                          child: const Icon(Icons.payments_outlined, size: 20),
                        ),
                        title: Text(cardName(payment.cardId)),
                        subtitle: Text(
                          [
                            formatDate(payment.date),
                            if (payment.notes != null &&
                                payment.notes!.isNotEmpty)
                              payment.notes!,
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatCurrency(payment.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Excluir pagamento?'),
                                    content: Text(
                                      'Remover pagamento de '
                                      '${formatCurrency(payment.amount)}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref
                                      .read(cardPaymentsProvider.notifier)
                                      .delete(payment.id);
                                }
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
