import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tenant_payments.dart';
import '../services/firebase_service.dart';

class MyTenants extends StatefulWidget {
  const MyTenants({Key? key}) : super(key: key);

  @override
  State<MyTenants> createState() => _MyTenantsState();
}

class _MyTenantsState extends State<MyTenants> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Tenants'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getHousesForCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('You have no houses with tenants.',
                    style: TextStyle(color: Colors.white)));
          }

          List<String> houseIds =
              snapshot.data!.docs.map((doc) => doc.id).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('accessRequests')
                .where('houseId', whereIn: houseIds)
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, requestsSnapshot) {
              if (requestsSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }

              if (requestsSnapshot.hasError) {
                return Center(
                    child: Text('Error: ${requestsSnapshot.error}',
                        style: TextStyle(color: Colors.white)));
              }

              if (!requestsSnapshot.hasData ||
                  requestsSnapshot.data!.docs.isEmpty) {
                return Center(
                    child: Text('You have no tenants.',
                        style: TextStyle(color: Colors.white)));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: requestsSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var requestData = requestsSnapshot.data!.docs[index].data()
                      as Map<String, dynamic>;
                  var tenantId = requestData['userId'];
                  var houseId = requestData['houseId'];

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _firebaseService.getUser(tenantId),
                    builder: (context, tenantSnapshot) {
                      if (tenantSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildShimmerCard();
                      }

                      if (tenantSnapshot.hasError || !tenantSnapshot.hasData) {
                        return _buildErrorCard('Error loading tenant');
                      }

                      var tenantData = tenantSnapshot.data!;
                      var houseData = snapshot.data!.docs
                          .firstWhere((doc) => doc.id == houseId)
                          .data() as Map<String, dynamic>;

                      return _buildTenantCard(
                          context, tenantData, houseData, houseId, tenantId);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.grey[300]!, Colors.grey[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.red[300]!, Colors.red[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
            child: Text(errorMessage, style: TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, Map<String, dynamic> tenantData,
      Map<String, dynamic> houseData, String houseId, String tenantId) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blueAccent),
          ),
          title: Text(
            '${tenantData['first_name']} ${tenantData['last_name']}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'House #: ${houseData['houseNumber']}',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TenantPayments(
                  houseId: houseId,
                  tenantId: tenantId,
                  tenantName:
                      '${tenantData['first_name']} ${tenantData['last_name']}',
                  houseNumber: houseData['houseNumber'],
                  monthlyRent: houseData['monthlyPayment'] ?? 0.0,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
