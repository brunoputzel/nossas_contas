// lib/tela_historico.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class HistoricoTela extends StatefulWidget {
  const HistoricoTela({super.key});

  @override
  State<HistoricoTela> createState() => HistoricoTelaState();
}

class HistoricoTelaState extends State<HistoricoTela> {
  static const String _baseUrl =
      'https://us-central1-nossas-contas-app-c432d.cloudfunctions.net/api';

  List<Map<String, dynamic>> _todasTransacoes = [];
  List<Map<String, dynamic>> _transacoesFiltradas = [];
  String _filtroAtivo = 'Todos';
  bool _carregando = true;
  String? _erro;

  // Filtro por grupo
  List<Map<String, dynamic>> _grupos = [];
  String? _grupoFiltroId;
  bool _carregandoGrupos = false;
  String? _erroGrupos;

  @override
  void initState() {
    super.initState();
    _carregarTransacoes();
    _carregarGrupos();
  }

  // para o MainNavigator conseguir forçar reload
  Future<void> reload() async {
    await _carregarTransacoes();
  }

  Future<void> _carregarTransacoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/transacoes'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

        _todasTransacoes = data.map((item) {
          final map = item as Map<String, dynamic>;

          return {
            'id': map['id'],
            'descricao': map['descricao'] ?? '',
            'valor': (map['valor'] as num?)?.toDouble() ?? 0.0,
            'tipo': map['tipo'] ?? 'Despesa',
            'categoria': map['categoria'] ?? '',
            // importante: manter grupoId se vier da API
            'grupoId': map['grupoId'],
          };
        }).toList();

        _aplicarFiltro(_filtroAtivo, rebuild: false);
      } else {
        _erro = 'Erro ao carregar transações (${response.statusCode})';
        _transacoesFiltradas = [];
      }
    } catch (_) {
      _erro = 'Erro ao carregar transações. Tente novamente.';
      _transacoesFiltradas = [];
    }

    if (mounted) {
      setState(() {
        _carregando = false;
      });
    }
  }

  Future<void> _carregarGrupos() async {
    setState(() {
      _carregandoGrupos = true;
      _erroGrupos = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/grupos'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

        _grupos = data.map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'id': map['id'],
            'nome': map['nome'] ?? '',
          };
        }).toList();
      } else {
        _erroGrupos = 'Erro ao carregar grupos (${response.statusCode})';
        _grupos = [];
      }
    } catch (_) {
      _erroGrupos = 'Erro ao carregar grupos. Tente novamente.';
      _grupos = [];
    }

    if (!mounted) return;
    setState(() {
      _carregandoGrupos = false;
    });
  }

  void _aplicarFiltro(String filtro, {bool rebuild = true}) {
    _filtroAtivo = filtro;

    List<Map<String, dynamic>> base = List.from(_todasTransacoes);

    // filtro por grupo, se houver grupo selecionado
    if (_grupoFiltroId != null && _grupoFiltroId!.isNotEmpty) {
      base = base.where((t) => t['grupoId'] == _grupoFiltroId).toList();
    }

    // filtro por tipo
    if (filtro == 'Receitas') {
      base = base.where((t) => t['tipo'] == 'Receita').toList();
    } else if (filtro == 'Despesas') {
      base = base.where((t) => t['tipo'] == 'Despesa').toList();
    }

    if (rebuild) {
      setState(() {
        _transacoesFiltradas = base;
      });
    } else {
      _transacoesFiltradas = base;
    }
  }

  Future<void> _excluirTransacao(Map<String, dynamic> transacao) async {
    final id = transacao['id'] as String?;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir. ID da transação ausente.'),
        ),
      );
      return;
    }

    setState(() {
      _todasTransacoes.removeWhere((t) => t['id'] == id);
      _aplicarFiltro(_filtroAtivo, rebuild: false);
    });

    try {
      final response =
          await http.delete(Uri.parse('$_baseUrl/transacoes/$id'));

      if (response.statusCode != 200 && response.statusCode != 204) {
        await _carregarTransacoes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir transação na API.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${transacao['descricao']} excluído(a).'),
        ),
      );
    } catch (_) {
      await _carregarTransacoes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão ao excluir.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        iconTheme: const IconThemeData(
          color: Colors.black54,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _carregarTransacoes();
            },
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? Center(child: Text(_erro!))
                : Column(
                    children: [
                      // filtros de tipo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilterChip(
                            label: const Text('Todos'),
                            selected: _filtroAtivo == 'Todos',
                            onSelected: (_) => _aplicarFiltro('Todos'),
                          ),
                          FilterChip(
                            label: const Text('Receitas'),
                            selected: _filtroAtivo == 'Receitas',
                            onSelected: (_) => _aplicarFiltro('Receitas'),
                          ),
                          FilterChip(
                            label: const Text('Despesas'),
                            selected: _filtroAtivo == 'Despesas',
                            onSelected: (_) => _aplicarFiltro('Despesas'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // filtro por grupo
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _carregandoGrupos
                            ? const Text('Carregando grupos...')
                            : _erroGrupos != null
                                ? Text(
                                    _erroGrupos!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _grupoFiltroId,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Filtrar por grupo',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: [
                                            const DropdownMenuItem<String>(
                                              value: null,
                                              child: Text('Todos os grupos'),
                                            ),
                                            ..._grupos.map(
                                              (g) => DropdownMenuItem<String>(
                                                value: g['id'] as String,
                                                child: Text(
                                                  (g['nome'] as String?) ?? '',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (String? novoId) {
                                            setState(() {
                                              _grupoFiltroId = novoId;
                                            });
                                            _aplicarFiltro(_filtroAtivo);
                                          },
                                        ),
                                      ),
                                      if (_grupoFiltroId != null) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: 'Limpar filtro de grupo',
                                          onPressed: () {
                                            setState(() {
                                              _grupoFiltroId = null;
                                            });
                                            _aplicarFiltro(_filtroAtivo);
                                          },
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                      ),

                      const Divider(),
                      Expanded(
                        child: _transacoesFiltradas.isEmpty
                            ? const Center(
                                child: Text('Nenhuma transação encontrada.'),
                              )
                            : ListView.builder(
                                itemCount: _transacoesFiltradas.length,
                                itemBuilder: (context, index) {
                                  final transacao =
                                      _transacoesFiltradas[index];
                                  final double valor =
                                      (transacao['valor'] as double?) ?? 0.0;
                                  final String tipo =
                                      transacao['tipo'] as String? ??
                                          'Despesa';

                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 8.0),
                                    child: ListTile(
                                      leading: Icon(
                                        tipo == 'Receita'
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: tipo == 'Receita'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      title: Text(
                                        transacao['descricao'] as String? ??
                                            '',
                                      ),
                                      subtitle: Text(
                                        transacao['categoria'] as String? ??
                                            '',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'R\$ ${valor.abs().toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: tipo == 'Receita'
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                _excluirTransacao(transacao),
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
