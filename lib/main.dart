import 'package:flutter/material.dart';
import 'package:staggered_list/staggered/widgets/staggered_grid_view.dart';
import 'package:staggered_list/staggered/widgets/staggered_tile.dart';

void main() {
  runApp(const MyApp());
}

class Product {
  final int id;
  final bool isExpanded;
  Product({
    required this.id,
    required this.isExpanded,
  });
}

List<Product> productList = [
  Product(
    id: 0,
    isExpanded: true,
  ),
  Product(
    id: 1,
    isExpanded: false,
  ),
  Product(
    id: 2,
    isExpanded: true,
  ),
  Product(
    id: 3,
    isExpanded: false,
  ),
  Product(
    id: 4,
    isExpanded: false,
  ),
  Product(
    id: 5,
    isExpanded: true,
  ),
  Product(
    id: 6,
    isExpanded: false,
  ),
  Product(
    id: 7,
    isExpanded: false,
  ),
  Product(
    id: 8,
    isExpanded: false,
  ),
  Product(
    id: 9,
    isExpanded: false,
  ),
  Product(
    id: 10,
    isExpanded: false,
  ),
  Product(
    id: 11,
    isExpanded: false,
  ),
  Product(
    id: 12,
    isExpanded: false,
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
      if (productList[i].isExpanded == true) {
        if (_mod == _counter) {
          if (productList.length - 2 <= i) {
            productList[i] = productList[i - 1];
            productList[i - 1] = product;
            if (productList.length == i &&
                productList[i + 1].isExpanded == true) {
              product = productList[i];
              productList[i] = productList[i + 1];
              productList[i + 1] = product;
            }
          } else {
            if (productList[i + 1].isExpanded == true) {
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
        if (list[index].isExpanded) {
          return typeView(list[index]);
        } else {
          return commonView(list[index]);
        }
      },
      staggeredTileBuilder: (int index) => list[index].isExpanded
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

  Widget typeView(Product product) {
    return Container(
      height: 100,
      color: Colors.red,
      child: Center(
        child: CircleAvatar(
          backgroundColor: product.isExpanded ? Colors.white : Colors.yellow,
          child: Text(product.id.toString()),
        ),
      ),
    );
  }

  Widget commonView(Product product) {
    return Container(
      height: 100,
      color: Colors.white,
      child: Center(
        child: CircleAvatar(
          backgroundColor: product.isExpanded ? Colors.white : Colors.yellow,
          child: Text(product.id.toString()),
        ),
      ),
    );
  }
}
