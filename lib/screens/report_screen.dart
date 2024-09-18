import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/firebase_service.dart';

class ReportScreen extends StatefulWidget {
  final bool isAdmin;

  ReportScreen({required this.isAdmin});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  bool isAdmin;

  _ReportScreenState() : isAdmin = false;

  @override
  void initState() {
    super.initState();
    isAdmin = widget.isAdmin;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf(BuildContext context, String reportType) async {
    final pdf = pw.Document();

    if (reportType == 'monthly') {
      await _addMonthlyPaymentReport(pdf);
    } else {
      await _addRentalBalanceReport(pdf);
    }

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share PDF'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Printing.sharePdf(
                    bytes: await pdf.save(),
                    filename: '$reportType-report.pdf',
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.save),
                title: Text('Save Locally'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _saveLocally(pdf, reportType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveLocally(pw.Document pdf, String reportType) async {
    final output = await getExternalStorageDirectory();
    final file = File("${output?.path}/$reportType-report.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF saved locally to ${file.path}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _addMonthlyPaymentReport(pw.Document pdf) async {
    final payments = await _firebaseService.getPaymentsForMonth(
      DateFormat('MMMM').format(DateTime.now()),
      DateTime.now().year.toString(),
      isAdmin: isAdmin,
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Monthly Payment Report'),
              ),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Name', 'House #', 'Date', 'Amount'],
                  ...payments.map((data) {
                    return [
                      data['tenantName']?.toString() ?? 'N/A',
                      data['houseNumber']?.toString() ?? 'N/A',
                      DateFormat('MMM dd, yyyy')
                          .format((data['paymentDate'] as Timestamp).toDate()),
                      'P${data['amount']?.toString() ?? '0'}',
                    ];
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addRentalBalanceReport(pw.Document pdf) async {
    final snapshot = await _firebaseService.getHousesWithBalance();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Rental Balance Report'),
              ),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Name', 'House #', 'Balance'],
                  ...snapshot.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return [
                      data['tenantName']?.toString() ?? 'N/A',
                      data['houseNumber']?.toString() ?? 'N/A',
                      'P${data['currentBalance']?.toString() ?? '0'}',
                    ];
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Monthly Payments'),
            Tab(text: 'Rental Balances'),
          ],
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelColor: Theme.of(context).colorScheme.secondary,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MonthlyPaymentReport(
            firebaseService: _firebaseService,
            isAdmin: isAdmin,
          ),
          RentalBalanceReport(firebaseService: _firebaseService),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generatePdf(
          context,
          _tabController.index == 0 ? 'monthly' : 'rental',
        ),
        label: Text('Generate PDF'),
        icon: Icon(Icons.picture_as_pdf),
      ),
    );
  }
}

class MonthlyPaymentReport extends StatefulWidget {
  final FirebaseService firebaseService;
  final bool isAdmin;

  MonthlyPaymentReport({required this.firebaseService, required this.isAdmin});

  @override
  _MonthlyPaymentReportState createState() => _MonthlyPaymentReportState();
}

class _MonthlyPaymentReportState extends State<MonthlyPaymentReport> {
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  String _selectedYear = DateTime.now().year.toString();
  List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    items: _months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMonth = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.firebaseService.getPaymentsForMonth(
                _selectedMonth, _selectedYear,
                isAdmin: widget.isAdmin),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No payments found for this month.'));
              }

              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var paymentData = snapshot.data![index];
                  return ReportItem(
                    name: paymentData['tenantName'] ?? 'N/A',
                    houseNumber: paymentData['houseNumber'] ?? 'N/A',
                    date: DateFormat('MMM dd, yyyy')
                        .format(paymentData['paymentDate'].toDate()),
                    amount: 'P${paymentData['amount']}',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class RentalBalanceReport extends StatelessWidget {
  final FirebaseService firebaseService;

  RentalBalanceReport({required this.firebaseService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: firebaseService.getHousesWithBalance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No rental balances found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var houseData =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return RentalBalanceItem(
              name: houseData['tenantName'] ?? 'N/A',
              houseNumber: houseData['houseNumber'] ?? 'N/A',
              balance: 'P${houseData['currentBalance']}',
            );
          },
        );
      },
    );
  }
}

class ReportItem extends StatelessWidget {
  final String name;
  final String houseNumber;
  final String date;
  final String amount;

  const ReportItem({
    Key? key,
    required this.name,
    required this.houseNumber,
    required this.date,
    required this.amount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text('House #: $houseNumber'),
              Text('Date: $date'),
            ],
          ),
          trailing: Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class RentalBalanceItem extends StatelessWidget {
  final String name;
  final String houseNumber;
  final String balance;

  const RentalBalanceItem({
    Key? key,
    required this.name,
    required this.houseNumber,
    required this.balance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          contentPadding: EdgeInsets.all(16),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('House #: $houseNumber'),
          trailing: Text(
            balance,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
