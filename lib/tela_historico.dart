import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  static const String _baseUrl =
      'https://us-central1-nossas-contas-app-c432d.cloudfunctions.net/api';

  List<Map<String, dynamic>> _transacoes = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final response = await http.get(Uri.parse("$_baseUrl/transacoes"));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _transacoes = data.map((t) {
            return {
              'id': t['id'],
              'descricao': t['descricao'],
              'valor': (t['valor'] as num).toDouble(),
              'tipo': t['tipo'],
              'categoria': t['categoria'],
            };
          }).toList();

          _carregando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro ao carregar (${response.statusCode})';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar transações.';
        _carregando = false;
      });
    }
  }

  Map<String, double> get gastosPorCategoria {
    final Map<String, double> dados = {};
    for (var t in _transacoes) {
      if (t['tipo'] == 'Despesa') {
        final categoria = t['categoria'];
        final valor = t['valor'] as double;
        dados.update(categoria, (v) => v + valor.abs(),
            ifAbsent: () => valor.abs());
      }
    }
    return dados;
  }

  @override
  Widget build(BuildContext context) {
    final double saldoTotal =
        _transacoes.fold(0.0, (sum, item) => sum + (item['valor'] as double));

    final dadosGrafico = gastosPorCategoria;
    final totalGastos = dadosGrafico.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/logo_splash.png', height: 32),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : _buildDashboard(saldoTotal, dadosGrafico, totalGastos),
    );
  }

  Widget _buildDashboard(
      double saldoTotal, Map<String, double> dadosGrafico, double totalGastos) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSaldoCard(saldoTotal),
        const SizedBox(height: 32),
        _buildPieChart(dadosGrafico, totalGastos),
        const SizedBox(height: 30),
        _buildLegenda(dadosGrafico),
        const SizedBox(height: 32),
        const Text(
          'Transações Recentes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTransacoesList(),
      ],
    );
  }

  Widget _buildSaldoCard(double saldoTotal) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saldo Atual',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              'R\$ ${saldoTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> dados, double totalGastos) {
    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2.0,
          centerSpaceRadius: 40.0,
          sections: dados.entries.map((entry) {
            final percentual = totalGastos > 0
                ? (entry.value / totalGastos) * 100
                : 0.0;

            return PieChartSectionData(
              color: Colors.primaries[
                  dados.keys.toList().indexOf(entry.key) %
                      Colors.primaries.length],
              value: entry.value,
              title: '${percentual.toStringAsFixed(1)}%',
              radius: 80.0,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegenda(Map<String, double> dados) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: dados.keys.map((categoria) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              color: Colors.primaries[
                  dados.keys.toList().indexOf(categoria) %
                      Colors.primaries.length],
            ),
            const SizedBox(width: 6),
            Text(categoria),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTransacoesList() {
    return Column(
      children: _transacoes.map((t) {
        final valor = t['valor'] as double;
        final tipo = t['tipo'];

        return Card(
          child: ListTile(
            leading: Icon(
              tipo == 'Receita' ? Icons.arrow_upward : Icons.arrow_downward,
              color: tipo == 'Receita' ? Colors.green : Colors.red,
            ),
            title: Text(t['descricao']),
            subtitle: Text(t['categoria']),
            trailing: Text(
              'R\$ ${valor.abs().toStringAsFixed(2)}',
              style: TextStyle(
                  color: tipo == 'Receita' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
