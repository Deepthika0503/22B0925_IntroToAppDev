import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:budget_app/auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class ItemListWidget extends StatefulWidget {
  @override
  _ItemListWidgetState createState() => _ItemListWidgetState();
}

class _ItemListWidgetState extends State<ItemListWidget> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  Map<String, int?> items = {};
  int? savingsValue;
  int? total = 0;
  bool isVisible = false;
  bool isVisibility = false;

  void toggleVisible() {
    setState(() {
      isVisibility = !isVisibility;
    });
  }

  Future<void> exportDataToPDF() async {
    // Permission is granted, proceed with exporting PDF
    final pdf = pw.Document();
    // Rest of your export code...

    // Create a PDF table
    final table = pw.TableHelper.fromTextArray(
      data: [
        ['Category', 'Price'],
        for (var entry in items.entries) [entry.key, entry.value.toString()],
      ],
      cellPadding: pw.EdgeInsets.all(10),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    );

    // Add the table to the PDF document
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(child: table),
          );
        },
      ),
    );

    // Get the device's document directory
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      print('File Path: ${directory?.path}');
      final file = File('${directory.path}/budget_tracker_data.pdf');

      // Write the PDF data to the file
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(file.path);
    }
  }

  void setSavingsValue(int savings) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'savings': savings}, SetOptions(merge: true)).then((_) {
        setState(() {
          savingsValue = savings;
        });
      }).catchError((error) {
        print("Error setting savings value: $error");
      });
    }
  }

  Future<void> showSetSavingsDialog() async {
    int? newSavings;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text('Set Savings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        newSavings = int.tryParse(value);
                      });
                    },
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Savings Amount',
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: newSavings != null
                      ? () {
                          Navigator.of(context).pop();
                          setSavingsValue(newSavings!);
                        }
                      : null,
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void addItem(String name, int? price) {
    setState(() {
      items[name] = price;
      total = (total ?? 0) + (price ?? 0);
    });
    showSavingsWarning();
  }

  void editItem(String key, int? originalPrice, int? editedPrice) {
    if (editedPrice != null && originalPrice != editedPrice) {
      setState(() {
        total = (total ?? 0) - (originalPrice ?? 0) + editedPrice;
        items[key] = editedPrice;
      });

      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Update the edited price in Firestore
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('items')
            .where('name', isEqualTo: key)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            querySnapshot.docs.first.reference
                .update({'price': editedPrice}).then((_) {
              // Document updated successfully
            }).catchError((error) {
              // Error occurred while updating document
              print("Error updating document: $error");
            });
          }
        }).catchError((error) {
          // Error occurred while fetching document to update
          print("Error fetching document to update: $error");
        });
      }
      showSavingsWarning();
    }
  }

  void showSavingsWarning() {
    if (savingsValue != null && total! < savingsValue!) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Warning'),
            content: Text('You are out of your savings.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
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
          .get()
          .then((docSnapshot) {
        setState(() {
          items = {};
          total = 0;
          if (docSnapshot.exists) {
            // Fetch the savings value from the document
            savingsValue = docSnapshot['savings'] ?? 0;
          }
        });
      }).catchError((error) {
        print("Error fetching user data: $error");
      });

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

  void showEditItemDialog(String key, int? value) async {
    int? editedPrice = value;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text('Edit Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$key', // Display the name (category) as read-only text
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextField(
                    controller: TextEditingController(text: value.toString()),
                    onChanged: (value) {
                      editedPrice = int.tryParse(value);
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (editedPrice != null) {
                      editItem(key, value, editedPrice);
                    }
                  },
                  child: Text('Save'),
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
    setState(() {
      items.remove(key);
      total = (total ?? 0) - (value ?? 0);
    });

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
    showSavingsWarning();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildTableRow(String key, int? value) {
      return Table(
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.transparent),
          children: [
            TableRow(
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
                        showEditItemDialog(key, value);
                      },
                      icon: Icon(Icons.edit),
                    ),
                  ),
                ),
              ],
            )
          ]);
    }

    double categoryColumnWidth = isVisible ? 2 : 1.5;
    double priceColumnWidth = 1;

    Widget buildTotalRow() {
      return Table(
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.transparent),
          children: [
            TableRow(
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
            )
          ]);
    }

    Widget buildDismissibleItem(String key, int? value) {
      return Dismissible(
        key: Key(key), // Unique key for each item
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          color: Colors.red,
          child: Icon(
            Icons.delete,
            color: Colors.black,
          ),
        ),
        onDismissed: (direction) {
          deleteItem(key, value);
        },
        child: buildTableRow(key, value),
      );
    }

    ListView.builder(
      itemCount: items.length + 1, // +1 for the total row
      itemBuilder: (context, index) {
        if (index == 0) {
          return buildTotalRow();
        } else {
          // Subtract 1 to account for the total row
          int itemIndex = index - 1;
          String key = items.keys.toList()[itemIndex];
          int? value = items.values.toList()[itemIndex];
          return buildDismissibleItem(key, value);
        }
      },
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
          IconButton(
            onPressed: () {
              // Call the exportDataToPDF function when export button is tapped
              exportDataToPDF();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data exported to PDF file.'),
                ),
              );
            },
            icon: Icon(Icons.file_download),
          ),
          IconButton(
            onPressed: showSetSavingsDialog,
            icon: Icon(Icons.monetization_on),
          ),
        ],
      ),
      body: Container(
        color: Colors.purple[200],
        child: Column(
          children: [
            buildTotalRow(),
            Visibility(
              visible: isVisible,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  String key = items.keys.toList()[index];
                  int? value = items.values.toList()[index];
                  return buildDismissibleItem(key, value);
                },
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
