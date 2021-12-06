import 'package:flutter/material.dart';
import 'package:staggered_list/staggered/widgets/staggered_grid_view.dart';
import 'package:staggered_list/staggered/widgets/staggered_tile.dart';

void main() {
  runApp(const MyApp());
}

class Product {
  final String name;
  final String type;
  Product({
    required this.name,
    required this.type,
  });
}

List<Product> productList = [
  Product(
    name: '0',
    type: 'component',
  ),
  Product(
    name: '1',
    type: 'component',
  ),
  Product(
    name: '2',
    type: 'ads',
  ),
  Product(
    name: '3',
    type: 'component',
  ),
  Product(
    name: '4',
    type: 'component',
  ),
  Product(
    name: '5',
    type: 'ads',
  ),
  Product(
    name: '6',
    type: 'component',
  ),
  Product(
    name: '7',
    type: 'component',
  ),
  Product(
    name: '8',
    type: 'component',
  ),
  Product(
    name: '9',
    type: 'component',
  ),
  Product(
    name: '10',
    type: 'component',
  ),
  Product(
    name: '11',
    type: 'component',
  ),
  Product(
    name: '12',
    type: 'component',
  ),
];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Staggered List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int _counter = 2;
  int _mod = 0;

  Product? product;

  void _incrementCounter() {
    _mod = 0;
    for (var i = 0; i < productList.length; i++) {
      Product product = productList[i];
      _mod++;
      if (productList[i].type == 'ads') {
        if (_mod == _counter) {
          if (productList.length - 2 <= i) {
            productList[i] = productList[i - 1];
            productList[i - 1] = product;
            if (productList.length == i && productList[i + 1].type == 'ads') {
              product = productList[i];
              productList[i] = productList[i + 1];
              productList[i + 1] = product;
            }
          } else {
            if (productList[i + 1].type == 'ads') {
              productList[i] = productList[i + 2];
              productList[i + 2] = product;
              setState(() {});
              i++;
            } else {
              productList[i] = productList[i + 1];
              productList[i + 1] = product;
            }
          }
        }
        _mod = 0;
      } else {
        if (_mod == _counter) {
          _mod = 0;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: staggered(list: productList),
    );
  }

  Widget staggered({required List<Product> list}) {
    _incrementCounter();
    return StaggeredGridView.countBuilder(
      crossAxisCount: _counter,
      itemBuilder: (BuildContext context, int index) {
        if (list[index].type == 'ads') {
          return adsView(list[index]);
        } else {
          return commonView(list[index]);
        }
      },
      staggeredTileBuilder: (int index) => list[index].type == 'ads'
          ? const StaggeredTile.fit(2)
          : const StaggeredTile.fit(1),
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      padding: const EdgeInsets.all(4.0),
      itemCount: list.length,
      primary: false,
      shrinkWrap: true,
    );
  }

  Widget adsView(Product product) {
    return Container(
      height: 100,
      color: Colors.red,
      child: Center(
        child: Text(
          product.name,
          style: const TextStyle(
              color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget commonView(Product product) {
    return Container(
      height: 100,
      color: Colors.white,
      child: Center(
        child: Text(
          product.name,
          style: const TextStyle(
              color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
