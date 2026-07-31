import 'package:financas/models/category.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/screens/expense_form_screen.dart';
import 'package:financas/utils/formatters.dart';
import 'package:financas/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(expenseSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesListProvider);
    final categories = ref.watch(categoriesProvider);
    final cards = ref.watch(cardsProvider);
    final categoryFilter = ref.watch(expenseFilterCategoryProvider);
    final cardFilter = ref.watch(expenseFilterCardProvider);
    final searchQuery = ref.watch(expenseSearchQueryProvider);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar descrição',
                  hintText: 'Ex.: ROMULO, UBER, NETFLIX',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar',
                          onPressed: () {
                            _searchController.clear();
                            ref.read(expenseSearchQueryProvider.notifier).state =
                                '';
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  ref.read(expenseSearchQueryProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: categoryFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        ref
                            .read(expenseFilterCategoryProvider.notifier)
                            .state = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: cardFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Cartão',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...cards.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        ref.read(expenseFilterCardProvider.notifier).state =
                            value;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (searchQuery.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${expenses.length} resultado(s) em todos os meses para "$searchQuery"',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        Expanded(
          child: expenses.isEmpty
              ? Center(
                  child: Text(
                    searchQuery.trim().isEmpty
                        ? 'Nenhum gasto encontrado neste período.'
                        : 'Nenhum gasto com essa descrição.',
                  ),
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
                            if (expense.statementDueMonth != null)
                              'Fatura ${shortMonthFormat.format(expense.statementDueMonth!)}',
                            if (expense.installmentLabel != null)
                              expense.isCarryoverInstallment
                                  ? 'Parcela antiga ${expense.installmentLabel}'
                                  : 'Parcela ${expense.installmentLabel}',
                            category?.name ?? 'Sem categoria',
                            cardName(expense.cardId),
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatCurrency(expense.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
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
