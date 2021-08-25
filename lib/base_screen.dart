import 'dart:convert';

import 'package:epub_reader/community_webview.dart';
import 'package:epub_reader/epub_screen.dart';
import 'package:epub_reader/home_screen.dart';
import 'package:epub_reader/simple_screen.dart';
import 'package:epub_reader/webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseScreen extends StatefulWidget {
  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  List<String> myAssets = <String>[];
  @override
  void initState() {
    super.initState();
    _loadAssets();
    print('init state');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leitor epub'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (_) {
            if (myAssets.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
                ),
              );
            }
            return ListView.builder(
              itemCount: myAssets.length,
              itemBuilder: (_, index) {
                return Center(
                  child: ListTile(
                    title:
                        Text(myAssets[index].split('/').last.split('.').first),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SimpleScreen(myAssets[index]))),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadAssets() async {
    print('loading assets info');
    final blah = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> bluh = jsonDecode(blah);
    final assets = bluh.keys
        .where((element) => element.toLowerCase().contains('.epub'))
        .toList();
    setState(() {
      myAssets = assets;
    });
  }
}
