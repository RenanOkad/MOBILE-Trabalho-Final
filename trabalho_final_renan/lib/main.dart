import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'produto.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100.0),
            SizedBox(height: 16.0),
            Text(
              'Meu App',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Produto> produtos = [
    Produto(nome: 'Carro', precoDolar: 100000.0),
    Produto(nome: 'Televisão', precoDolar: 820.0),
    Produto(nome: 'Celular', precoDolar: 1999.0),
    Produto(nome: 'Bicicleta', precoDolar: 3560.0),
  ];

  double taxaCambio = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTaxaCambio();
  }

  Future<void> _fetchTaxaCambio() async {
    final response = await http.get(
      Uri.parse(
          'https://api.twelvedata.com/time_series?symbol=USD/BRL&interval=1min&apikey=3d919b2f09ac4cb4be1bfb18bd496276'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final closeValue = double.parse(jsonData['values'][0]['close']);
      setState(() {
        taxaCambio = closeValue;
      });
    } else {
      throw Exception('Failed to load taxa de câmbio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Produtos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lista'),
              Tab(text: 'Adicionar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListaProdutos(
              produtos: produtos,
              taxaCambio: taxaCambio,
              onProdutoRemovido: _removerProduto,
              onProdutoDetalhes: _mostrarDetalhesProduto,
            ),
            AdicionarProduto(onProdutoAdicionado: _adicionarProduto),
          ],
        ),
      ),
    );
  }

  void _adicionarProduto(Produto produto) {
    setState(() {
      produtos.add(produto);
    });
  }

  void _removerProduto(int index) {
    setState(() {
      produtos.removeAt(index);
    });
  }

  void _mostrarDetalhesProduto(Produto produto) {
    final valorEmReal = produto.precoDolar * taxaCambio;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detalhes do Produto'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nome do Produto: ${produto.nome}'),
              Text('Taxa de Câmbio Aplicada: $taxaCambio'),
              Text('Valor em Dólar: \$${produto.precoDolar}'),
              Text('Valor em Real: R\$$valorEmReal'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

class ListaProdutos extends StatelessWidget {
  final List<Produto> produtos;
  final double taxaCambio;
  final Function(int) onProdutoRemovido;
  final Function(Produto) onProdutoDetalhes;

  ListaProdutos({
    required this.produtos,
    required this.taxaCambio,
    required this.onProdutoRemovido,
    required this.onProdutoDetalhes,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: produtos.length,
      itemBuilder: (context, index) {
        final produto = produtos[index];
        return Card(
          elevation: 5.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text(produto.nome),
            subtitle: Text('\$${produto.precoDolar.toString()}'),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _exibirDialogoConfirmacao(context, index),
            ),
            onTap: () {
              onProdutoDetalhes(produto);
            },
          ),
        );
      },
    );
  }

  Future<void> _exibirDialogoConfirmacao(BuildContext context, int index) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                onProdutoRemovido(index);
                Navigator.of(context).pop();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}


class AdicionarProduto extends StatefulWidget {
  final Function(Produto) onProdutoAdicionado;

  AdicionarProduto({required this.onProdutoAdicionado});

  @override
  _AdicionarProdutoState createState() => _AdicionarProdutoState();
}

class _AdicionarProdutoState extends State<AdicionarProduto> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(labelText: 'Nome do Produto'),
          ),
          TextField(
            controller: _precoController,
            decoration: const InputDecoration(labelText: 'Preço em Dólar'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              String nome = _nomeController.text;
              double preco = double.parse(_precoController.text);

              Produto novoProduto = Produto(nome: nome, precoDolar: preco);

              widget.onProdutoAdicionado(novoProduto);

              _nomeController.clear();
              _precoController.clear();
            },
            child: const Text('Adicionar Produto'),
          ),
        ],
      ),
    );
  }
}
