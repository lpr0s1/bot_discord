import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const BotCreatorScreen(),
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
  final TextEditingController _prefixController = TextEditingController(text: "!");
  
  bool _isOnline = false;
  bool _moderationEnabled = true;
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
      _addLog("Erreur : Token vide !");
      return;
    }

    _addLog("Connexion a Discord en cours...");

    try {
      _client = await Nyxx.connectGateway(
        token,
        GatewayIntents.allUnprivileged | GatewayIntents.messageContent,
      );

      _client!.onReady.listen((event) {
        setState(() {
          _isOnline = true;
        });
        _addLog("Bot connecte sous le pseudo : ${event.user.username}");
        
        _client!.updatePresence(PresenceBuilder(
          status: CurrentStatus.online,
          isAfk: false,
          activities: [ActivityBuilder(name: "Bot Android Actif", type: ActivityType.game)],
        ));
      });

      _client!.onMessageCreate.listen((event) async {
        if (event.message.author.isBot) return;

        _addLog("${event.message.author.username}: ${event.message.content}");

        if (_moderationEnabled) {
          final content = event.message.content.toLowerCase();
          if (content.contains("merde") || content.contains("connard")) {
            await event.message.delete();
            await event.message.channel.sendMessage(MessageBuilder(
              content: "<@${event.message.author.id}>, merci de rester poli !",
            ));
            _addLog("Moderation : Message supprime.");
            return;
          }
        }

        if (event.message.content == "${_prefixController.text}ping") {
          await event.message.channel.sendMessage(MessageBuilder(
            content: "Pong !",
            replyId: event.message.id,
          ));
          _addLog("Commande ping executee.");
        }
      });

    } catch (e) {
      _addLog("Erreur de connexion : $e");
    }
  }

  void _stopBot() async {
    if (_client != null) {
      await _client!.close();
      setState(() {
        _isOnline = false;
      });
      _addLog("Le bot a ete arrete.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Createur Bot Discord APK")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _isOnline ? "Statut : En ligne" : "Statut : Hors ligne",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: "Token du Bot Discord"),
              obscureText: true,
            ),
            TextField(
              controller: _prefixController,
              decoration: const InputDecoration(labelText: "Prefixe des commandes"),
            ),
            SwitchListTile(
              title: const Text("Activer la moderation automatique"),
              value: _moderationEnabled,
              onChanged: (val) => setState(() => _moderationEnabled = val),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isOnline ? null : _startBot,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("DEMARRER"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isOnline ? _stopBot : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("ARRETER"),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text("Console d evenements en direct :"),
            Expanded(
              child: Container(
                color: Colors.black,
                width: double.infinity,
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      logs[index], 
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')
                    ),
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
