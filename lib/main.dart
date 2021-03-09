import 'package:flutter/material.dart';
import 'flutter_stateless_chessboard/flutter_stateless_chessboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Chess',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Random Chess'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  String selectedRandomMode = 'random_total';
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    //print('Queried Size: ${size.width}');

    return Scaffold(
      appBar: AppBar(
        title: Text("Random Chess"),
      ),
      body: Center(
        child: Container(
          width: size.width,
          height: size.width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                child: Chessboard(
                  fen: _fen,
                  size: size.width,
                  orientation: 'w',
                  onMove: (move) {
                    print("move from ${move.from} to ${move.to}");
                  },
                ),
              ),
              Container(
                width: size.width,
                height: size.width / 2,
                color: Colors.black.withAlpha(146),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ListTile(
                    //   title: Text(
                    //     "Random Mode",
                    //     textAlign: TextAlign.left,
                    //     style: TextStyle(fontSize: 20),
                    //   ),
                    // ),
                    RadioListTile<String>(
                      title: const Text('Fully Randomized'),
                      value: 'random_total',
                      groupValue: selectedRandomMode,
                      onChanged: (String value) {
                        setState(() {
                          selectedRandomMode = value;
                        });
                      },
                      selected: selectedRandomMode == 'random_total',
                      secondary: IconButton(
                        icon: Icon(Icons.info_outline_rounded),
                        onPressed: () {},
                      ),
                    ),
                    RadioListTile<String>(
                      title: const Text('Ches960 - Fischer'),
                      value: 'random_fischer',
                      groupValue: selectedRandomMode,
                      selected: selectedRandomMode == 'random_fischer',
                      onChanged: (String value) {
                        setState(() {
                          selectedRandomMode = value;
                        });
                      },
                      secondary: IconButton(
                        icon: Icon(Icons.info_outline_rounded),
                        onPressed: () {},
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.cached),
                        label: Text('GENERATE'),
                        onPressed: () {},
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
