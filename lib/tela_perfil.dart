import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class PerfilTela extends StatelessWidget {
  const PerfilTela({super.key});

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
      ),
      backgroundColor: Colors.grey[50],
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Meu Perfil'),
            subtitle: const Text('Seus dados e informações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MeuPerfilTela()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Gerenciar Categorias'),
            subtitle: const Text('Adicione ou remova categorias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaginaDeExemplo(
                    titulo: 'Gerenciar Categorias',
                    conteudo: 'Funcionalidade a ser implementada.',
                  ),
                ),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}



class MeuPerfilTela extends StatefulWidget {
  const MeuPerfilTela({super.key});

  @override
  State<MeuPerfilTela> createState() => _MeuPerfilTelaState();
}

class _MeuPerfilTelaState extends State<MeuPerfilTela> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }


  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _nomeController.text = prefs.getString('nome_perfil') ?? '';
      _emailController.text = prefs.getString('email_perfil') ?? '';
      _telefoneController.text = prefs.getString('telefone_perfil') ?? '';
    });
  }


  Future<void> _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nome_perfil', _nomeController.text);
    await prefs.setString('email_perfil', _emailController.text);
    await prefs.setString('telefone_perfil', _telefoneController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados salvos com sucesso!')),
    );

    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _telefoneController,
            decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _salvarDados,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueAccent,
            ),
            child: const Text('Salvar Alterações', style: TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }
}

class PaginaDeExemplo extends StatelessWidget {
  final String titulo;
  final String conteudo;
  const PaginaDeExemplo({super.key, required this.titulo, required this.conteudo});

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
      ),
      body: Center(child: Text(conteudo, style: const TextStyle(fontSize: 20))),
    );
  }
}