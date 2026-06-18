import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BotCreatorScreen(),
    );
  }
}

class BotCreatorScreen extends StatefulWidget {
  const BotCreatorScreen({super.key});

  @override
  State<BotCreatorScreen> createState() => _BotCreatorScreenState();
}

class _BotCreatorScreenState extends State<BotCreatorScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isOnline = false;
  List<String> logs = [];
  NyxxGateway? _client;

  void _addLog(String message) {
    setState(() {
      logs.add("[${DateTime.now().toString().substring(11, 19)}] $message");
    });
  }

  void _startBot() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _addLog("Erreur : Token vide");
      return;
    }

    _addLog("Connexion en cours...");

    try {
      _client = await Nyxx.connectGateway(
        token,
        GatewayIntents.allUnprivileged | GatewayIntents.messageContent,
      );

      _client!.onReady.listen((event) {
        setState(() {
          _isOnline = true;
        });
        _addLog("Bot connecte");
      });

      _client!.onMessageCreate.listen((event) async {
        // Securite pour eviter que le bot ne se reponde a lui-meme
        if (event.message.author.id == _client!.user.id) return;

        _addLog("Message recu de ${event.message.author.username}");

        // Commande de test basique
        if (event.message.content == "!ping") {
          await event.message.channel.sendMessage(MessageBuilder(
            content: "Pong !",
          ));
          _addLog("Reponse ping envoyee");
        }
      });

    } catch (e) {
      _addLog("Erreur : $e");
    }
  }

  void _stopBot() async {
    if (_client != null) {
      await _client!.close();
      setState(() {
        _isOnline = false;
      });
      _addLog("Bot arrete");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bot Creator")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_isOnline ? "Statut : En ligne" : "Statut : Hors ligne"),
            const SizedBox(height: 10),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: "Token Discord"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isOnline ? null : _startBot,
              child: const Text("DEMARRER"),
            ),
            ElevatedButton(
              onPressed: _isOnline ? _stopBot : null,
              child: const Text("ARRETER"),
            ),
            const SizedBox(height: 20),
            const Text("Logs :"),
            Expanded(
              child: Container(
                color: Colors.black12,
                width: double.infinity,
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(logs[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
