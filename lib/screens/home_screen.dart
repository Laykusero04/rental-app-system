import 'package:flutter/material.dart';
import 'package:rental_app_system/componets/custom_drawer.dart';
import '../componets/info_card.dart';
import 'houses_list.dart';

class HomeScreen extends StatefulWidget {
  final int userRole;

  const HomeScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _appBarTitle {
    switch (widget.userRole) {
      case 1:
        return 'Admin Dashboard';
      case 2:
        return 'Landowner Dashboard';
      case 3:
        return 'Tenant Home';
      default:
        return 'Home';
    }
  }

  Widget _buildAdminView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildResponsiveGrid(
          constraints,
          [
            InfoCard(
                title: 'Total Houses',
                value: '8',
                icon: Icons.home,
                iconSize: 40),
            InfoCard(
                title: 'Total Tenants',
                value: '3',
                icon: Icons.people,
                iconSize: 40),
            InfoCard(
                title: 'Total Land Owners',
                value: '23',
                icon: Icons.person,
                iconSize: 40),
            InfoCard(
                title: 'Total House Types',
                value: '5',
                icon: Icons.category,
                iconSize: 40),
          ],
        );
      },
    );
  }

  Widget _buildLandlordView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildResponsiveGrid(
          constraints,
          [
            InfoCard(
                title: 'My Houses', value: '3', icon: Icons.home, iconSize: 40),
            InfoCard(
                title: 'My Tenants',
                value: '2',
                icon: Icons.people,
                iconSize: 40),
            InfoCard(
                title: 'Total Payments',
                value: '₱15,000',
                icon: Icons.payments,
                iconSize: 40),
            InfoCard(
                title: 'Vacant Houses',
                value: '1',
                icon: Icons.house,
                iconSize: 40),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveGrid(
      BoxConstraints constraints, List<Widget> children) {
    int crossAxisCount;
    double childAspectRatio;
    if (constraints.maxWidth > 1200) {
      crossAxisCount = 4;
      childAspectRatio = 1.7;
    } else if (constraints.maxWidth > 800) {
      crossAxisCount = 3;
      childAspectRatio = 1.6;
    } else if (constraints.maxWidth > 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.5;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 1;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      padding: EdgeInsets.all(16.0),
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      children: children,
    );
  }

  Widget _buildTenantView() {
    return HousesList(userRole: widget.userRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu, size: 28),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(_appBarTitle),
      ),
      drawer: CustomDrawer(userRole: widget.userRole),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.userRole) {
      case 1:
        return _buildAdminView();
      case 2:
        return _buildLandlordView();
      case 3:
        return _buildTenantView();
      default:
        return Center(child: Text('Unknown user role'));
    }
  }
}
