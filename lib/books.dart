import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/books/v1.dart' as booksapi;

import 'main.dart';

class GoogleBooks {
  Future<booksapi.VolumeVolumeInfo> getBook({String isbn}) async {
    var client = http.Client();
    try {
      var api = booksapi.BooksApi(client);
      final volumes = await api.volumes.list(q: 'isbn:$isbn');
      return volumes.items.first.volumeInfo;
    } finally {
      client.close();
    }
  }
}

class BookTile extends StatelessWidget {
  final booksapi.VolumeVolumeInfo book;
  final ValueChanged<booksapi.VolumeVolumeInfo> onTapped;

  BookTile({@required this.book, @required this.onTapped});

  Widget bookThumbnail() {
    var url = book.imageLinks.thumbnail;
    if (url != null) {
      if (url.startsWith('http://')) {
        url = url.replaceFirst('http://', 'https://');
      }
      return Image.network(url);
    } else {
      return const Icon(Icons.book);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return ListTile();
    } else {
      return Card(
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () => onTapped(book),
          child: ListTile(
            leading: bookThumbnail(),
            title: book.title != null ? Text(book.title) : '[Unknown]',
            subtitle: Text(book.authors.join(', ')),
          ),
        ),
      );
    }
  }
}

class BooksPage extends StatefulWidget {
  final ValueChanged<booksapi.VolumeVolumeInfo> onTapped;

  BooksPage({@required this.onTapped});

  @override
  _BooksPageState createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Books'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Manually add a book ISBN',
            onPressed: () {
              final parentState =
                  context.findAncestorStateOfType<BarcoderAppState>();

              parentState.setState(
                () {
                  parentState.isAddingBarcode = true;
                },
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: Bookshelf.of(context).bookshelf.length,
        itemBuilder: (BuildContext context, int index) {
          return FutureBuilder(
            future: GoogleBooks().getBook(
                isbn: Bookshelf.of(context).bookshelf.elementAt(index)),
            builder:
                (context, AsyncSnapshot<booksapi.VolumeVolumeInfo> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return BookTile(
                  book: snapshot.data,
                  onTapped: widget.onTapped,
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.qr_code_scanner),
        onPressed: (() {
          final parentState =
              context.findAncestorStateOfType<BarcoderAppState>();

          parentState.setState(
            () {
              parentState.isScanning = true;
            },
          );
        }),
      ),
    );
  }
}
