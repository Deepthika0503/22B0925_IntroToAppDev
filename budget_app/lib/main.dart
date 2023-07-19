import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: ItemListWidget(),
  ));
}

class ItemListWidget extends StatefulWidget {
  @override
  _ItemListWidgetState createState() => _ItemListWidgetState();
}

class _ItemListWidgetState extends State<ItemListWidget> {
  Map<String, int?> items = {};
  int? total = 0;
  bool isVisible = false;

  void addItem(String name, int? price) {
    setState(() {
      items[name] = price;
      total = (total ?? 0) + (price ?? 0);
    });
  }

  void toggleVisibility() {
    setState(() {
      isVisible = !isVisible;
    });
  }

  bool checkVisibility() {
    return items.isNotEmpty;
  }

  Future<void> showAddItemDialog() async {
    String name = '';
    int? price;
    bool isFormValid = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text('New Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      name = value;
                      setState(() {
                        isFormValid = name.isNotEmpty && price != null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Category',
                    ),
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        price = int.tryParse(value);
                        isFormValid = name.isNotEmpty && price != null;
                      });
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price',
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: isFormValid
                      ? () {
                    Navigator.of(context).pop();
                    addItem(name, price);
                  }
                      : null,
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteItem(String key, int? value) {
    setState(() {
      items.remove(key);
      total = (total ?? 0) - (value ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<TableRow> categoryRows = items.entries.map((entry) {
      var key = entry.key;
      var value = entry.value;
      return TableRow(
        children: [
          TableCell(
            child: Container(
              color: Colors.purple[100],
              padding: EdgeInsets.all(15.0),
              child: Text(
                '$key',
                style: TextStyle(
                  color: Colors.purple[250],
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          TableCell(
            child: Container(
              color: Colors.purple[100],
              padding: EdgeInsets.all(15.0),
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          TableCell(
            child: Container(
              color: Colors.purple[100],
              padding: EdgeInsets.only(top: 8.0),
              child: IconButton(
                onPressed: () {
                  deleteItem('$key', value);
                },
                icon: Icon(Icons.delete),
              ),
            ),
          ),
        ],
      );
    }).toList();

    double categoryColumnWidth = isVisible ? 2 : 1.5;
    double priceColumnWidth = 1;

    TableRow totalRow = TableRow(
      children: [
        TableCell(
          child: Container(
            color: Colors.purple[100],
            padding: EdgeInsets.all(15.0),
            child: Text(
              'Total',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        TableCell(
          child: Visibility(
            visible: checkVisibility(),
            child: Container(
              color: Colors.purple[100],
              padding: EdgeInsets.all(15.0),
              child: Text(
                '$total',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            replacement: Container(
              color: Colors.purple[100],
              padding: EdgeInsets.all(15.0),
              child: Text(
                '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: Container(
            color: Colors.purple[100],
            padding: EdgeInsets.all(14.5),
            child: GestureDetector(
              onTap: toggleVisibility,
              child: Icon(Icons.arrow_drop_down_circle_outlined),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text(
          'Budget Tracker',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: Colors.purple[200],
        child: Column(
          children: [
            Table(
              columnWidths: {
                0: FlexColumnWidth(categoryColumnWidth),
                1: FlexColumnWidth(priceColumnWidth),
              },
              border: TableBorder.all(color: Colors.transparent),
              children: [totalRow],
            ),
            Visibility(
              visible: isVisible,
              child: Table(
                columnWidths: {
                  0: FlexColumnWidth(categoryColumnWidth),
                  1: FlexColumnWidth(priceColumnWidth),
                },
                border: TableBorder.all(color: Colors.transparent),
                children: categoryRows,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddItemDialog,
        backgroundColor: Colors.purple[100],
        child: Icon(Icons.add),
      ),
    );
  }
}
