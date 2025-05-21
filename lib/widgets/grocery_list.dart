import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:shopping_list/data/categories.dart";

import "package:shopping_list/models/grocery_item.dart";
import "package:shopping_list/widgets/new_item.dart";
import "package:shopping_list/models/category.dart";

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  String? _error;
  bool _isLoading = true;

  void _loadItems() async {
    final Uri url = Uri.https(
      "shopping-list-91b3a-default-rtdb.asia-southeast1.firebasedatabase.app",
      "shopping-list.json",
    );
    try {
      final http.Response response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = "Failed to fetch data. Please try again later.";
        });
        return;
      }

      if (response.body == "null") {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final Category category =
            categories.entries
                .firstWhere(
                  (catItem) => catItem.value.title == item.value["category"],
                )
                .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = "Something went wrong! Please try again later.";
      });
    }
  }

  void _addItem() async {
    final GroceryItem? newItem = await Navigator.of(
      context,
    ).push<GroceryItem?>(MaterialPageRoute(builder: (ctx) => NewItem()));

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems = [..._groceryItems, newItem];
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems =
          _groceryItems
              .where((groceryItem) => item.id != groceryItem.id)
              .toList();
    });
    final Uri url = Uri.https(
      "shopping-list-91b3a-default-rtdb.asia-southeast1.firebasedatabase.app",
      "shopping-list.json",
    );
    final http.Response response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        final List<GroceryItem> newItems = [..._groceryItems];
        newItems.insert(index, item);
        _groceryItems = newItems;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(child: Text("No items added yet."));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder:
            (ctx, index) => Dismissible(
              key: ValueKey(_groceryItems[index].id),
              child: ListTile(
                title: Text(_groceryItems[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: _groceryItems[index].category.color,
                ),
                trailing: Text(_groceryItems[index].quantity.toString()),
              ),
              onDismissed: (DismissDirection direction) {
                _removeItem(_groceryItems[index]);
              },
            ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Your groceries"),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
