import 'package:flutter/material.dart';
import 'tela_dashboard.dart';
import 'tela_historico.dart';
import 'tela_add_transacao.dart';
import 'tela_perfil.dart';
import 'tela_grupos.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();

  final GlobalKey<HistoricoTelaState> _historicoKey =
    GlobalKey<HistoricoTelaState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 0) {
        _dashboardKey.currentState?.reload();
      } else if (index == 1) {
    _historicoKey.currentState?.reload();
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      DashboardScreen(key: _dashboardKey),
      HistoricoTela(key: _historicoKey),
      const GruposScreen(),
      const PerfilTela(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: telas,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTransacaoTela(),
            ),
          );

          _dashboardKey.currentState?.reload();
          _historicoKey.currentState?.reload();
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
