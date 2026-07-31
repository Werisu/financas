import 'package:financas/models/income.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/screens/income_form_screen.dart';
import 'package:financas/utils/formatters.dart';
import 'package:financas/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomesScreen extends ConsumerWidget {
  const IncomesScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case IncomeTypes.salary:
        return Icons.work_outline;
      case IncomeTypes.benefit:
        return Icons.card_giftcard_outlined;
      case IncomeTypes.maxim:
        return Icons.two_wheeler_outlined;
      case IncomeTypes.freelance:
        return Icons.handshake_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomes = ref.watch(monthIncomesProvider);
    final total = ref.watch(monthlyIncomeTotalProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: MonthSelector(invoiceAware: false),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Card(
            color: scheme.secondaryContainer.withValues(alpha: 0.4),
            child: ListTile(
              title: const Text('Total de entradas'),
              trailing: Text(
                formatCurrency(total),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        Expanded(
          child: incomes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: scheme.secondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma entrada neste mês.\nRegistre salário, Maxim, benefícios…',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: incomes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  IncomeFormScreen(income: income),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor:
                              scheme.secondary.withValues(alpha: 0.15),
                          foregroundColor: scheme.secondary,
                          child: Icon(_iconFor(income.type), size: 20),
                        ),
                        title: Text(income.description),
                        subtitle: Text(
                          '${income.type} · ${formatDate(income.date)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatCurrency(income.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Excluir entrada?'),
                                    content: Text(
                                      'Remover "${income.description}"?',
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
                                      .read(incomesProvider.notifier)
                                      .delete(income.id);
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
