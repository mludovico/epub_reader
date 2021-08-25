import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart' as Dio hide Headers;
import 'package:epub/epub.dart' hide Image;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:shelf/shelf_io.dart' as Shelf;
import 'package:shelf/shelf.dart' as PureShelf;

class SimpleScreen extends StatefulWidget {
  final String bookAsset;

  const SimpleScreen(this.bookAsset);
  @override
  _SimpleScreenState createState() => _SimpleScreenState();
}

class _SimpleScreenState extends State<SimpleScreen> {
  String title = 'HTML Reader';
  String author = 'Author';
  Uint8List imageData;
  InAppWebViewController webViewController;
  String data = '';
  String styleData = '';
  HttpServer server;
  EpubBook book;
  bool loading = false;
  PageController pageViewController = PageController(initialPage: 7);
  InAppWebViewGroupOptions options;
  double height = 1;
  double width = 1;
  int index = 0;

  @override
  void initState() {
    _loadEbook();
    super.initState();
  }

  void _loadEbook() async {
    setState(() {
      loading = true;
    });
    // final dio = Dio.Dio();
    // final url =
    //     'https://bamboleio-staging.s3.sa-east-1.amazonaws.com/staging/uploads
    //     /books/1/book_file/livro-1.epub?X-Amz-Expires=600&X-Amz-Date=
    //     20210818T160151Z&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=
    //     AKIA3333MIK52B5A7G65%2F20210818%2Fsa-east-1%2Fs3%2Faws4_request&X-
    //     Amz-SignedHeaders=host&X-Amz-Signature=
    //     97e2436dcc570bdd4bf4a4a2495ba5c59421a8016a8c44d27b2daa42a7ff267c';
    // Dio.Response response;
    // try {
    //   response = await dio.get<Uint8List>(
    //     url,
    //     options: Dio.Options(
    //       responseType: Dio.ResponseType.bytes,
    //       validateStatus: (code) => code < 500,
    //     ),
    //   );
    // } on Exception catch (e) {
    //   print(e.toString());
    //   return;
    // }
    // final bytes = response.data;
    // EpubBook book = await EpubReader.readBook(bytes);
    final bookFile2 = await rootBundle.load(widget.bookAsset);
    final bytes2 = bookFile2.buffer.asUint8List();
    final book2 = await EpubReader.readBook(bytes2);
    await _initServer();
    setState(() {
      author = book2.Author;
      title = book2.Title;
      book = book2;
      loading = false;
      if (book2.CoverImage != null) imageData = book2.CoverImage.getBytes();
    });
    // webViewController.loadUrl(url: 'localhost:8080/page001.xhtml');
  }

