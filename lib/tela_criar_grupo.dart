import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CriarGrupoTela extends StatefulWidget {
  const CriarGrupoTela({super.key});

  @override
  State<CriarGrupoTela> createState() => _CriarGrupoTelaState();
}

class _CriarGrupoTelaState extends State<CriarGrupoTela> {
  static const String _baseUrl =
      'https://us-central1-nossas-contas-app-c432d.cloudfunctions.net/api';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeGrupoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  // Estrutura interna para cada membro
  final List<_MembroForm> _membros = [ _MembroForm() ];

  bool _salvando = false;

  @override
  void dispose() {
    _nomeGrupoController.dispose();
    _descricaoController.dispose();
    for (final m in _membros) {
      m.nomeController.dispose();
      m.emailController.dispose();
    }
    super.dispose();
  }

  void _adicionarMembro() {
    setState(() {
      _membros.add(_MembroForm());
    });
  }

  void _removerMembro(int index) {
    if (_membros.length == 1) return; // sempre deixa pelo menos 1 linha
    setState(() {
      final m = _membros.removeAt(index);
      m.nomeController.dispose();
      m.emailController.dispose();
    });
  }

  Future<void> _salvarGrupo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final membrosValidos = _membros
        .where((m) =>
            m.nomeController.text.trim().isNotEmpty &&
            m.emailController.text.trim().isNotEmpty)
        .map((m) => {
              'nome': m.nomeController.text.trim(),
              'email': m.emailController.text.trim(),
            })
        .toList();

    if (membrosValidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma pessoa no grupo.')),
      );
      return;
    }

    final payload = {
      'nome': _nomeGrupoController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'membros': membrosValidos,
    };

    setState(() {
      _salvando = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/grupos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo criado com sucesso.')),
        );
        Navigator.of(context).pop(true); // volta indicando sucesso
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao criar grupo (${response.statusCode}).',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Novo Grupo',
          style: TextStyle(color: Colors.black87),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
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
                            controller: _nomeGrupoController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do grupo',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Informe o nome do grupo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descricaoController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição (opcional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Pessoas do grupo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _membros.length,
                            itemBuilder: (context, index) {
                              final membro = _membros[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: membro.nomeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nome',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: membro.emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'E-mail',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _removerMembro(index),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _adicionarMembro,
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar pessoa'),
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
                                            AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Criar grupo',
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

class _MembroForm {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
}
