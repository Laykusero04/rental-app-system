import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HouseInfo extends StatefulWidget {
  final String houseId;
  final int userRole;

  const HouseInfo({Key? key, required this.houseId, required this.userRole})
      : super(key: key);

  @override
  _HouseInfoState createState() => _HouseInfoState();
}

class _HouseInfoState extends State<HouseInfo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('House Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'House Info'),
                Tab(text: 'Tenant Management'),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHouseInfoTab(),
                _buildTenantManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseInfoTab() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('House not found'));
        }

        var houseData = snapshot.data!.data() as Map<String, dynamic>;

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Web layout
              return _buildWebLayout(houseData);
            } else {
              // Mobile layout
              return _buildMobileLayout(houseData);
            }
          },
        );
      },
    );
  }

  Widget _buildWebLayout(Map<String, dynamic> houseData) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  houseData['imageUrl'] ??
                      'https://via.placeholder.com/400x300',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'House #: ${houseData['houseNumber']}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'House Type: ${houseData['houseType']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Description:',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(houseData['description']),
                  SizedBox(height: 16),
                  Text(
                    'Price: ${_formatPrice(houseData['price'])}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Contact: ${houseData['contactNumber'] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 16),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(houseData['createdBy'])
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Text('Created by: Loading...');
                      }
                      if (userSnapshot.hasError || !userSnapshot.hasData) {
                        return Text('Created by: Unknown');
                      }
                      var userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      return Text(
                        'Created by: ${userData['first_name']} ${userData['last_name']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  if (widget.userRole == 3) // Only show for tenants
                    ElevatedButton(
                      onPressed: () => _requestAccess(context),
                      child: Text('Request Access to Transaction History'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic> houseData) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              houseData['imageUrl'] ?? 'https://via.placeholder.com/400x300',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'House #: ${houseData['houseNumber']}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'House Type: ${houseData['houseType']}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: 16),
                Text(
                  'Description:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(houseData['description']),
                SizedBox(height: 16),
                Text(
                  'Price: ${_formatPrice(houseData['price'])}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.green),
                ),
                SizedBox(height: 16),
                Text(
                  'Contact: ${houseData['contactNumber'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: 16),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(houseData['createdBy'])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Text('Created by: Loading...');
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData) {
                      return Text('Created by: Unknown');
                    }
                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    return Text(
                      'Created by: ${userData['first_name']} ${userData['last_name']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
                SizedBox(height: 24),
                if (widget.userRole == 3) // Only show for tenants
                  ElevatedButton(
                    onPressed: () => _requestAccess(context),
                    child: Text('Request Access to Transaction History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantManagementTab() {
    if (widget.userRole != 2) {
      return Center(child: Text('Only landlords can manage tenants.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('accessRequests')
          .where('houseId', isEqualTo: widget.houseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<QueryDocumentSnapshot> requests = snapshot.data?.docs ?? [];

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) => _buildRequestTile(requests[index]),
        );
      },
    );
  }

  Widget _buildRequestTile(QueryDocumentSnapshot request) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(request['userId'])
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text('Loading...'));
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return ListTile(title: Text('Error loading user'));
        }
        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text('${userData['first_name']} ${userData['last_name']}'),
            subtitle: Text('Status: ${request['status']}'),
            trailing: _buildActionButtons(request),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(QueryDocumentSnapshot request) {
    switch (request['status']) {
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: () => _approveRequest(request.id, request['userId']),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () => _denyRequest(request.id),
            ),
          ],
        );
      case 'approved':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.attach_money, color: Colors.blue),
              onPressed: () => _setMonthlyRate(request['userId']),
            ),
            IconButton(
              icon: Icon(Icons.person_remove, color: Colors.red),
              onPressed: () => _removeTenant(request['userId']),
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }

  void _approveRequest(String requestId, String userId) async {
    try {
      // Step 1: Update the access request status
      await FirebaseFirestore.instance
          .collection('accessRequests')
          .doc(requestId)
          .update({'status': 'approved'});

      print('Access request updated successfully'); // Debug print

      // Step 2: Update the house document
      DocumentReference houseRef =
          FirebaseFirestore.instance.collection('houses').doc(widget.houseId);
      DocumentSnapshot houseSnapshot = await houseRef.get();

      if (!houseSnapshot.exists) {
        throw Exception('House not found');
      }

      Map<String, dynamic> houseData =
          houseSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> tenants =
          Map<String, dynamic>.from(houseData['tenants'] ?? {});
      tenants[userId] = {'monthlyRate': null, 'currentBalance': 0};

      await houseRef.update({'tenants': tenants});

      print('House document updated successfully'); // Debug print

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Request approved. Please set the monthly rate.')),
      );
    } catch (e) {
      print('Error in _approveRequest: $e'); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve request: ${e.toString()}')),
      );
    }
  }

  void _setMonthlyRate(String userId) async {
    String? monthlyRate = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _controller = TextEditingController();
        return AlertDialog(
          title: Text('Set Monthly Rate'),
          content: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Monthly Rate'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(_controller.text),
            ),
          ],
        );
      },
    );

    if (monthlyRate == null || monthlyRate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Monthly rate is required')),
      );
      return;
    }

    double rate = double.tryParse(monthlyRate) ?? 0;
    if (rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid monthly rate')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .update({
        'tenants.$userId.monthlyRate': rate,
        'tenants.$userId.currentBalance':
            rate, // Initialize balance with the monthly rate
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Monthly rate set successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set monthly rate: $e')),
      );
    }
  }

  void _removeTenant(String tenantId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Tenant'),
        content: Text('Are you sure you want to remove this tenant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        // Remove tenant from the house's tenant list
        DocumentReference houseRef =
            FirebaseFirestore.instance.collection('houses').doc(widget.houseId);
        DocumentSnapshot houseSnapshot = await houseRef.get();
        List<String> tenants =
            List<String>.from(houseSnapshot.get('tenants') ?? []);
        tenants.remove(tenantId);
        await houseRef.update({'tenants': tenants});

        // Update the access request status to 'removed'
        QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
            .collection('accessRequests')
            .where('houseId', isEqualTo: widget.houseId)
            .where('userId', isEqualTo: tenantId)
            .get();

        if (requestSnapshot.docs.isNotEmpty) {
          await requestSnapshot.docs.first.reference
              .update({'status': 'removed'});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tenant removed successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove tenant: $e')),
        );
      }
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    try {
      return currencyFormat.format(double.parse(price.toString()));
    } catch (e) {
      print('Error formatting price: $e');
      return 'Invalid Price';
    }
  }

  void _requestAccess(BuildContext context) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      await FirebaseFirestore.instance.collection('accessRequests').add({
        'userId': currentUser.uid,
        'houseId': widget.houseId,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access request submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    }
  }

  void _denyRequest(String requestId) {
    FirebaseFirestore.instance
        .collection('accessRequests')
        .doc(requestId)
        .update({'status': 'denied'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request denied')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deny request: $error')),
      );
    });
  }
}
