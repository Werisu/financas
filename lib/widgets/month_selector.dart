import 'package:financas/providers/finance_providers.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final invoiceView = ref.watch(invoiceViewProvider);

    return Row(
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1);
          },
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            invoiceView
                ? 'Fatura · ${capitalize(monthYearFormat.format(month))}'
                : capitalize(monthYearFormat.format(month)),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1);
          },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
