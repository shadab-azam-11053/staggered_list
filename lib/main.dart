import 'package:flutter/material.dart';
import 'package:staggered_list/staggered/widgets/staggered_grid_view.dart';
import 'package:staggered_list/staggered/widgets/staggered_tile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class Model {
  String name;
  String type;
  Model({required this.name, required this.type});
}

class _MyAppState extends State<MyApp> {
  int position = 2;

  List<int> intArr = [];
  @override
  Widget build(BuildContext context) {
    List<Model> list = [
      Model(name: 'A', type: 'aa'),
      Model(name: 'B', type: 'bb'),
      Model(name: 'C', type: 'cc'),
      Model(name: 'D', type: 'dd'),
      Model(name: 'E', type: 'cc'),
      Model(name: 'F', type: 'ff'),
      Model(name: 'G', type: 'gg'),
      Model(name: 'H', type: 'hh'),
      Model(name: 'I', type: 'ii'),
      Model(name: 'J', type: 'jj'),
    ];

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Custom Staggered GridView'),
        ),
        // body: listView(staggered),
        body: staggered(list: list, type: list[position].type),
      ),
    );
  }

  void replace(list, i) {
    if (i < list.length - 2) {
      Model model = list[i];
      list.remove(model);
      list.insert(i + 1, model);
      intArr.add(i + 1);
    }
  }

  Widget staggered({required List<Model> list, required String type}) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].type == type) {
        if (intArr.isEmpty || intArr.length % 2 == 0) {
          if (i % 2 == 0) {
            intArr.add(i);
          } else {
            replace(list, i);
          }
        } else if (intArr.length % 2 != 0) {
          if (i % 2 == 0) {
            replace(list, i);
          } else {
            intArr.add(i);
          }
        }
      }

      print(intArr);
    }

    for (int i = 0; i < list.length; i++) {
      if (list[i].type == type) {
        intArr.add(i);
      }
    }
    return StaggeredGridView.countBuilder(
      crossAxisCount: 2,
      itemBuilder: (BuildContext context, int index) {
        if (intArr.contains(index)) {
          return typeView(list[index]);
        } else {
          return commonView(list[index]);
        }
      },
      staggeredTileBuilder: (int index) => intArr.contains(index)
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

  Widget commonView(Model model) {
    return Container(
        margin: const EdgeInsets.all(5),
        color: Colors.blue,
        height: 100,
        child: Center(child: Text(model.name)));
  }

  Widget typeView(Model model) {
    return Container(
        margin: const EdgeInsets.all(5),
        color: Colors.red,
        height: 100,
        child: Center(child: Text(model.name)));
  }
}
