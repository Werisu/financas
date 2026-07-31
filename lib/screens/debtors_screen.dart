import 'package:financas/models/debtor.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:financas/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class DebtorsScreen extends ConsumerWidget {
  const DebtorsScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Debtor? debtor,
  }) async {
    final nameController = TextEditingController(text: debtor?.name ?? '');
    final amountController = TextEditingController(
      text: debtor == null
          ? ''
          : debtor.amountOwed.toStringAsFixed(2).replaceAll('.', ','),
    );
    final notesController = TextEditingController(text: debtor?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(debtor == null ? 'Novo devedor' : 'Editar devedor'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                textCapitalization: TextCapitalization.words,
                autofocus: debtor == null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor devido',
                  prefixText: 'R\$ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Ex.: emprestado em julho',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              final amount = parseBrazilianAmount(amountController.text);
              if (amount == null || amount < 0) return;
              Navigator.pop(context, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final amount = parseBrazilianAmount(amountController.text) ?? 0;
      final notes = notesController.text.trim();
      await ref.read(debtorsProvider.notifier).save(
            Debtor(
              id: debtor?.id ?? const Uuid().v4(),
              name: nameController.text.trim(),
              amountOwed: amount,
              notes: notes.isEmpty ? null : notes,
              updatedAt: DateTime.now(),
            ),
          );
    }

    nameController.dispose();
    amountController.dispose();
    notesController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtors = ref.watch(debtorsProvider);
    final total = ref.watch(debtorTotalOwedProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Devedor'),
      ),
      body: debtors.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: scheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum devedor cadastrado.\nRegistre quem te deve e o valor.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: debtors.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    child: ListTile(
                      title: const Text('Total a receber'),
                      trailing: Text(
                        formatCurrency(total),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }
                final debtor = debtors[index - 1];
                return Card(
                  child: ListTile(
                    onTap: () => _openEditor(context, ref, debtor: debtor),
                    leading: CircleAvatar(
                      backgroundColor: scheme.tertiary.withValues(alpha: 0.15),
                      foregroundColor: scheme.tertiary,
                      child: Text(
                        debtor.name.isNotEmpty
                            ? debtor.name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(debtor.name),
                    subtitle: debtor.notes == null || debtor.notes!.isEmpty
                        ? null
                        : Text(debtor.notes!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatCurrency(debtor.amountOwed),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Excluir devedor?'),
                                content: Text('Remover "${debtor.name}"?'),
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
                                  .read(debtorsProvider.notifier)
                                  .delete(debtor.id);
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
    );
  }
}
