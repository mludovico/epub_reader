// import 'package:epub_view/epub_view.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// class EpubScreen extends StatefulWidget {
//   final String epubAsset;
//   EpubScreen(this.epubAsset);
//
//   @override
//   _EpubScreenState createState() => _EpubScreenState();
// }
//
// class _EpubScreenState extends State<EpubScreen> {
//   EpubController controller;
//
//   @override
//   void initState() {
//     controller = EpubController(document: loadBook());
//     super.initState();
//   }
//
//   Future<EpubBook> loadBook() async {
//     final bookFile = await rootBundle.load(widget.epubAsset);
//     final bytes = bookFile.buffer.asUint8List();
//     return EpubReader.readBook(bytes);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Epub read'),
//       ),
//       body: Container(
//         child: EpubView(
//           controller: controller,
//           itemBuilder: (context, chapters, paragraphs, page) {},
//           loader: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation(Colors.teal),
//           ),
//           errorBuilder: (e) {
//             return Center(
//               child: Text(e?.toString() ?? 'Erro ao exibir livro'),
//             );
//           },
//           onDocumentError: (e) {
//             return Center(
//               child: Text(e?.toString() ?? 'Erro ao carregar livro'),
//             );
//           },
//           dividerBuilder: (chapter) => Divider(),
//           onDocumentLoaded: (book) {
//             print('${book.Title} loaded!');
//           },
//         ),
//       ),
//     );
//   }
// }
