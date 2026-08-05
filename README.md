# Finanças

App Flutter (Android e Web) para categorizar gastos do cartão de crédito, acompanhar a fatura e entender onde o dinheiro está indo.

**Desenvolvido por Wellysson Nascimento Rocha**

## Firebase (`financas-wellysson`)

Login (e-mail/senha + Google) e sincronização na nuvem via Firestore.
Veja o passo a passo em [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

Dados ficam no aparelho (Hive) e sincronizam com a conta Firebase.

## Navegação

- **Visão geral** — totais do mês, gráfico por categoria, ranking de devedores e painel de pagamento da fatura
- **Gastos** — lista com filtros (mês, categoria, cartão, busca por descrição)
- **Entradas** — salário, benefício, Maxim, freelance e outros
- **Mais** — categorias, cartões, pagamentos de fatura e devedores

## Recursos

- Lançamento manual de gastos (com parcelamento 2x–24x)
- Importação de fatura CSV com sugestão de categoria e detecção de parcelas (`PARC 02/05`, `5x`, etc.)
- Visão **por fatura**: total real do mês, separando compras novas e parcelas antigas
- Pagamento de fatura **total ou parcial**, com status (em aberto / parcial / paga) e histórico
- Dashboard mensal por categoria (gráfico + ranking)
- Categorias padrão: Supermercado, Saúde, Transportes, Moradia, Lazer, Educação, Restaurantes, Assinaturas, Outros
- Cadastro de cartões (fechamento e vencimento)
- Devedores (nome + valor) com ranking na visão geral
- Entradas de dinheiro por tipo e mês
- Perfil (nome e foto)
- Desbloqueio por digital / Face ID / PIN do celular (Android e iOS; ativar em **Meu perfil**)
- Resetar lançamentos (gastos e pagamentos), mantendo categorias, cartões, entradas, devedores e perfil

## Como rodar

Requer Flutter no PATH (SDK instalado em `C:\flutter` neste ambiente).

```bash
flutter pub get
flutter run -d chrome
# ou
flutter run -d android
```

## Importar fatura

1. Exporte a fatura do banco em CSV (colunas: data, descrição, valor)
2. No app, toque no ícone de upload
3. Ajuste as colunas se necessário
4. Revise as categorias sugeridas e confirme a importação

Aceita separador `;` ou `,`. Há um CSV de exemplo em `assets/sample_fatura.csv`.

## Pagar fatura

1. Na **Visão geral**, use o modo **Por fatura**
2. No painel **Pagamento da fatura**, veja total, já pago e restante
3. Toque em **Pagar fatura** (valor cheio ou parcial)
4. Ou use **Mais → Pagamentos de fatura** para histórico, edição e exclusão

## Desbloqueio por digital

1. Entre com e-mail/Google normalmente
2. Em **Meu perfil**, ative **Desbloquear com digital**
3. Ao abrir o app ou voltar do segundo plano, confirme com biometria ou PIN do aparelho

A biometria protege o acesso local após o login Firebase; no Web o toggle não aparece.
