import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class InfoUserRent extends StatefulWidget {
  final String houseId;
  final String tenantId;

  const InfoUserRent({Key? key, required this.houseId, required this.tenantId})
      : super(key: key);

  @override
  _InfoUserRentState createState() => _InfoUserRentState();
}

class _InfoUserRentState extends State<InfoUserRent> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  String? _tenantName;
  DateTime? _startDate;
  double? _monthlyPayment;

  @override
  void initState() {
    super.initState();
    _loadTenantInfo();
  }

  void _loadTenantInfo() async {
    DocumentSnapshot houseDoc = await FirebaseFirestore.instance
        .collection('houses')
        .doc(widget.houseId)
        .get();

    if (houseDoc.exists) {
      Map<String, dynamic> data = houseDoc.data() as Map<String, dynamic>;
      setState(() {
        _startDate = data['startDate']?.toDate();
        // Convert monthlyPayment to double if it's an int
        _monthlyPayment = (data['monthlyPayment'] is int)
            ? (data['monthlyPayment'] as int).toDouble()
            : data['monthlyPayment'];
      });
    }

    DocumentSnapshot tenantDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.tenantId)
        .get();

    if (tenantDoc.exists) {
      Map<String, dynamic> tenantData =
          tenantDoc.data() as Map<String, dynamic>;
      setState(() {
        _tenantName = '${tenantData['first_name']} ${tenantData['last_name']}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Information'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('House ID: ${widget.houseId}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Tenant Name: ${_tenantName ?? 'Loading...'}',
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 16),
              ListTile(
                title: Text('Start Date'),
                subtitle: Text(_startDate?.toString() ?? 'Not set'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                    });
                  }
                },
              ),
              TextFormField(
                initialValue: _monthlyPayment?.toString(),
                decoration: InputDecoration(labelText: 'Monthly Payment'),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                    _monthlyPayment = double.tryParse(value ?? ''),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an amount' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTenantInfo,
                child: Text('Update Tenant Info'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _removeTenant,
                child: Text('Remove Tenant'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTenantInfo() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .update({
          'tenantId': widget.tenantId,
          'startDate': _startDate,
          'monthlyPayment': _monthlyPayment,
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tenant information updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating tenant information: $e')));
      }
    }
  }

  void _removeTenant() async {
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
        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .update({
          'tenantId': FieldValue.delete(),
          'startDate': FieldValue.delete(),
          'monthlyPayment': FieldValue.delete(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tenant removed successfully')));
        Navigator.of(context).pop(); // Return to the previous screen
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error removing tenant: $e')));
      }
    }
  }
}
