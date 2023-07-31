import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_app/auth.dart';

class ItemListWidget extends StatefulWidget {
  @override
  _ItemListWidgetState createState() => _ItemListWidgetState();
}

class _ItemListWidgetState extends State<ItemListWidget> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  Map<String, int?> items = {};
  int? total = 0;
  bool isVisible = false;
  bool isVisibility = false;

  void toggleVisible() {
    setState(() {
      isVisibility = !isVisibility;
    });
  }

  void addItem(String name, int? price) {
    setState(() {
      items[name] = price;
      total = (total ?? 0) + (price ?? 0);
    });
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('items')
          .get()
          .then((querySnapshot) {
        setState(() {
          items = {};
          total = 0;
          querySnapshot.docs.forEach((doc) {
            String name = doc['name'];
            int price = doc['price'];
            items[name] = price;
            total = total! + price;
          });
        });
      }).catchError((error) {
        print("Error fetching data: $error");
      });
    }
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
                    controller: _nameController,
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
                    controller: _priceController,
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
                          addItemToFirebase();
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

  void addItemToFirebase() {
    String name = _nameController.text;
    int? price = int.tryParse(_priceController.text);

    if (name.isNotEmpty && price != null) {
      // Get the current user's UID
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        // Add the data to Firestore under the user's specific collection
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('items')
            .add({
          'name': name,
          'price': price,
          // You can add more fields here if needed
        }).then((_) {
          // Data added successfully, clear the text fields
          setState(() {
            addItem(name, price);
          });
          _nameController.clear();
          _priceController.clear();
        }).catchError((error) {
          // Error occurred while adding data
          print("Error adding data: $error");
        });
      }
    }
  }

  void deleteItem(String key, int? value) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Delete the document from Firestore
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('items')
          .where('name', isEqualTo: key)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          querySnapshot.docs.first.reference.delete().then((_) {
            // Document deleted successfully, update the local state
            setState(() {
              items.remove(key);
              total = (total ?? 0) - (value ?? 0);
            });
          }).catchError((error) {
            // Error occurred while deleting document
            print("Error deleting document: $error");
          });
        }
      }).catchError((error) {
        // Error occurred while fetching document to delete
        print("Error fetching document to delete: $error");
      });
    }
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

    final User? user = Auth().currentUser;

    Widget _userUid() {
      return Text(user?.email ?? 'User email');
    }

    Future<void> signOut() async {
      await Auth().signOut();
      fetchUserData();
      Navigator.pop(context);
    }

    Widget _signOutButton(BuildContext context) {
      return ElevatedButton(
          onPressed: () {
            signOut();
          },
          child: const Text('Sign Out'));
    }

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
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: _userUid(),
                  enabled: false,
                ),
                PopupMenuItem(
                  child: _signOutButton(context),
                  enabled: false,
                ),
              ];
            },
            onSelected: (value) {
              // Nothing to do here, no action is performed when an item is selected
            },
            icon: Icon(Icons.person),
          ),
        ],
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
