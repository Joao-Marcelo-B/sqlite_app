import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exemplo SQLite',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: MyHomePage(title: 'App de Entregas'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //criação do objeto que referencia o banco de dados
  late Future<Database> database;
// criação dos controladores de texto
  final idEntregaController = TextEditingController();
  final nomeDestinatarioController = TextEditingController();
  final enderecoController = TextEditingController();
  final descricaoController = TextEditingController();
  final statusController = TextEditingController();

  //função para limpar os campos do formulário
  void clear() {
    idEntregaController.clear();
    nomeDestinatarioController.clear();
    enderecoController.clear();
    descricaoController.clear();
    statusController.clear();
  }

  // define o estado inicial do aplicativo.
  //A função initBD é chamada dentro de initState porque initState não pode ser
  //um método assíncrono. Assim, criamos o métodos ass´ncrono fora de initSate
  @override
  void initState()  {
    super.initState();
    initBD();
  }
// função para iniciar o banco de dados
  Future<void> initBD() async{
    //abre o banco de dados no diretório padrão de banco de dados da plataforma
    database = openDatabase(
      join(await getDatabasesPath(), 'app_sqlite.db'),
      //aso o banco de dados não exista, cria-o especificando a nova versão
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE entregas(id_entrega INTEGER PRIMARY KEY AUTOINCREMENT, nome_destinatario TEXT, endereco TEXT, descricao TEXT, status TEXT)',
        );
      },
      version: 1,
    );
  }
//função para inserir um novo registro na tabela entregas do banco de dados
  Future<void> insertEntrega(Entrega entrega) async {
    //carrega o banco de dados
    final db = await database;
    //executa o método de inserção
    await db.insert(
      'entregas',
      // a função toMap está implementada no final deste código
      //Sua finalidade é mapear o objeto entrega na estrutura adequada do banco de dados
      entrega.toMap(),
      //evita erros, caso o regsitro seja inserido mais de uma vez
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
//função para listar todas as entregas
  //esta função retorna uma lista de entregas
  Future<List<Entrega>> listEntregas() async {
    final db = await database;
    //cria um objeto para mapear os dados retornados da consulta ao banco de dados em um objeto do tipo List
    final List<Map<String, Object?>> entregaMaps = await db.query('entregas');
    //percorre a lista entregaMaps, retornando todos os registros
    return List.generate(entregaMaps.length, (i) {
      return Entrega(
        idEntrega: entregaMaps[i]['id_entrega'] as int,
        nomeDestinatario: entregaMaps[i]['nome_destinatario'] as String,
        descricao: entregaMaps[i]['descricao'] as String,
        endereco: entregaMaps[i]['endereco'] as String,
        status: entregaMaps[i]['status'] as String,
      );
    });
  }
//função para atualizar um registro de Entrega
  Future<void> updateEntrega(Entrega entrega) async {
    //carrega o banco de dados
    final db = await database;
    //executa o método de atualização do registro apontado pelo id, mapeando para o banco de dados
    //
    await db.update(
      'entregas',
      entrega.toMap(),
      where: 'id_entrega = ?',
      whereArgs: [entrega.idEntrega],
    );
  }
//função para excluir um registro
  Future<void> deleteEntrega(int id) async {
    //carrega o banco de dados
    final db = await database;
    //executa o método de exclusão do registro apontado pelo id
    await db.delete(
      'entregas',
      where: 'id_entrega = ?',
      whereArgs: [id],
    );
  }

  //criação do layout da interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: nomeDestinatarioController,
              decoration: InputDecoration(labelText: 'Nome Destinatário'),
            ),
            TextField(
              controller: enderecoController,
              decoration: InputDecoration(labelText: 'Endereço'),
            ),
            TextField(
              controller: descricaoController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: statusController,
              decoration: InputDecoration(labelText: 'Status'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    var entrega = Entrega(
                      idEntrega: null,
                      nomeDestinatario: nomeDestinatarioController.text,
                      endereco: enderecoController.text,
                      descricao: descricaoController.text,
                      status: statusController.text,
                    );
                    await insertEntrega(entrega);
                    setState(() {});
                  },
                  child: Text('Inserir'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    var entrega = Entrega(
                      idEntrega: int.parse(idEntregaController.text),
                      endereco: enderecoController.text,
                      nomeDestinatario: nomeDestinatarioController.text,
                      descricao: descricaoController.text,
                      status: statusController.text,
                    );
                    await updateEntrega(entrega);
                    setState(() {});
                  },
                  child: Text('Atualizar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await deleteEntrega(int.parse(idEntregaController.text));
                    setState(() {});
                  },
                  child: Text('Excluir'),
                ),
                ElevatedButton(
                  onPressed: ()  {
                    clear();
                    setState(() {});
                  },
                  child: Text('Limpar'),
                ),
              ],
            ),
            Expanded(
              //cria um widget para conter dados Future. Nesta caso, as entregas cadastradas
              //Um snapshot se refere à lista de entregas retornada pela função definida no parâmetro future
              child: FutureBuilder<List<Entrega>>(
                future: listEntregas(),
                builder: (context, snapshot) {
                  //se o snapshot não conte´m dados
                  if (snapshot.hasError) {
                    return const Center(child: Text('Não existem entregas cadastradas.'));
                  }
                  //se o snapshot contém dados
                  else if (snapshot.hasData) {
                    //retorna um ListView apresentando todas as entregas cadastradas
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        //retorna um bloco de dados na lista
                        return ListTile(
                          title: Text(snapshot.data![index].nomeDestinatario),
                          subtitle: Text('Entrega: ${snapshot.data![index].descricao}\nStatus: ${snapshot.data![index].status}'),
                          //ao tocar (tap) em um elemento da lista, exibe seus dados nos controladores de texto
                          onTap: () {
                            idEntregaController.text = snapshot.data![index].idEntrega.toString();
                            enderecoController.text = snapshot.data![index].endereco;
                            nomeDestinatarioController.text = snapshot.data![index].nomeDestinatario;
                            descricaoController.text = snapshot.data![index].descricao;
                            statusController.text = snapshot.data![index].status;
                          },
                        );
                      },
                    );
                  } else {
                    //apresenta uma animação de 'carregando' enquanto os dados future não são obtidos
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//classe modelo de Entrega
class Entrega {
  final int? idEntrega;
  final String nomeDestinatario;
  final String endereco;
  final String descricao;
  final String status;

//método contrutor da classe modelo
  Entrega({
    required this.idEntrega,
    required this.nomeDestinatario,
    required this.endereco,
    required this.descricao,
    required this.status,
  });

  //função para mapear um objeto da classe Entrega no formato do banco de dados chave: valor (JSON)
Map<String, Object?> toMap() {
  final map = {
    'nome_destinatario': nomeDestinatario,
    'endereco': endereco,
    'descricao': descricao,
    'status': status,
  };
  if (idEntrega != null) {
    map['id_entrega'] = idEntrega.toString();
  }
  return map;
}

}