import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _baseUrl =
    'https://us-central1-nossas-contas-app-c432d.cloudfunctions.net/api';

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _grupos = [];

  @override
  void initState() {
    super.initState();
    _carregarGrupos();
  }

  Future<void> _carregarGrupos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/grupos'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

        _grupos = data.map((item) {
          final map = item as Map<String, dynamic>;

          final int membrosCountFromApi = (map['membrosCount'] as int?) ?? 0;
          final int lancamentosCountFromApi =
              (map['lancamentosCount'] as int?) ?? 0;

          final int membrosFromList =
              (map['membros'] as List?)?.length ?? 0;
          final int lancamentosFromList =
              (map['transacoes'] as List?)?.length ?? 0;

          final int membrosCount = membrosCountFromApi != 0
              ? membrosCountFromApi
              : membrosFromList;

          final int lancamentosCount = lancamentosCountFromApi != 0
              ? lancamentosCountFromApi
              : lancamentosFromList;

          return {
            'id': map['id'],
            'nome': map['nome'] ?? '',
            'descricao': map['descricao'] ?? '',
            'membrosCount': membrosCount,
            'lancamentosCount': lancamentosCount,
            'membros': map['membros'] ?? [],
          };
        }).toList();
      } else {
        _erro = 'Erro ao carregar grupos (${response.statusCode})';
        _grupos = [];
      }
    } catch (e) {
      _erro = 'Erro ao carregar grupos. Tente novamente.';
      _grupos = [];
    }

    if (mounted) {
      setState(() {
        _carregando = false;
      });
    }
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? grupo}) async {
    final bool? precisaAtualizar = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GrupoFormScreen(grupo: grupo),
      ),
    );

    if (precisaAtualizar == true) {
      _carregarGrupos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black54),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Novo grupo',
            onPressed: () => _abrirFormulario(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.group_add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? Center(child: Text(_erro!))
                : _grupos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Nenhum grupo cadastrado.'),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _abrirFormulario(),
                              icon: const Icon(Icons.group_add),
                              label: const Text('Criar primeiro grupo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _grupos.length,
                        itemBuilder: (context, index) {
                          final grupo = _grupos[index];
                          final String nome = grupo['nome'] as String? ?? '';
                          final String descricao =
                              grupo['descricao'] as String? ?? '';

                          final int membrosCount =
                              grupo['membrosCount'] as int? ?? 0;
                          final int lancamentosCount =
                              grupo['lancamentosCount'] as int? ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (descricao.isNotEmpty)
                                    Text(
                                      descricao,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$membrosCount membro(s)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar grupo',
                                onPressed: () =>
                                    _abrirFormulario(grupo: grupo),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class GrupoFormScreen extends StatefulWidget {
  final Map<String, dynamic>? grupo;

  const GrupoFormScreen({super.key, this.grupo});

  @override
  State<GrupoFormScreen> createState() => _GrupoFormScreenState();
}

class _GrupoFormScreenState extends State<GrupoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();

  List<Map<String, String>> _membros = [];
  bool _salvando = false;

  bool get isEdicao => widget.grupo != null;

  @override
  void initState() {
    super.initState();
    if (isEdicao) {
      final g = widget.grupo!;
      _nomeController.text = g['nome'] ?? '';
      _descricaoController.text = g['descricao'] ?? '';

      final membros = g['membros'];
      if (membros is List) {
        _membros = membros
            .map((m) => {
                  'nome': (m['nome'] ?? '').toString(),
                  'email': (m['email'] ?? '').toString(),
                })
            .toList()
            .cast<Map<String, String>>();
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      final body = jsonEncode({
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'membros': _membros,
      });

      http.Response response;
      if (isEdicao) {
        final id = widget.grupo!['id'] as String;
        response = await http.put(
          Uri.parse('$_baseUrl/grupos/$id'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      } else {
        response = await http.post(
          Uri.parse('$_baseUrl/grupos'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar grupo (${response.statusCode}).',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão ao salvar grupo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  void _adicionarMembro() {
    setState(() {
      _membros.add({'nome': '', 'email': ''});
    });
  }

  void _removerMembro(int index) {
    setState(() {
      _membros.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final titulo = isEdicao ? 'Editar grupo' : 'Novo grupo';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 700;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 700 : double.infinity,
                ),
                child: Card(
                  elevation: isWide ? 4 : 0,
                  shape: isWide
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        )
                      : null,
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 24 : 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do grupo',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o nome do grupo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descricaoController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Descrição (opcional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Membros',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._membros.asMap().entries.map((entry) {
                            final index = entry.key;
                            final membro = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: membro['nome'],
                                      decoration: const InputDecoration(
                                        labelText: 'Nome',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) =>
                                          _membros[index]['nome'] = val,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: membro['email'],
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) =>
                                          _membros[index]['email'] = val,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _removerMembro(index),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _adicionarMembro,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Adicionar membro'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _salvando ? null : _salvarGrupo,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blueAccent,
                              ),
                              child: _salvando
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Salvar grupo',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
