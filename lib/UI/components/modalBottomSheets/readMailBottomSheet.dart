import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ynotes/UI/components/dialogs.dart';
import 'package:ynotes/UI/utils/fileUtils.dart';
import 'package:ynotes/apis/EcoleDirecte.dart';
import 'package:ynotes/classes.dart';

import '../../../models.dart';
import '../../../usefulMethods.dart';

class ReadMailBottomSheet extends StatefulWidget {
  final Mail mail;
  final int index;

  const ReadMailBottomSheet(this.mail, this.index, {Key key}) : super(key: key);

  @override
  _ReadMailBottomSheetState createState() => _ReadMailBottomSheetState();
}

class _ReadMailBottomSheetState extends State<ReadMailBottomSheet> {
  bool monochromatic = false;
  DateFormat format = DateFormat("dd-MM-yyyy HH:hh");
  getMonochromaticColors(String html) {
    if (!monochromatic) {
      return html;
    }
    String color = isDarkModeEnabled ? "white" : "black";
    String finalHTML = html.replaceAll("color", "taratata");
    return finalHTML;
  }

  recipientFromMap() {
    return [Recipient(this.widget.mail.from["prenom"], this.widget.mail.from["nom"], this.widget.mail.from["id"].toString(), this.widget.mail.from["type"] == "P", this.widget.mail.from["matiere"])];
  }

