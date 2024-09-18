import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/firebase_service.dart';
import 'add_house.dart';
import 'house_info.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';

class HousesList extends StatefulWidget {
  final int userRole;

  const HousesList({Key? key, required this.userRole}) : super(key: key);

  @override
  _HousesListState createState() => _HousesListState();
}

class _HousesListState extends State<HousesList> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.userRole != 3
          ? AppBar(
              title:
                  Text('Houses', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              elevation: 0,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search houses...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredHousesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var houses = snapshot.data!.docs
                    .where((doc) =>
                        doc['houseNumber']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        doc['houseType']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        doc['description']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery))
                    .toList();

                if (houses.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_work, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No houses found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Mobile layout
                      return ListView.builder(
                        itemCount: houses.length,
                        itemBuilder: (context, index) {
                          var house = houses[index];
                          return HouseItem(
                            id: house.id,
                            houseNumber: house['houseNumber'],
                            houseType: house['houseType'],
                            description: house['description'],
                            price: house['price'],
                            createdBy: house['createdBy'],
                            imageUrl: house['imageUrl'],
                            contactNumber: _getContactNumber(house),
                            onEdit: widget.userRole != 3
                                ? () => _editHouse(house.id,
                                    house.data() as Map<String, dynamic>)
                                : null,
                            onDelete: widget.userRole != 3
                                ? () => _deleteHouse(house.id)
                                : null,
                            userRole: widget.userRole,
                          );
                        },
                      );
                    } else {
                      // Web layout
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth ~/ 300,
                          childAspectRatio: 0.80,
                        ),
                        itemCount: houses.length,
                        itemBuilder: (context, index) {
                          var house = houses[index];
                          return HouseItem(
                            id: house.id,
                            houseNumber: house['houseNumber'],
                            houseType: house['houseType'],
                            description: house['description'],
                            price: house['price'],
                            createdBy: house['createdBy'],
                            imageUrl: house['imageUrl'],
                            contactNumber: _getContactNumber(house),
                            onEdit: widget.userRole != 3
                                ? () => _editHouse(house.id,
                                    house.data() as Map<String, dynamic>)
                                : null,
                            onDelete: widget.userRole != 3
                                ? () => _deleteHouse(house.id)
                                : null,
                            userRole: widget.userRole,
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.userRole != 3
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AddHouse()));
              },
              icon: Icon(Icons.add),
              label: Text('Add House'),
            )
          : null,
    );
  }

  String _getContactNumber(DocumentSnapshot house) {
    try {
      return house['contactNumber'] ?? 'N/A';
    } catch (e) {
      print('Error getting contact number: $e');
      return 'N/A';
    }
  }

  Stream<QuerySnapshot> _getFilteredHousesStream() {
    if (widget.userRole == 1) {
      // Admin can see all houses
      return _firebaseService.getHouses();
    } else if (widget.userRole == 2) {
      // Landowner can only see their own houses
      return _firebaseService.getHousesForCurrentUser();
    } else {
      // Tenant can see all houses (or you might want to filter for available houses only)
      return _firebaseService.getHouses();
    }
  }

  Future<void> _editHouse(String id, Map<String, dynamic> houseData) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddHouse(houseId: id, houseData: houseData)),
    );
  }

  Future<void> _deleteHouse(String id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete House'),
        content: Text('Are you sure you want to delete this house?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await _firebaseService.deleteHouse(id);
    }
  }
}

class HouseItem extends StatelessWidget {
  final String id;
  final String houseNumber;
  final String houseType;
  final String description;
  final String price;
  final String createdBy;
  final String? imageUrl;
  final String contactNumber;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int userRole;

  const HouseItem({
    Key? key,
    required this.id,
    required this.houseNumber,
    required this.houseType,
    required this.description,
    required this.price,
    required this.createdBy,
    this.imageUrl,
    required this.contactNumber,
    this.onEdit,
    this.onDelete,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget houseCard = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HouseInfo(houseId: id, userRole: userRole)),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'House #$houseNumber',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.home, houseType),
                  SizedBox(height: 4),
                  _buildInfoRow(Icons.description, description),
                  SizedBox(height: 4),
                  _buildInfoRow(Icons.attach_money, price),
                  SizedBox(height: 4),
                  _buildInfoRow(Icons.phone, contactNumber),
                  if (userRole != 2) SizedBox(height: 4),
                  if (userRole != 2) _buildCreatedBy(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (userRole == 3) {
      return houseCard;
    } else {
      return Slidable(
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            if (onEdit != null)
              SlidableAction(
                onPressed: (context) => onEdit!(),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
              ),
            if (onDelete != null)
              SlidableAction(
                onPressed: (context) => onDelete!(),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
          ],
        ),
        child: houseCard,
      );
    }
  }

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: Icon(Icons.home, size: 80, color: Colors.grey[400]),
      );
    }

    if (kIsWeb) {
      return Image.network(
        imageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.error);
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Icon(Icons.error),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatedBy() {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(createdBy).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildInfoRow(Icons.person, 'Loading...');
        }
        if (snapshot.hasError) {
          return _buildInfoRow(Icons.error, 'Error');
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String fullName =
              '${userData['first_name']} ${userData['last_name']}';
          return _buildInfoRow(Icons.person, 'Created by: $fullName');
        }
        return _buildInfoRow(Icons.person, 'Created by: Unknown');
      },
    );
  }
}
