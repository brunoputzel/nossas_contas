import 'package:flutter/material.dart';
import 'tela_dashboard.dart'; 
import 'tela_historico.dart'; 
import 'tela_add_transacao.dart';
import 'tela_perfil.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0; 

  List<Map<String, dynamic>> _transacoes = [
    {'descricao': 'Salário', 'valor': 4000.00, 'tipo': 'Receita', 'categoria': 'Salário'},
    {'descricao': 'Aluguel', 'valor': -1500.00, 'tipo': 'Despesa', 'categoria': 'Moradia'},
    {'descricao': 'Supermercado', 'valor': -350.50, 'tipo': 'Despesa', 'categoria': 'Alimentação'},
    {'descricao': 'Cinema', 'valor': -80.00, 'tipo': 'Despesa', 'categoria': 'Lazer'},
  ];

  void _adicionarTransacao(Map<String, dynamic> novaTransacao) {
    setState(() {
      // ATUALIZADO: Cria uma nova lista em vez de modificar a antiga
      _transacoes = [novaTransacao, ..._transacoes];
    });
  }

  void _removerTransacao(Map<String, dynamic> transacaoParaRemover) {
    setState(() {
      // ATUALIZADO: Cria uma nova lista, filtrando o item a ser removido
      _transacoes = _transacoes.where((t) => t != transacaoParaRemover).toList();
    });
  }

  void _abrirTelaAdicionarTransacao() async {
    final novaTransacao = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AddTransacaoTela()),
    );
    if (novaTransacao != null) {
      _adicionarTransacao(novaTransacao);
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> telas = [
      DashboardScreen(transacoes: _transacoes), 
      HistoricoTela(
        todasTransacoes: _transacoes,
        onExcluir: _removerTransacao,
      ), 
      const PerfilTela(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: telas,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirTelaAdicionarTransacao,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}