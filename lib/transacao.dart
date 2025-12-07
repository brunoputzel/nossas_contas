class Transacao {
  final String descricao;
  final double valor;
  final String tipo; // "Receita" ou "Despesa"

  Transacao({required this.descricao, required this.valor, required this.tipo});
}