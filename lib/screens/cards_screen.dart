import 'package:financas/models/credit_card.dart';
import 'package:financas/providers/finance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CreditCard? card,
  }) async {
    final nameController = TextEditingController(text: card?.name ?? '');
    final nicknameController =
        TextEditingController(text: card?.nickname ?? '');
    final closingController = TextEditingController(
      text: card?.closingDay?.toString() ?? '',
    );
    final dueController = TextEditingController(
      text: card?.dueDay?.toString() ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card == null ? 'Novo cartão' : 'Editar cartão'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome / bandeira',
                  hintText: 'Ex.: PicPay, Nubank, Inter',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Apelido (opcional)',
                  hintText: 'Ex.: Cartão principal',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: closingController,
                decoration: const InputDecoration(
                  labelText: 'Dia de fechamento',
                  hintText: 'Ex.: 29',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dueController,
                decoration: const InputDecoration(
                  labelText: 'Dia de vencimento',
                  hintText: 'Ex.: 5',
                ),
                keyboardType: TextInputType.number,
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
              Navigator.pop(context, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final closing = int.tryParse(closingController.text.trim());
      final due = int.tryParse(dueController.text.trim());
      await ref.read(cardsProvider.notifier).save(
            CreditCard(
              id: card?.id ?? const Uuid().v4(),
              name: nameController.text.trim(),
              nickname: nicknameController.text.trim().isEmpty
                  ? null
                  : nicknameController.text.trim(),
              closingDay: closing != null && closing >= 1 && closing <= 31
                  ? closing
                  : null,
              dueDay: due != null && due >= 1 && due <= 31 ? due : null,
            ),
          );
    }

    nameController.dispose();
    nicknameController.dispose();
    closingController.dispose();
    dueController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Cartão'),
      ),
      body: cards.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Cadastre seus cartões para vincular os gastos e filtrar a fatura.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final card = cards[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      child: const Icon(Icons.credit_card),
                    ),
                    title: Text(card.displayName),
                    subtitle: Text(
                      [
                        card.name,
                        if (card.closingDay != null)
                          'Fecha dia ${card.closingDay}',
                        if (card.dueDay != null) 'Vence dia ${card.dueDay}',
                      ].join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _openEditor(context, ref, card: card),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () async {
                            await ref
                                .read(cardsProvider.notifier)
                                .delete(card.id);
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
