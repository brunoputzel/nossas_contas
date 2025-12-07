import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transacoes;

  const DashboardScreen({super.key, required this.transacoes});

  Map<String, double> get gastosPorCategoria {
    final Map<String, double> dados = {};
    for (var transacao in transacoes) {
      if (transacao['tipo'] == 'Despesa') {
        final categoria = transacao['categoria'] as String;
        final valor = transacao['valor'] as double;
        dados.update(categoria, (value) => value + valor.abs(),
            ifAbsent: () => valor.abs());
      }
    }
    return dados;
  }

  @override
  Widget build(BuildContext context) {
    final double saldoTotal = transacoes.fold(
        0.0, (somaAnterior, item) => somaAnterior + (item['valor'] as double));

    final dadosGrafico = gastosPorCategoria;
    final totalGastos =
        dadosGrafico.values.fold(0.0, (sum, item) => sum + item);

    return Scaffold(
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
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 900;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Centraliza o conteúdo no desktop e limita largura
                maxWidth: isDesktop ? 950 : constraints.maxWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  /// ---------- SALDO ----------
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(child: _buildSaldoCard(saldoTotal)),
                      ],
                    )
                  else
                    _buildSaldoCard(saldoTotal),

                  const SizedBox(height: 32),

                  /// ---------- GRÁFICO + LEGENDA ----------
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildPieChart(dadosGrafico, totalGastos),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _buildLegenda(dadosGrafico),
                        ),
                      ],
                    )
                  else ...[
                    const Text(
                      'Gastos por Categoria',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    _buildPieChart(dadosGrafico, totalGastos),
                    const SizedBox(height: 30),
                    _buildLegenda(dadosGrafico),
                  ],

                  const SizedBox(height: 32),

                  /// ---------- TRANSACOES ----------
                  const Text(
                    'Transações Recentes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTransacoesList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ================================================================
  ///  WIDGETS MODULARES (mantém o código organizado e responsivo)
  /// ================================================================

  Widget _buildSaldoCard(double saldoTotal) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
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

  /// ---------- GRÁFICO ----------
  Widget _buildPieChart(Map<String, double> dados, double totalGastos) {
    return Column(
      children: [
        const Text(
          'Gastos por Categoria',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 240,
          child: PieChart(
            PieChartData(
              sections: dados.entries.map((entry) {
                final percentual =
                    totalGastos > 0 ? (entry.value / totalGastos) * 100 : 0.0;

                return PieChartSectionData(
                  color: Colors.primaries[
                      dados.keys.toList().indexOf(entry.key) %
                          Colors.primaries.length],
                  value: entry.value,
                  title: '${percentual.toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }

  /// ---------- LEGENDA ----------
  Widget _buildLegenda(Map<String, double> dados) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.start,
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

  /// ---------- LISTA DE TRANSACOES ----------
  Widget _buildTransacoesList() {
    return Column(
      children: transacoes.map((transacao) {
        final valor = transacao['valor'] as double? ?? 0.0;
        final tipo = transacao['tipo'] as String? ?? 'Despesa';

        return Card(
          child: ListTile(
            leading: Icon(
              tipo == 'Receita' ? Icons.arrow_upward : Icons.arrow_downward,
              color: tipo == 'Receita' ? Colors.green : Colors.red,
            ),
            title: Text(transacao['descricao'] as String? ?? ''),
            subtitle: Text(transacao['categoria'] as String? ?? ''),
            trailing: Text(
              'R\$ ${valor.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: tipo == 'Receita' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
