import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart';

class HouseTypesList extends StatefulWidget {
  @override
  _HouseTypesListState createState() => _HouseTypesListState();
}

class _HouseTypesListState extends State<HouseTypesList> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('House Types'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.toLowerCase();
                    });
                  },
                  child: Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseService.getHouseTypes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var houseTypes = snapshot.data!.docs
                    .where((doc) => doc['type']
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery))
                    .toList();

                return ListView.builder(
                  itemCount: houseTypes.length,
                  itemBuilder: (context, index) {
                    var houseType = houseTypes[index];
                    return HouseTypeItem(
                      id: houseType.id,
                      type: houseType['type'],
                      onEdit: () =>
                          _editHouseType(houseType.id, houseType['type']),
                      onDelete: () => _deleteHouseType(houseType.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHouseType,
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _addHouseType() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add House Type'),
        content: TextField(
          controller: _typeController,
          decoration: InputDecoration(hintText: 'Enter house type'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_typeController.text.isNotEmpty) {
                await _firebaseService.addHouseType(_typeController.text);
                _typeController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editHouseType(String id, String currentType) async {
    _typeController.text = currentType;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit House Type'),
        content: TextField(
          controller: _typeController,
          decoration: InputDecoration(hintText: 'Enter new house type'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_typeController.text.isNotEmpty) {
                await _firebaseService.updateHouseType(
                    id, _typeController.text);
                _typeController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHouseType(String id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete House Type'),
        content: Text('Are you sure you want to delete this house type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await _firebaseService.deleteHouseType(id);
    }
  }
}

class HouseTypeItem extends StatelessWidget {
  final String id;
  final String type;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HouseTypeItem({
    Key? key,
    required this.id,
    required this.type,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white, // White text to contrast the gradient
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