  _initServer() async {
    server = await Shelf.serve((PureShelf.Request request) async {
      final path = request.url.path;
      if (!book.Content.AllFiles.containsKey(path)) {
        print('${request.requestedUri} - $path not found');
        return PureShelf.Response(HttpStatus.notFound);
      }
      final file = book.Content.AllFiles[path];
      dynamic body;
      switch (file.ContentType) {
        case EpubContentType.XHTML_1_1:
        case EpubContentType.DTBOOK:
        case EpubContentType.DTBOOK_NCX:
        case EpubContentType.OEB1_DOCUMENT:
        case EpubContentType.XML:
        case EpubContentType.CSS:
        case EpubContentType.OEB1_CSS:
          body = (file as EpubTextContentFile).Content;
          break;
        case EpubContentType.IMAGE_GIF:
        case EpubContentType.IMAGE_JPEG:
        case EpubContentType.IMAGE_PNG:
        case EpubContentType.IMAGE_SVG:
        case EpubContentType.FONT_TRUETYPE:
        case EpubContentType.FONT_OPENTYPE:
        case EpubContentType.OTHER:
          body = (file as EpubByteContentFile).Content;
          break;
      }
      final connectionInfo = request.context.values.first as HttpConnectionInfo;
      print(
          '${connectionInfo.remoteAddress.address}:${connectionInfo.remotePort}');
      print('${request.requestedUri} - Served $path');
      return PureShelf.Response(
        HttpStatus.ok,
        headers: {'Content-Type': file.ContentMimeType},
        body: body,
      );
    }, '0.0.0.0', 8080);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await server.close(force: true);
        print('Server closed');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Builder(builder: (context) {
          if (book == null && !loading)
            return Container();
          else if (loading)
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
              ),
            );
          final url = Uri.parse('http://localhost:8080/'
              '${book.Schema.Package.Manifest.Items.firstWhere((element) => element.Id == book.Schema.Package.Spine.Items[index].IdRef).Href}');
          print('url now is $url');
          return Center(
            child: InAppWebView(
              onConsoleMessage: (controller, log) {
                print(log.message);
              },
              onLoadStop: (controller, url) async {
                if (Platform.isIOS) {
                  final double htmlWidth = (await controller.evaluateJavascript(
                          source: 'document.body.scrollWidth'))
                      .toDouble();
                  print('html width: $htmlWidth');
                  final deviceWidth = MediaQuery.of(context).size.width;
                  print('device width: $deviceWidth');
                  final ratio = deviceWidth / htmlWidth;
                  print('Ratio: $ratio');
                  await controller.injectCSSCode(
                      source: 'body {zoom: $ratio;}');
                  await controller.injectCSSCode(
                      source: 'body {visibility: visible;}');
                }

//                 await controller.evaluateJavascript(
//                     source: 'console.log(document.body.offsetHeight)');
//                 await controller.evaluateJavascript(
//                     source: 'console.log(document.body.clientHeight)');
//                 await controller.evaluateJavascript(
//                     source: 'console.log(document.body.scrollHeight)');
//                 await controller.evaluateJavascript(
//                     source:
//                         'console.log(document.documentElement.offsetHeight)');
//                 await controller.evaluateJavascript(
//                     source:
//                         'console.log(document.documentElement.clientHeight)');
//                 await controller.evaluateJavascript(
//                     source:
//                         'console.log(document.documentElement.scrollHeight)');
//                 final double height = (await controller.evaluateJavascript(
//                         source: jsGetMaxHeightScript))
//                     .toDouble();
//                 final ratio = <double>[
//                   height / constraints.maxHeight,
//                   width / constraints.maxWidth
//                 ].reduce(max);
//                 setState(() {
//                   this.height = height / ratio;
//                   this.width = width / ratio;
//                 });
//                 print('''
// WebView size: ($width x $height)
// Available size ({constraints.maxWidth} x {constraints.maxHeight})
// Biggest calculated ratio ratio
// Resized image size (${this.width} x ${this.height})
//                     ''');
              },
              onLoadStart: (controller, url) {
                setState(() {
                  this.height = 1;
                  this.width = 1;
                });
              },
              initialOptions: InAppWebViewGroupOptions(
                ios: IOSInAppWebViewOptions(
                  enableViewportScale: true,
                ),
              ),
              onLoadError: (controller, url, code, message) =>
                  print('$url, $code, $message'),
              initialUrlRequest: URLRequest(
                url: url,
              ),
              onWebViewCreated: (controller) async {
                setState(() {
                  webViewController = controller;
                });
              },
            ),
          );
        }),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: index == 0
                    ? null
                    : () {
                        setState(() {
                          index--;
                        });
                        print('go to previous page: $index');
                        _loadPage();
                      },
              ),
              label: 'Anterior',
            ),
            BottomNavigationBarItem(
              icon: IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed:
                    index == book?.Schema?.Package?.Spine?.Items?.length ??
                            0 - 1
                        ? null
                        : () {
                            setState(() {
                              index++;
                            });
                            print('go to next page: $index');
                            _loadPage();
                          },
              ),
              label: 'Próxima',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPage() async {
    await webViewController.injectCSSCode(source: 'body {visibility: hidden;}');
    await webViewController.injectCSSCode(source: 'body {zoom: 1;}');
    await webViewController.loadUrl(
      urlRequest: URLRequest(
        url: Uri.parse('http://localhost:8080/'
            '${book.Schema.Package.Manifest.Items.firstWhere((element) => element.Id == book.Schema.Package.Spine.Items[index].IdRef).Href}'),
      ),
    );
  }

  final String jsGetMaxWidthScript = '''
(function() {
    var pageWidth = 0;

    function findHighestNode(nodesList) {
        for (var i = nodesList.length - 1; i >= 0; i--) {
            if (nodesList[i].scrollWidth && nodesList[i].clientWidth) {
                var elWidth = Math.max(nodesList[i].scrollWidth, nodesList[i].clientWidth);
                pageWidth = Math.max(elWidth, pageWidth);
            }
            if (nodesList[i].childNodes.length) findHighestNode(nodesList[i].childNodes);
        }
    }

    findHighestNode(document.documentElement.childNodes);

    // The entire page height is found
    console.log('Page width is', pageWidth);
    return pageWidth;
})();  ''';
  final String jsGetMaxHeightScript = '''
(function() {
    var pageHeight = 0;

    function findHighestNode(nodesList) {
        for (var i = nodesList.length - 1; i >= 0; i--) {
            if (nodesList[i].scrollHeight && nodesList[i].clientHeight) {
                var elHeight = Math.max(nodesList[i].scrollHeight, nodesList[i].clientHeight);
                pageHeight = Math.max(elHeight, pageHeight);
            }
            if (nodesList[i].childNodes.length) findHighestNode(nodesList[i].childNodes);
        }
    }

    findHighestNode(document.documentElement.childNodes);

    // The entire page height is found
    console.log('Page height is', pageHeight);
    return pageHeight;
})();  ''';
}