  @override
  Widget build(BuildContext context) {
    print(this.widget.mail.id);
    MediaQueryData screenSize = MediaQuery.of(context);
    return FutureBuilder(
        future: readMail(this.widget.mail.id, this.widget.mail.read),
        builder: (context, snapshot) {
          return Container(
              height: screenSize.size.height,
              padding: EdgeInsets.all(0),
              child: new Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.1),
                    width: screenSize.size.width,
                    height: screenSize.size.height / 10 * 1.0,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(MdiIcons.arrowLeft, color: isDarkModeEnabled ? Colors.white : Colors.black),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    monochromatic = !monochromatic;
                                  });
                                },
                                icon: Icon((monochromatic ? MdiIcons.eye : MdiIcons.eyeOutline), color: isDarkModeEnabled ? Colors.white : Colors.black),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: screenSize.size.height / 10 * (8.8),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: screenSize.size.width,
                            padding: EdgeInsets.symmetric(horizontal: screenSize.size.width / 5 * 0.2, vertical: screenSize.size.height / 10 * 0.2),
                            child: AutoSizeText(
                              this.widget.mail.subject != "" ? this.widget.mail.subject : "(Sans sujet)",
                              maxLines: 100,
                              style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                              minFontSize: 18,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            height: screenSize.size.height / 10 * 0.8,
                            width: screenSize.size.width,
                            child: Row(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                    width: screenSize.size.width / 5 * 0.8,
                                    child: CircleAvatar(
                                      child: Text(
                                        this.widget.mail.from["name"][0],
                                        style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                                      ),
                                      maxRadius: screenSize.size.width / 5 * 0.8,
                                    )),
                                Container(
                                  margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                  width: screenSize.size.width / 5 * 3.4,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: screenSize.size.width / 5 * 0.1,
                                        children: [
                                          Text(
                                            this.widget.mail.from["name"],
                                            style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white : Colors.black),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            format.format(DateTime.parse(widget.mail.date)),
                                            style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
                                          ),
                                        ],
                                      ),
                                      if (!this.widget.mail.to.isEmpty)
                                        Text(
                                          this.widget.mail.to[0]["name"],
                                          style: TextStyle(fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
                                        )
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                  width: screenSize.size.width / 5 * 0.5,
                                  child: IconButton(
                                    icon: Icon(MdiIcons.undoVariant, color: isDarkModeEnabled ? Colors.white : Colors.black),
                                    onPressed: () async {
                                      await CustomDialogs.writeModalBottomSheet(context, defaultSubject: this.widget.mail.subject, defaultListRecipients: recipientFromMap());
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: screenSize.size.width,
                            child: (snapshot.hasData)
                                ? Column(
                                    children: <Widget>[
                                      HtmlWidget(
                                        getMonochromaticColors(snapshot.data),
                                        hyperlinkColor: Colors.blue.shade300,
                                        onTapUrl: (url) async {
                                          if (await canLaunch(url)) {
                                            await launch(url);
                                          } else {
                                            throw "Unable to launch url";
                                          }
                                        },
                                        textStyle: TextStyle(color: isDarkModeEnabled ? Colors.white : Colors.black),
                                      ),
                                      AnimatedContainer(
                                        duration: Duration(milliseconds: 75),
                                        width: screenSize.size.width / 5 * 4.4,
                                        height: this.widget.mail.files.length * (screenSize.size.height / 10 * 0.7),
                                        child: ListView.builder(
                                            itemCount: this.widget.mail.files.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              return Container(
                                                margin: EdgeInsets.only(bottom: screenSize.size.height / 10 * 0.2),
                                                child: Material(
                                                  borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.1),
                                                  color: Color(0xff5FA9DA),
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.5),
                                                    child: Container(
                                                      decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 0, color: Colors.transparent))),
                                                      width: screenSize.size.width / 5 * 4.4,
                                                      height: screenSize.size.height / 10 * 0.7,
                                                      child: Stack(
                                                        children: <Widget>[
                                                          Align(
                                                            alignment: Alignment.centerLeft,
                                                            child: Container(
                                                              margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                                              width: screenSize.size.width / 5 * 2.8,
                                                              child: ClipRRect(
                                                                child: Marquee(text: this.widget.mail.files[index].libelle, blankSpace: screenSize.size.width / 5 * 0.2, style: TextStyle(fontFamily: "Asap", color: Colors.white)),
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            right: screenSize.size.width / 5 * 0.1,
                                                            top: screenSize.size.height / 10 * 0.11,
                                                            child: Container(
                                                              height: screenSize.size.height / 10 * 0.5,
                                                              decoration: BoxDecoration(color: darken(Color(0xff5FA9DA)), borderRadius: BorderRadius.circular(50)),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                children: <Widget>[
                                                                  if ((this.widget.mail.files[index].libelle).contains("pdf"))
                                                                    IconButton(
                                                                      icon: Icon(
                                                                        MdiIcons.eyeOutline,
                                                                        color: Colors.white,
                                                                      ),
                                                                      onPressed: () {
                                                                        // do something
                                                                      },
                                                                    ),
                                                                  if ((this.widget.mail.files[index].libelle).contains("pdf"))
                                                                    VerticalDivider(
                                                                      width: 2,
                                                                      color: Color(0xff5FA9DA),
                                                                    ),
                                                                  ViewModelBuilder<DownloadModel>.reactive(
                                                                      viewModelBuilder: () => DownloadModel(),
                                                                      builder: (context, model, child) {
                                                                        return FutureBuilder(
                                                                            future: model.fileExists(this.widget.mail.files[index].libelle),
                                                                            initialData: false,
                                                                            builder: (context, snapshot) {
                                                                              if (snapshot.data == false) {
                                                                                if (model.isDownloading) {
                                                                                  /// If download is in progress or connecting
                                                                                  if (model.downloadProgress == null || model.downloadProgress < 100) {
                                                                                    return Container(
                                                                                      padding: EdgeInsets.symmetric(
                                                                                        horizontal: screenSize.size.width / 5 * 0.2,
                                                                                      ),
                                                                                      child: Center(
                                                                                        child: SizedBox(
                                                                                          width: screenSize.size.width / 5 * 0.3,
                                                                                          height: screenSize.size.width / 5 * 0.3,
                                                                                          child: CircularProgressIndicator(
                                                                                            backgroundColor: Colors.green,
                                                                                            strokeWidth: screenSize.size.width / 5 * 0.05,
                                                                                            value: model.downloadProgress,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  }

                                                                                  ///Download is ended
                                                                                  else {
                                                                                    return Container(
                                                                                        child: IconButton(
                                                                                      icon: Icon(
                                                                                        MdiIcons.check,
                                                                                        color: Colors.green,
                                                                                      ),
                                                                                      onPressed: () async {
                                                                                        FileAppUtil.openFile(this.widget.mail.files[index].libelle, usingFileName: true);
                                                                                      },
                                                                                    ));
                                                                                  }
                                                                                }

                                                                                ///Isn't downloading
                                                                                if (!model.isDownloading) {
                                                                                  return IconButton(
                                                                                    icon: Icon(
                                                                                      MdiIcons.fileDownloadOutline,
                                                                                      color: Colors.white,
                                                                                    ),
                                                                                    onPressed: () async {
                                                                                      await model.download(this.widget.mail.files[index]);
                                                                                    },
                                                                                  );
                                                                                }
                                                                              }

                                                                              ///If file already exists
                                                                              else {
                                                                                return Container(
                                                                                    child: IconButton(
                                                                                  icon: Icon(
                                                                                    MdiIcons.check,
                                                                                    color: Colors.green,
                                                                                  ),
                                                                                  onPressed: () async {
                                                                                    FileAppUtil.openFile(this.widget.mail.files[index].libelle, usingFileName: true);
                                                                                  },
                                                                                ));
                                                                              }
                                                                            });
                                                                      }),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                      )
                                    ],
                                  )
                                : SpinKitFadingFour(
                                    color: Theme.of(context).primaryColorDark,
                                    size: screenSize.size.width / 5 * 0.7,
                                  ),
                          )
                        ],
                      ),
                    ),
                  ),
                  /* Container(
                    height: screenSize.size.height / 10 * 1.0,
                    width: screenSize.size.width / 5 * 4.8,
                    child: FittedBox(
                      child: Column(
                        children: <Widget>[
                          Text(
                            this.widget.mail.subject,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: "Asap", fontWeight: FontWeight.bold, color: isDarkModeEnabled ? Colors.white : Colors.black),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              if (this.widget.mail.mtype != "send")
                                Container(
                                  width: screenSize.size.width / 5 * 2.6,
                                  height: screenSize.size.height / 10 * 0.45,
                                  padding: EdgeInsets.all(screenSize.size.height / 10 * 0.1),
                                  decoration: ShapeDecoration(shape: StadiumBorder(), color: Theme.of(context).primaryColorDark),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        "de : ",
                                        style: TextStyle(fontFamily: "Asap", fontWeight: FontWeight.bold, fontSize: screenSize.size.height / 10 * 0.15, color: isDarkModeEnabled ? Colors.white70 : Colors.black87),
                                      ),
                                      Text(
                                        this.widget.mail.from["name"],
                                        style: TextStyle(fontFamily: "Asap", fontWeight: FontWeight.bold, fontSize: screenSize.size.height / 10 * 0.15, color: isDarkModeEnabled ? Colors.white70 : Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              if (this.widget.mail.mtype != "received")
                                Container(
                                  padding: EdgeInsets.all(screenSize.size.height / 10 * 0.1),
                                  width: screenSize.size.width / 5 * 2.6,
                                  height: screenSize.size.height / 10 * 0.45,
                                  decoration: ShapeDecoration(shape: StadiumBorder(), color: Theme.of(context).primaryColorDark),
                                  child: FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Row(
                                      children: <Widget>[
                                        Text(
                                          "à : ",
                                          style: TextStyle(fontFamily: "Asap", fontWeight: FontWeight.bold, fontSize: screenSize.size.height / 10 * 0.15, color: isDarkModeEnabled ? Colors.white70 : Colors.black87),
                                        ),
                                        Container(
                                          width: screenSize.size.width / 5 * 2.1,
                                          height: screenSize.size.height / 10 * 0.45,
                                          child: Marquee(
                                            text: to,
                                            style: TextStyle(fontFamily: "Asap", fontWeight: FontWeight.bold, fontSize: screenSize.size.height / 10 * 0.15, color: isDarkModeEnabled ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Container(
                                margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                width: screenSize.size.width / 5 * 1.3,
                                padding: EdgeInsets.all(screenSize.size.height / 10 * 0.1),
                                height: screenSize.size.height / 10 * 0.45,
                                decoration: ShapeDecoration(shape: StadiumBorder(), color: Theme.of(context).primaryColorDark),
                                child: FittedBox(
                                  child: Text(
                                    DateFormat("dd MMMM yyyy", "fr_FR").format(DateTime.parse(this.widget.mail.date)),
                                    style: TextStyle(fontFamily: "Asap", fontWeight: FontWeight.bold, fontSize: screenSize.size.height / 10 * 0.15, color: isDarkModeEnabled ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: screenSize.size.width / 5 * 4.8,
                    height: screenSize.size.height / 10 * 4,
                    child: (snapshot.hasData)
                        ? SingleChildScrollView(
                            child: Column(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(top: screenSize.size.width / 5 * 0.2),
                                height: screenSize.size.height / 10 * 0.5,
                                width: screenSize.size.width / 5 * 3.5,
                                child: RaisedButton(
                                  color: Theme.of(context).primaryColorDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: new BorderRadius.circular(8),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      monochromatic = !monochromatic;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(monochromatic ? MdiIcons.eye : MdiIcons.eyeOutline, color: isDarkModeEnabled ? Colors.white : Colors.black),
                                      SizedBox(
                                        width: screenSize.size.width / 5 * 0.15,
                                      ),
                                      Text(
                                        monochromatic ? "Lecteur normal" : "Lecteur monochrome",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 18, fontFamily: "Asap", color: isDarkModeEnabled ? Colors.white : Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              HtmlWidget(
                                getMonochromaticColors(snapshot.data),
                                hyperlinkColor: Colors.blue.shade300,
                                onTapUrl: (url) async {
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  } else {
                                    throw "Unable to launch url";
                                  }
                                },
                                textStyle: TextStyle(color: isDarkModeEnabled ? Colors.white : Colors.black),
                              ),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 75),
                                width: screenSize.size.width / 5 * 4.4,
                                height: this.widget.mail.files.length * (screenSize.size.height / 10 * 0.7),
                                child: ListView.builder(
                                    itemCount: this.widget.mail.files.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      return Container(
                                        margin: EdgeInsets.only(bottom: screenSize.size.height / 10 * 0.2),
                                        child: Material(
                                          borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.1),
                                          color: Color(0xff5FA9DA),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.5),
                                            child: Container(
                                              decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 0, color: Colors.transparent))),
                                              width: screenSize.size.width / 5 * 4.4,
                                              height: screenSize.size.height / 10 * 0.7,
                                              child: Stack(
                                                children: <Widget>[
                                                  Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      margin: EdgeInsets.only(left: screenSize.size.width / 5 * 0.1),
                                                      width: screenSize.size.width / 5 * 2.8,
                                                      child: ClipRRect(
                                                        child: Marquee(text: this.widget.mail.files[index].libelle, blankSpace: screenSize.size.width / 5 * 0.2, style: TextStyle(fontFamily: "Asap", color: Colors.white)),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: screenSize.size.width / 5 * 0.1,
                                                    top: screenSize.size.height / 10 * 0.11,
                                                    child: Container(
                                                      height: screenSize.size.height / 10 * 0.5,
                                                      decoration: BoxDecoration(color: darken(Color(0xff5FA9DA)), borderRadius: BorderRadius.circular(50)),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: <Widget>[
                                                          if ((this.widget.mail.files[index].libelle).contains("pdf"))
                                                            IconButton(
                                                              icon: Icon(
                                                                MdiIcons.eyeOutline,
                                                                color: Colors.white,
                                                              ),
                                                              onPressed: () {
                                                                // do something
                                                              },
                                                            ),
                                                          if ((this.widget.mail.files[index].libelle).contains("pdf"))
                                                            VerticalDivider(
                                                              width: 2,
                                                              color: Color(0xff5FA9DA),
                                                            ),
                                                          ViewModelBuilder<DownloadModel>.reactive(
                                                              viewModelBuilder: () => DownloadModel(),
                                                              builder: (context, model, child) {
                                                                return FutureBuilder(
                                                                    future: model.fileExists(this.widget.mail.files[index].libelle),
                                                                    initialData: false,
                                                                    builder: (context, snapshot) {
                                                                      if (snapshot.data == false) {
                                                                        if (model.isDownloading) {
                                                                          /// If download is in progress or connecting
                                                                          if (model.downloadProgress == null || model.downloadProgress < 100) {
                                                                            return Container(
                                                                              padding: EdgeInsets.symmetric(
                                                                                horizontal: screenSize.size.width / 5 * 0.2,
                                                                              ),
                                                                              child: Center(
                                                                                child: SizedBox(
                                                                                  width: screenSize.size.width / 5 * 0.3,
                                                                                  height: screenSize.size.width / 5 * 0.3,
                                                                                  child: CircularProgressIndicator(
                                                                                    backgroundColor: Colors.green,
                                                                                    strokeWidth: screenSize.size.width / 5 * 0.05,
                                                                                    value: model.downloadProgress,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }

                                                                          ///Download is ended
                                                                          else {
                                                                            return Container(
                                                                                child: IconButton(
                                                                              icon: Icon(
                                                                                MdiIcons.check,
                                                                                color: Colors.green,
                                                                              ),
                                                                              onPressed: () async {
                                                                                FileAppUtil.openFile(this.widget.mail.files[index].libelle, usingFileName: true);
                                                                              },
                                                                            ));
                                                                          }
                                                                        }

                                                                        ///Isn't downloading
                                                                        if (!model.isDownloading) {
                                                                          return IconButton(
                                                                            icon: Icon(
                                                                              MdiIcons.fileDownloadOutline,
                                                                              color: Colors.white,
                                                                            ),
                                                                            onPressed: () async {
                                                                              await model.download(this.widget.mail.files[index]);
                                                                            },
                                                                          );
                                                                        }
                                                                      }

                                                                      ///If file already exists
                                                                      else {
                                                                        return Container(
                                                                            child: IconButton(
                                                                          icon: Icon(
                                                                            MdiIcons.check,
                                                                            color: Colors.green,
                                                                          ),
                                                                          onPressed: () async {
                                                                            FileAppUtil.openFile(this.widget.mail.files[index].libelle, usingFileName: true);
                                                                          },
                                                                        ));
                                                                      }
                                                                    });
                                                              }),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              )
                            ],
                          ))
                        : SpinKitFadingFour(
                            color: Theme.of(context).primaryColorDark,
                            size: screenSize.size.width / 5 * 0.7,
                          ),
                  )*/
                ],
              ));
        });
  }
}
