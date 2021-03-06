import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ynotes/UI/utils/hiveExportImportUtils.dart';
import 'package:ynotes/classes.dart';
import 'package:ynotes/usefulMethods.dart';

import '../../main.dart';

class ExportPage extends StatefulWidget {
  @override
  _ExportPageState createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool exportPinnedHomework = false;
  bool exportReminders = false;
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: new Text(
          "Gestionnaire de sauvegarde",
          style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white : Colors.black),
          textAlign: TextAlign.center,
        ),
      ),
      body: Container(
        width: screenSize.size.width,
        height: screenSize.size.height,
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.2),
              width: screenSize.size.width / 5 * 4.8,
              height: screenSize.size.height / 10 * 2.5,
              child: AutoSizeText(
                "L'exportation de vos données vous permet de retrouver vos devoirs épinglés, vos évènements personnalisés et " +
                    "rappels sur un autre téléphone. L'assistant d'exportation va vous permettre d'exporter un fichier contenant toutes ces données dans un fichier .json, " +
                    "ces données seront importables à partir de ce même menu depuis un autre téléphone ou de celui à partir duquel vous effectuez l'exportation. " +
                    "Notez que vos données sont exportées en clair, il est recommandé de stocker ce fichier en sécurité et de ne pas le communiquer à quelqu'un d'autre. Notez que yNotes s'occupera automatiquement de fusionner les données sans perte.",
                style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white : Colors.black),
                minFontSize: 0,
                maxLines: 15,
                textAlign: TextAlign.justify,
              ),
            ),
            SwitchListTile(
                title: Text(
                  "Exporter mes devoirs (hors ligne et épinglés)",
                  style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white : Colors.black),
                ),
                value: exportPinnedHomework,
                onChanged: (newValue) {
                  setState(() {
                    exportPinnedHomework = newValue;
                  });
                }),
            SwitchListTile(
                title: Text(
                  "Exporter mes rappels",
                  style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white : Colors.black),
                ),
                value: exportReminders,
                onChanged: (newValue) {
                  setState(() {
                    exportReminders = newValue;
                  });
                }),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RaisedButton(
                  color: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  onPressed: () async {
                    String data = await HiveBackUpManager(null).getBackUpFileData();

                    Map decoded = jsonDecode(data);
                    if (decoded != null) {
                      //Try to import pinned homework
                      if (decoded["homework"] != null && decoded["homework"] != null) {
                        print("Importing homework");
                        List<Homework> hw = List();
                        jsonDecode(decoded["homework"]).forEach((e) {
                          hw.add(Homework.fromJson(e));
                        });
                        await HiveBackUpManager(offline.offlineBox, subBoxName: "homework", dataToImport: hw).import();
                      }
                      if (decoded["pinnedHomework"] != null && jsonDecode(decoded["pinnedHomework"]) != null) {
                        print("Importing pinned homework");

                        Map dates = jsonDecode(decoded["pinnedHomework"]);
                        await HiveBackUpManager(offline.pinnedHomeworkBox, dataToImport: dates).import();
                      }
                      //Try to import reminders
                      if (decoded["reminders"] != null && jsonDecode(decoded["reminders"]) != null) {
                        print("Importing reminders");
                        List<AgendaReminder> reminders = List();
                        jsonDecode(decoded["reminders"]).forEach((e) {
                          reminders.add(AgendaReminder.fromJson(e));
                        });
                        await HiveBackUpManager(offline.offlineBox, subBoxName: "reminders", dataToImport: reminders).import();
                      }
                    }
                  },
                  child: Text(
                    'Importer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  width: screenSize.size.width / 5 * 0.1,
                ),
                RaisedButton(
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  onPressed: (exportPinnedHomework || exportReminders)
                      ? () async {
                          Map json = Map();
                          if (exportPinnedHomework) {
                            json["pinnedHomework"] = HiveBackUpManager(offline.pinnedHomeworkBox).export();
                            json["homework"] = HiveBackUpManager(offline.offlineBox, subBoxName: "homework").export();
                          }

                          if (exportReminders) {
                            json["reminders"] = HiveBackUpManager(offline.offlineBox, subBoxName: "reminders").export();
                          }
                          //Write save file
                          await HiveBackUpManager(null).writeBackUpFile(jsonEncode(json));
                        }
                      : null,
                  child: Text(
                    'Exporter mes données',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
