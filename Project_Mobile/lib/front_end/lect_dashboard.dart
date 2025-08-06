import 'package:flutter/material.dart';
import 'package:room_reservation/front_end/navigation_lect.dart';
import 'package:room_reservation/front_end/splash.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LectDashboard extends StatefulWidget {
  const LectDashboard({super.key});

  @override
  State<LectDashboard> createState() => _LectDashboardState();
}

class _LectDashboardState extends State<LectDashboard> {
  int _currentIndex = 1;

  int freeSlots = 0;
  int pendingSlots = 0;
  int reservedSlots = 0;
  int disabledSlots = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    const url = 'http://172.25.212.53:3000/lecturer/dashboard';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          freeSlots = int.tryParse(data['free_slots'].toString()) ?? 0;
          pendingSlots = int.tryParse(data['pending_slots'].toString()) ?? 0;
          reservedSlots = int.tryParse(data['reserved_slots'].toString()) ?? 0;
          disabledSlots = int.tryParse(data['disabled_slots'].toString()) ?? 0;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.red,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  color: Color(0xFF052659),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Splash()),
                );
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF5483B3),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFC1E8FF),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF052659),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFC1E8FF),
        actions: [
          TextButton.icon(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFF5483B3),
            ),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFF5483B3),
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            DashboardCard(
              iconColor: Colors.green,
              color: Color(0xFF40EC85),
              icon: Icons.meeting_room,
              title: 'Free Slot',
              count: freeSlots.toString(),
            ),
            SizedBox(height: 16),
            DashboardCard(
              iconColor: Colors.amber,
              color: Color(0xFFFAE384),
              icon: Icons.pending_actions,
              title: 'Pending Slot',
              count: pendingSlots.toString(),
            ),
            SizedBox(height: 16),
            DashboardCard(
              iconColor: Colors.blue,
              color: Color(0xFF84CDFA),
              icon: Icons.check_box,
              title: 'Reserved Slot',
              count: reservedSlots.toString(),
            ),
            SizedBox(height: 16),
            DashboardCard(
              iconColor: Colors.red,
              color: Color(0xFFFA8484),
              icon: Icons.build,
              title: 'Disabled Slot',
              count: disabledSlots.toString(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationLect(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final Color iconColor;
  final Color color;
  final IconData icon;
  final String title;
  final String count;

  const DashboardCard({
    required this.iconColor,
    required this.color,
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                icon,
                size: 35,
                color: iconColor,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Color(0xFF042145),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    count,
                    style: TextStyle(
                      color: Color(0xFF052659),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
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
}
