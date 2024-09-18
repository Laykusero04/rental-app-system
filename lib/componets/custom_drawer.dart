import 'package:flutter/material.dart';
import 'package:rental_app_system/screens/home_screen.dart';
import 'package:rental_app_system/screens/my_rental.dart';
import 'package:rental_app_system/services/firebase_service.dart';
import 'package:rental_app_system/screens/login_screen.dart';
import '../screens/house_types_list.dart';
import '../screens/houses_list.dart';
import '../screens/my_tenants.dart';
import '../screens/report_screen.dart';
import '../screens/users_list.dart';
import '../screens/user_profile_screen.dart';

class CustomDrawer extends StatelessWidget {
  final int userRole;
  final FirebaseService _firebaseService = FirebaseService();

  CustomDrawer({Key? key, required this.userRole}) : super(key: key);

  bool get isAdmin => userRole == 1;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _buildDrawerContent(context),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _buildDrawerHeader(context),
        if (userRole == 1) ..._buildAdminMenuItems(context),
        if (userRole == 2) ..._buildLandlordMenuItems(context),
        if (userRole == 3) ..._buildTenantMenuItems(context),
        _buildUserProfileTile(context),
        const Divider(),
        _buildLogoutTile(context),
      ],
    );
  }

  Widget _buildUserProfileTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
      title:
          Text('User Profile', style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        _navigateTo(context,
            UserProfileScreen()); // Assuming you have a UserProfileScreen
      },
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getHeaderIcon(),
            size: 60,
            color: Colors.white,
          ),
          SizedBox(height: 10),
          Text(
            _getDrawerHeaderTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHeaderIcon() {
    switch (userRole) {
      case 1:
        return Icons.admin_panel_settings;
      case 2:
        return Icons.house;
      case 3:
        return Icons.person;
      default:
        return Icons.home;
    }
  }

  String _getDrawerHeaderTitle() {
    switch (userRole) {
      case 1:
        return 'Admin Menu';
      case 2:
        return 'Landowner Menu';
      case 3:
        return 'Tenant Menu';
      default:
        return 'Menu';
    }
  }

  List<Widget> _buildAdminMenuItems(BuildContext context) {
    return _buildMenuItems(
      context,
      [
        MenuItem(Icons.dashboard_outlined, 'Dashboard',
            () => _navigateTo(context, HomeScreen(userRole: userRole))),
        MenuItem(Icons.home_outlined, 'List of Houses',
            () => _navigateTo(context, HousesList(userRole: userRole))),
        MenuItem(Icons.category_outlined, 'List of House Types',
            () => _navigateTo(context, HouseTypesList())),
        MenuItem(Icons.people_alt_outlined, 'List of Users',
            () => _navigateTo(context, UsersListScreen())),
        MenuItem(Icons.analytics_outlined, 'Reports',
            () => _navigateTo(context, ReportScreen(isAdmin: isAdmin))),
      ],
    );
  }

  List<Widget> _buildLandlordMenuItems(BuildContext context) {
    return _buildMenuItems(
      context,
      [
        MenuItem(Icons.dashboard_outlined, 'Dashboard',
            () => _navigateTo(context, HomeScreen(userRole: userRole))),
        MenuItem(Icons.home_outlined, 'My Houses',
            () => _navigateTo(context, HousesList(userRole: userRole))),
        MenuItem(Icons.people_outline, 'My Tenants',
            () => _navigateTo(context, MyTenants())),
        MenuItem(Icons.analytics_outlined, 'Reports',
            () => _navigateTo(context, ReportScreen(isAdmin: isAdmin))),
      ],
    );
  }

  List<Widget> _buildTenantMenuItems(BuildContext context) {
    return _buildMenuItems(
      context,
      [
        MenuItem(
            Icons.home, 'My Rental', () => _navigateTo(context, MyRental())),
      ],
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, List<MenuItem> items) {
    return items.map((item) => _buildMenuItem(context, item)).toList();
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return ListTile(
      leading: Icon(item.icon, color: Theme.of(context).primaryColor),
      title: Text(item.title, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        item.onTap();
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.exit_to_app, color: Colors.red),
      title: Text('Logout',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
      onTap: () async {
        try {
          await _firebaseService.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to log out. Please try again.')),
          );
        }
      },
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  MenuItem(this.icon, this.title, this.onTap);
}
