import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importa para a AppBar

class HistoricoTela extends StatefulWidget {
  final List<Map<String, dynamic>> todasTransacoes;
  final Function(Map<String, dynamic>) onExcluir;

  const HistoricoTela({
    super.key,
    required this.todasTransacoes,
    required this.onExcluir,
  });

  @override
  State<HistoricoTela> createState() => _HistoricoTelaState();
}

class _HistoricoTelaState extends State<HistoricoTela> {
  late List<Map<String, dynamic>> _transacoesFiltradas;
  String _filtroAtivo = 'Todos';

  @override
  void initState() {
    super.initState();
    _transacoesFiltradas = List.from(widget.todasTransacoes);
  }
  
  @override
  void didUpdateWidget(covariant HistoricoTela oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.todasTransacoes != oldWidget.todasTransacoes) {
      _aplicarFiltro(_filtroAtivo);
    }
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroAtivo = filtro;
      if (filtro == 'Receitas') {
        _transacoesFiltradas = widget.todasTransacoes.where((t) => t['tipo'] == 'Receita').toList();
      } else if (filtro == 'Despesas') {
        _transacoesFiltradas = widget.todasTransacoes.where((t) => t['tipo'] == 'Despesa').toList();
      } else {
        _transacoesFiltradas = List.from(widget.todasTransacoes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- APP BAR CORRIGIDA ---
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        title: Image.asset(
          'assets/logo_splash.png',
          height: 32,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(
          color: Colors.black54, 
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(label: const Text('Todos'), selected: _filtroAtivo == 'Todos', onSelected: (_) => _aplicarFiltro('Todos')),
                FilterChip(label: const Text('Receitas'), selected: _filtroAtivo == 'Receitas', onSelected: (_) => _aplicarFiltro('Receitas')),
                FilterChip(label: const Text('Despesas'), selected: _filtroAtivo == 'Despesas', onSelected: (_) => _aplicarFiltro('Despesas')),
              ],
            ),
            const Divider(),
            Expanded(
              child: _transacoesFiltradas.isEmpty
                  ? const Center(child: Text('Nenhuma transação encontrada.'))
                  : ListView.builder(
                      itemCount: _transacoesFiltradas.length,
                      itemBuilder: (context, index) {
                        final transacao = _transacoesFiltradas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: Icon(
                              transacao['tipo'] == 'Receita' ? Icons.arrow_upward : Icons.arrow_downward,
                              color: transacao['tipo'] == 'Receita' ? Colors.green : Colors.red,
                            ),
                            title: Text(transacao['descricao'] as String? ?? ''),
                            subtitle: Text(transacao['categoria'] as String? ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'R\$ ${(transacao['valor'] as double).abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: transacao['tipo'] == 'Receita' ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    widget.onExcluir(transacao);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${transacao['descricao']} excluído(a).')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}