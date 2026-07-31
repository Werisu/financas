import 'package:financas/models/category.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/screens/expense_form_screen.dart';
import 'package:financas/utils/formatters.dart';
import 'package:financas/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(filteredExpensesProvider);
    final categories = ref.watch(categoriesProvider);
    final cards = ref.watch(cardsProvider);
    final categoryFilter = ref.watch(expenseFilterCategoryProvider);
    final cardFilter = ref.watch(expenseFilterCardProvider);

    Category? categoryOf(String id) {
      final match = categories.where((c) => c.id == id);
      return match.isEmpty ? null : match.first;
    }

    String cardName(String? id) {
      if (id == null) return 'Sem cartão';
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
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DropdownButtonFormField<String?>(
                value: categoryFilter,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (value) {
                  ref.read(expenseFilterCategoryProvider.notifier).state = value;
                },
              ).constrained(220),
              DropdownButtonFormField<String?>(
                value: cardFilter,
                decoration: const InputDecoration(
                  labelText: 'Cartão',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...cards.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.displayName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  ref.read(expenseFilterCardProvider.notifier).state = value;
                },
              ).constrained(220),
            ],
          ),
        ),
        Expanded(
          child: expenses.isEmpty
              ? const Center(
                  child: Text('Nenhum gasto encontrado neste período.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: expenses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final category = categoryOf(expense.categoryId);
                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExpenseFormScreen(expense: expense),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: (category?.color ?? Colors.grey)
                              .withValues(alpha: 0.15),
                          foregroundColor: category?.color ?? Colors.grey,
                          child: Icon(category?.icon ?? Icons.receipt, size: 20),
                        ),
                        title: Text(expense.description),
                        subtitle: Text(
                          [
                            formatDate(expense.date),
                            if (expense.installmentLabel != null)
                              'Parcela ${expense.installmentLabel}',
                            category?.name ?? 'Sem categoria',
                            cardName(expense.cardId),
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatCurrency(expense.amount),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Excluir gasto?'),
                                    content: Text(
                                      'Remover "${expense.description}"?',
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
                                      .read(expensesProvider.notifier)
                                      .delete(expense.id);
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

extension on Widget {
  Widget constrained(double width) => SizedBox(width: width, child: this);
}
