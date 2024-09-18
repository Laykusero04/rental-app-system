import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class TenantPayments extends StatefulWidget {
  final String houseId;
  final String tenantId;
  final String tenantName;
  final String houseNumber;
  final double monthlyRent;

  const TenantPayments({
    Key? key,
    required this.houseId,
    required this.tenantId,
    required this.tenantName,
    required this.houseNumber,
    required this.monthlyRent,
  }) : super(key: key);

  @override
  _TenantPaymentsState createState() => _TenantPaymentsState();
}

class _TenantPaymentsState extends State<TenantPayments> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _balanceController;
  DateTime _selectedDate = DateTime.now();
  double _tenantMonthlyRate = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _balanceController = TextEditingController();
    _loadTenantData();
  }

  void _loadTenantData() async {
    DocumentSnapshot houseDoc = await FirebaseFirestore.instance
        .collection('houses')
        .doc(widget.houseId)
        .get();

    if (houseDoc.exists) {
      var data = houseDoc.data() as Map<String, dynamic>;
      var tenants = data['tenants'] as Map<String, dynamic>? ?? {};
      var tenantData = tenants[widget.tenantId] as Map<String, dynamic>? ?? {};

      setState(() {
        _balanceController.text =
            (tenantData['currentBalance'] ?? widget.monthlyRent).toString();
        // Convert tenantData['monthlyRate'] to double if it's not null
        _tenantMonthlyRate =
            (tenantData['monthlyRate']?.toDouble() ?? widget.monthlyRent);
      });
    } else {
      _balanceController.text = widget.monthlyRent.toString();
      _tenantMonthlyRate = widget.monthlyRent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Payments for ${widget.tenantName}'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                SizedBox(height: 20),
                _buildPaymentForm(),
                SizedBox(height: 20),
                _buildPaymentHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'House #: ${widget.houseNumber}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Monthly Rate: ₱${_tenantMonthlyRate.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixIcon: Icon(Icons.attach_money, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Current Balance',
                  prefixIcon:
                      Icon(Icons.account_balance_wallet, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the current balance';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Payment Date',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      Icon(Icons.arrow_drop_down, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addPayment,
                child: Text('Add Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('houses')
                  .doc(widget.houseId)
                  .collection('payments')
                  .where('tenantId', isEqualTo: widget.tenantId)
                  .orderBy('paymentDate', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No payment history available.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var paymentData = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(Icons.payment, color: Colors.blue),
                        title: Text('₱${paymentData['amount']}',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('yyyy-MM-dd')
                            .format(paymentData['paymentDate'].toDate())),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addPayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        double amount = double.parse(_amountController.text);
        double currentBalance = double.parse(_balanceController.text);
        double newBalance = currentBalance - amount;

        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .collection('payments')
            .add({
          'amount': amount,
          'paymentDate': _selectedDate,
          'tenantId': widget.tenantId,
        });

        await FirebaseFirestore.instance
            .collection('houses')
            .doc(widget.houseId)
            .update({
          'tenants.${widget.tenantId}.currentBalance': newBalance,
        });

        setState(() {
          _balanceController.text = newBalance.toString();
          _amountController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment added successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error adding payment: $e')));
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
}
