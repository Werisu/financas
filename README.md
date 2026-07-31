# Finanças

App Flutter para categorizar gastos do cartão de crédito e entender onde o dinheiro está indo.

**Desenvolvido por Wellysson Nascimento Rocha**

## Recursos

- Lançamento manual de gastos
- Importação de fatura CSV com sugestão de categoria
- Dashboard mensal por categoria (gráfico + ranking)
- Categorias padrão: Supermercado, Saúde, Transportes, Moradia, Lazer, Educação, Restaurantes, Assinaturas, Outros
- Cadastro de cartões
- Dados 100% locais (Hive) — Android e Web

## Como rodar

Requer Flutter no PATH (SDK instalado em `C:\flutter` neste ambiente).

```bash
flutter pub get
flutter run -d chrome
# ou
flutter run -d android
```

## Importar fatura

1. Exporte a fatura do banco em CSV
2. No app, toque no ícone de upload
3. Ajuste as colunas de data, descrição e valor se necessário
4. Revise as categorias sugeridas e confirme a importação

Há um CSV de exemplo em `assets/sample_fatura.csv`.
