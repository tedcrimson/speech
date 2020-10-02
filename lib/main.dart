import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:speech/word.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

typedef Future<Null> Action();

class _MyAppState extends State<MyApp> {
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  List<Word> lastWords = [];
  String lastError = "";
  String lastStatus = "";
  String _currentLocaleId = "";
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  Random random = Random();
  List<Widget> wordWidgets = [];
  Queue<Action> actionQueue = Queue();

  @override
  void initState() {
    super.initState();
    initSpeechState();
  }

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      _localeNames = await speech.locales();

      var systemLocale = await speech.systemLocale();
      _currentLocaleId = systemLocale.localeId;
    }

    if (!mounted) return;

    setState(() {
      _hasSpeech = hasSpeech;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            left: 10,
            right: 10,
            top: 100,
            bottom: 80,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              runAlignment: WrapAlignment.start,
              // direction: Axis.vertical,
              spacing: 10,
              children: wordWidgets.map((e) => e).toList(),
            ),
          ),
          Positioned.fill(
            bottom: 40,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                // crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            wordWidgets.clear();
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: speech.isListening ? 0 : 60,
                          height: speech.isListening ? 0 : 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(100)),
                            color: Colors.white,
                          ),
                          child: Center(child: Icon(Icons.clear)),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_hasSpeech) {
                        if (speech.isListening) {
                          stopListening();
                        } else {
                          startListening();
                        }
                      }
                    },
                    child: Container(
                        width: 100,
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(blurRadius: 0, spreadRadius: level * 1.5, color: Colors.red.withOpacity(0.5))
                          ],
                          color: speech.isListening ? Colors.red : Colors.white,
                          // border: Border.all(
                          //   color: Colors.black26,
                          //   width: 1,
                          //   style: speech.isListening ? BorderStyle.none : BorderStyle.solid,
                          // ),
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                        ),
                        child: Icon(
                          Icons.mic,
                          size: 40,
                          color: !speech.isListening ? Colors.red : Colors.white,
                        )),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          showDialog<void>(
                              context: context,
                              builder: (context) => Padding(
                                    padding: const EdgeInsets.all(40.0),
                                    child: Material(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _localeNames.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          return ListTile(
                                            selected: _localeNames[index].localeId == _currentLocaleId,
                                            title: Text(_localeNames[index].name),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              _switchLang(_localeNames[index].localeId);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ));
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: speech.isListening ? 0 : 60,
                          height: speech.isListening ? 0 : 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(100)),
                            color: Colors.white,
                          ),
                          child: Center(child: Text(_currentLocaleId)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void startListening() {
    lastWords.clear();
    actionQueue.clear();
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 60),
        pauseFor: Duration(seconds: 10),
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        // onDevice: true,
        listenMode: ListenMode.deviceDefault);
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      var words = result.recognizedWords.split(' ');
      if (words.length > 0 && words[0].isNotEmpty) {
        List<Word> ww = [];
        for (var i = 0; i < words.length; i++) {
          if (i >= lastWords.length) {
            print(words[i]);
            var word = Word(words[i], random);
            ww.add(word);
            lastWords.add(word);
          }
        }
        if (ww.length > 0) _addToQueue(ww);
      }
      // print("@ ${result.recognizedWords}=>$last");
      // if (last.isNotEmpty && lastWords.length == 0 || lastWords.last.value != last) {
      //   print(last);
      //   lastWords.add(Word(last, random));
      // }
    });
  }

  bool calling = false;

  void _addToQueue(List<Word> words) async {
    for (var word in words) {
      actionQueue.add(() async {
        setState(() {
          wordWidgets.add(TweenAnimationBuilder(
            tween: Tween(begin: 1.0, end: 0.0),
            curve: Curves.easeInCubic,
            duration: Duration(milliseconds: 400),
            // child: ,
            builder: (context, double val, Widget child) {
              double scale = 5.0;
              return Transform(
                transform: Matrix4.translationValues(20 * val, 30 * val, 0)
                  ..scale(
                    1 + (scale - 1) * val,
                  ),
                child: Opacity(
                    opacity: 1 - val,
                    child: Text(
                      word.value,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    )),
              );
            },
          ));
        });
        await Future<void>.delayed(Duration(milliseconds: 200));
      });
    }
    if (!calling) {
      calling = true;
      while (actionQueue.length > 0) {
        await (actionQueue.removeFirst())();
      }
      calling = false;
    }
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // print("sound level $level: $minSoundLevel - $maxSoundLevel ");
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    // print("Received error status: $error, listening: ${speech.isListening}");
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
      print(lastError);
    });
  }

  void statusListener(String status) {
    // print(
    // "Received listener status: $status, listening: ${speech.isListening}");
    setState(() {
      lastStatus = "$status";
      print(lastStatus);
      level = 0.0;
    });
  }

  void _switchLang(String selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }
}
