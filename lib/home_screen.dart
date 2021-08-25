// import 'dart:collection';
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:dio/dio.dart' as Dio hide Headers;
// import 'package:epub/epub.dart' hide Image;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:shelf/shelf_io.dart' as Shelf;
// import 'package:shelf/shelf.dart' as PureShelf;
//
// class HomeScreen extends StatefulWidget {
//   final String bookAsset;
//
//   const HomeScreen(this.bookAsset);
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   String title = 'HTML Reader';
//   String author = 'Author';
//   Uint8List imageData;
//   InAppWebViewController webViewController;
//   String data = '';
//   String styleData = '';
//   HttpServer server;
//   EpubBook book;
//   bool loading = false;
//   PageController pageViewController = PageController(initialPage: 7);
//   InAppWebViewGroupOptions options;
//   double height = 1;
//
//   @override
//   void initState() {
//     _loadEbook();
//     super.initState();
//   }
//
//   void _loadEbook() async {
//     setState(() {
//       loading = true;
//     });
//     // final dio = Dio.Dio();
//     // final url =
//     //     'https://bamboleio-staging.s3.sa-east-1.amazonaws.com/staging/uploads/books/1/book_file/livro-1.epub?X-Amz-Expires=600&X-Amz-Date=20210818T160151Z&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIA3333MIK52B5A7G65%2F20210818%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-SignedHeaders=host&X-Amz-Signature=97e2436dcc570bdd4bf4a4a2495ba5c59421a8016a8c44d27b2daa42a7ff267c';
//     // Dio.Response response;
//     // try {
//     //   response = await dio.get<Uint8List>(
//     //     url,
//     //     options: Dio.Options(
//     //       responseType: Dio.ResponseType.bytes,
//     //       validateStatus: (code) => code < 500,
//     //     ),
//     //   );
//     // } on Exception catch (e) {
//     //   print(e.toString());
//     //   return;
//     // }
//     // final bytes = response.data;
//     // EpubBook book = await EpubReader.readBook(bytes);
//     final bookFile2 = await rootBundle.load(widget.bookAsset);
//     final bytes2 = bookFile2.buffer.asUint8List();
//     final book2 = await EpubReader.readBook(bytes2);
//     await _initServer();
//     setState(() {
//       author = book2.Author;
//       title = book2.Title;
//       book = book2;
//       loading = false;
//       if (book2.CoverImage != null) imageData = book2.CoverImage.getBytes();
//     });
//     // webViewController.loadUrl(url: 'localhost:8080/page001.xhtml');
//   }
//
//   _initServer() async {
//     server = await Shelf.serve((PureShelf.Request request) async {
//       final path = request.url.path;
//       if (!book.Content.AllFiles.containsKey(path)) {
//         print('${request.requestedUri} - $path not found');
//         return PureShelf.Response(HttpStatus.notFound);
//       }
//       final file = book.Content.AllFiles[path];
//       dynamic body;
//       switch (file.ContentType) {
//         case EpubContentType.XHTML_1_1:
//         case EpubContentType.DTBOOK:
//         case EpubContentType.DTBOOK_NCX:
//         case EpubContentType.OEB1_DOCUMENT:
//         case EpubContentType.XML:
//         case EpubContentType.CSS:
//         case EpubContentType.OEB1_CSS:
//           body = (file as EpubTextContentFile).Content;
//           break;
//         case EpubContentType.IMAGE_GIF:
//         case EpubContentType.IMAGE_JPEG:
//         case EpubContentType.IMAGE_PNG:
//         case EpubContentType.IMAGE_SVG:
//         case EpubContentType.FONT_TRUETYPE:
//         case EpubContentType.FONT_OPENTYPE:
//         case EpubContentType.OTHER:
//           body = (file as EpubByteContentFile).Content;
//           break;
//       }
//       final connectionInfo = request.context.values.first as HttpConnectionInfo;
//       print(
//           '${connectionInfo.remoteAddress.address}:${connectionInfo.remotePort}');
//       print('${request.requestedUri} - Served $path');
//       return PureShelf.Response(
//         HttpStatus.ok,
//         headers: {'Content-Type': file.ContentMimeType},
//         body: body,
//       );
//     }, '0.0.0.0', 8080);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     options = InAppWebViewGroupOptions(
//       ios: IOSInAppWebViewOptions(
//         //   // enableViewportScale: true,
//         //   ignoresViewportScaleLimits: true,
//         //   disallowOverScroll: true,
//         //   automaticallyAdjustsScrollIndicatorInsets: true,
//         pageZoom: .5,
//       ),
//       crossPlatform: InAppWebViewOptions(
//         supportZoom: true,
//         horizontalScrollBarEnabled: true,
//         preferredContentMode: UserPreferredContentMode.MOBILE,
//         disableHorizontalScroll: false,
//       ),
//       // android: AndroidInAppWebViewOptions(),
//     );
//     return WillPopScope(
//       onWillPop: () async {
//         await server.close(force: true);
//         print('Server closed');
//         return true;
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(title),
//         ),
//         body: Builder(builder: (_) {
//           if (book == null && !loading)
//             return Container();
//           else if (loading)
//             return Center(
//               child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
//               ),
//             );
//           return PageView.builder(
//             controller: pageViewController,
//             itemCount: book.Schema.Package.Spine.Items.length,
//             itemBuilder: (_, index) {
//               final spineId = book.Schema.Package.Spine.Items[index].IdRef;
//               final fileName = book.Schema.Package.Manifest.Items
//                   .firstWhere((element) => element.Id == spineId)
//                   .Href;
//               final url = 'http://localhost:8080/$fileName';
//               return InAppWebView(
//                 onLoadStop: (controller, url) async {
//                   print(await controller.getZoomScale());
//                   await controller.scrollTo(x: 10, y: 2);
//                   final scrollX = await controller.getScrollX();
//                   final scrollY = await controller.getScrollY();
//                   final height = await controller.getContentHeight();
//                   print(
//                       'Scroll X: $scrollX, Scroll Y: $scrollY, height: $height');
//                   setState(() {
//                     this.height = height.toDouble();
//                   });
//                 },
//                 initialOptions: options,
//                 onLoadError: (controller, url, code, message) =>
//                     print('$url, $code, $message'),
//                 initialUrlRequest: URLRequest(
//                   url: Uri.parse(url),
//                 ),
//                 onWebViewCreated: (controller) async {
//                   setState(() {
//                     webViewController = controller;
//                   });
//                 },
//               );
//             },
//           );
//         }),
//         bottomNavigationBar: BottomNavigationBar(
//           items: [
//             BottomNavigationBarItem(
//               icon: IconButton(
//                 icon: Icon(Icons.arrow_back),
//                 onPressed: () {
//                   pageViewController.previousPage(
//                       duration: Duration(milliseconds: 500),
//                       curve: Curves.ease);
//                 },
//               ),
//               label: 'Anterior',
//             ),
//             BottomNavigationBarItem(
//               icon: IconButton(
//                 icon: Icon(Icons.arrow_forward),
//                 onPressed: () {
//                   pageViewController.nextPage(
//                       duration: Duration(milliseconds: 500),
//                       curve: Curves.ease);
//                 },
//               ),
//               label: 'Próxima',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
