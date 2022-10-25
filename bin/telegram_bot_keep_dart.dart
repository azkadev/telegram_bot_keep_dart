// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';
import 'dart:io';

import 'package:telegram_client/telegram_client.dart';
import 'package:alfred/alfred.dart';
import 'package:galaxeus_lib/galaxeus_lib.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  Directory current_dir = Directory.current;
  String db_bot_api = p.join(current_dir.path, "bot_api");
  Directory dir_bot_api = Directory(db_bot_api);
  if (!dir_bot_api.existsSync()) {
    dir_bot_api.createSync(recursive: true);
  }
  int port = int.parse(Platform.environment["PORT"] ?? "8080");
  String host = Platform.environment["HOST"] ?? "0.0.0.0";

  String token_bot = "5604742186:AAH40qT65BbJstJJVnKgN24o8IDLkT-uYmM";
  TelegramBotApiServer telegramBotApiServer = TelegramBotApiServer();
  telegramBotApiServer.run(
    executable: "./telegram_bot_api",
    arguments: telegramBotApiServer.optionsParameters(
      apiid: "3945474",
      apihash: "200e85971cc662a40385e0e60c7f7fac",
      httpport: "9000",
      dir: dir_bot_api.path,
    ),
  );
  TelegramBotApi tg = TelegramBotApi(token_bot, clientOption: {
    "api": "http://0.0.0.0:9000/",
  });

  await tg.request("setWebhook", parameters: {
    "url": "http://${host}:${port}",
  });
  Alfred app = Alfred();
  EventEmitter eventEmitter = EventEmitter();

  eventEmitter.on("update", null, (ev, context) async {
    if (ev.eventData is UpdateBot) {
      UpdateBot updateBot = ev.eventData as UpdateBot;
      String token_bot = updateBot.token_bot;
      String type_bot = updateBot.type_bot;
      Map update = updateBot.body;

      Future<Map<dynamic, dynamic>> request(
        String method, {
        Map<dynamic, dynamic>? parameters,
        bool is_form = false,
        String? tokenBot,
        String? urlApi,
        String? clientType,
        void Function(int, int)? onUploadProgress,
      }) async {
        return await tg.request(
          method,
          parameters: parameters,
          is_form: is_form,
          tokenBot: token_bot,
          urlApi: urlApi,
          clientType: clientType,
          onUploadProgress: onUploadProgress,
        );
      }

      if (update["message"] is Map) {
        Map msg = (update["message"] as Map);
        Map from = msg["from"];
        int from_id = from["id"];
        Map chat = msg["chat"];
        int chat_id = chat["id"];
        String? text = msg["text"];
        await request("sendMessage", parameters: {
          "chat_id": chat_id,
          "text": text,
          "reply_markup": {
            "inline_keyboard": [
              [
                {"text": "Github", "url": "https://github.com/azkadev"}
              ]
            ]
          }
        });
        return;
      }
    }
  });

  app.all("/", (req, res) async {
    if (req.method.toLowerCase() != "post") {
      return res.json({"@type": "ok", "message": "server run normal"});
    } else {
      late String token_bot = "";
      late String type_bot = "";
      Map query = req.uri.queryParameters;
      if (query.containsKey("type_bot")) {
        type_bot = query["type_bot"];
      }
      if (query.containsKey("token_bot")) {
        token_bot = query["token_bot"];
      } else {
        return res.json({"@type": "error", "message": "server run normal"});
      }
      Map body = await req.bodyAsJsonMap;
      eventEmitter.emit(
        "update",
        null,
        UpdateBot(
          body: body,
          token_bot: token_bot,
          type_bot: type_bot,
        ),
      );
      return res.json({"@type": "ok", "message": "server run normal"});
    }
  });

  await app.listen(port, host);

  print("Server run on ${app.server!.address.address}}");
}

class UpdateBot {
  late Map body;
  late String token_bot;
  late String type_bot;
  UpdateBot({
    required this.body,
    required this.token_bot,
    required this.type_bot,
  });
}
