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
  int i = 2;
  int position = -1;

  List<int> intArr = [];
  @override
  Widget build(BuildContext context) {
    List<Model> list = [
      Model(name: 'A', type: 'aa'),
      Model(name: 'B', type: 'bb'),
      Model(name: 'C', type: 'cc'),
      Model(name: 'D', type: 'dd'),
      Model(name: 'E', type: 'ee'),
      Model(name: 'F', type: 'cc'),
      Model(name: 'G', type: 'gg'),
      Model(name: 'H', type: 'hh'),
      Model(name: 'I', type: 'ii'),
      Model(name: 'J', type: 'jj'),
      Model(name: 'K', type: 'kk'),
      Model(name: 'L', type: 'll'),
      Model(name: 'M', type: 'mm'),
      Model(name: 'N', type: 'nn'),
      Model(name: 'O', type: 'oo'),
      Model(name: 'P', type: 'pp'),
      Model(name: 'Q', type: 'qq'),
      Model(name: 'R', type: 'rr'),
      Model(name: 'S', type: 'ss'),
      Model(name: 'T', type: 'tt'),
      Model(name: 'U', type: 'uu'),
      Model(name: 'V', type: 'vv'),
      Model(name: 'W', type: 'ww'),
      Model(name: 'X', type: 'xx'),
      Model(name: 'Y', type: 'yy'),
      Model(name: 'Z', type: 'zz'),
    ];

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Custom Staggered GridView'),
        ),
        // body: listView(staggered),
        body: staggered(list: list, type: list[i].type),
      ),
    );
  }

  Widget staggered({required List<Model> list, required String type}) {
    if (list[list.length - 1].type == type) {
      Model model = list[list.length - 1];
      list.remove(model);
      list.insert(list.length - 2, model);
    }
    return StaggeredGridView.countBuilder(
      crossAxisCount: 2,
      itemBuilder: (BuildContext context, int index) {
        /* if (index == list.length - 3 &&  list[list.length - 1].type == type) {
          Model model = list[list.length - 1];
          list.remove(model);
          list.insert(list.length - 2, model);
        }*/
        if (list[index].type == type) {
          if (index % 2 == 0) {
            position = index;
            intArr.add(position);
            return typeView(list[index]);
          } else {
            position = index + 1;
            if (position < list.length) {
              Model model = list[index];
              list.remove(model);
              list.insert(position, model);
            } else {
              position == index;
            }
            return commonView(list[index]);
          }
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

  void move<T>(List<T> list, int oldIndex, int newIndex) {
    var item = list[oldIndex];
    list.removeAt(oldIndex);

    if (newIndex > oldIndex) newIndex--;
    // the actual index could have shifted due to the removal

    list.insert(newIndex, item);
  }
}
