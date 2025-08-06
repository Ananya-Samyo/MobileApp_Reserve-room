import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:room_reservation/front_end/navigation_student.dart';
import 'package:room_reservation/front_end/splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StuCheck extends StatefulWidget {
  const StuCheck({super.key});

  @override
  State<StuCheck> createState() => _StuCheckState();
}

class _StuCheckState extends State<StuCheck> {
  int _currentIndex = 1;
  Map<String, String>? booking;
  bool isLoading = true;

  // Fetch user id from SharedPreferences and load booking data
  Future<void> fetchBookingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId != null) {
      final response = await http.get(
        Uri.parse('http://172.25.212.53:3000/check?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data == null || data.isEmpty) {
          setState(() {
            booking = null;
            isLoading = false;
          });
        } else {
          setState(() {
            booking = {
              "user_id": userId,
              "room_number": data[0]['room_number'],
              "time": data[0]['time'],
              "objective": data[0]['objective'],
              "approved_name": data[0]['approve_name'],
              "approve_status": data[0]['booking_status'].toString(),
            };
            isLoading = false;
          });
        }
      } else {
        // Handle the error if response is not 200
        print("Error: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
        // You can display a message here if needed
      }
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
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
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
  void initState() {
    super.initState();
    fetchBookingData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFC1E8FF),
      appBar: AppBar(
        backgroundColor: Color(0xFFC1E8FF),
        title: const Text(
          'Check Status',
          style: TextStyle(
            color: Color(0xFF052659),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        automaticallyImplyLeading: false,
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
        child: isLoading
            ? Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : booking == null
                ? Center(child: Text('You do not have any bookings for today.'))
                : ListView(
                    children: [
                      RequestCard(bookingData: booking!),
                      SizedBox(height: 20),
                      Image.asset(
                        'assets/images/check_status.png',
                        height: 200,
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: NavigationStudent(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final Map<String, String> bookingData;

  const RequestCard({required this.bookingData});

  @override
  Widget build(BuildContext context) {
    TextStyle labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF042145),
    );

    // Get approve_status and set color accordingly
    String approveStatus = bookingData['approve_status'] ?? '1';
    Color statusColor = _getStatusColor(approveStatus);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildRow('Student ID:', bookingData['user_id'] ?? ''),
            SizedBox(height: 8),
            buildRow('Room:', bookingData['room_number'] ?? ''),
            SizedBox(height: 8),
            buildRow('Time:', bookingData['time'] ?? ''),
            SizedBox(height: 8),
            buildRow('Objective:', bookingData['objective'] ?? ''),
            SizedBox(height: 8),
            buildRow('Approve:', bookingData['approved_name'] ?? ''),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Status:', style: labelStyle),
                SizedBox(width: 8),
                Text(
                  _getStatusText(approveStatus),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(String label, String value) {
    TextStyle labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF042145),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  // Determine the color based on approval status
  Color _getStatusColor(String status) {
    switch (status) {
      case '2': // Approved
        return Colors.green;
      case '3': // Disapproved
        return Colors.red;
      case '1': // Pending
      default:
        return Colors.amber;
    }
  }

  // Get the status text based on approval status
  String _getStatusText(String status) {
    switch (status) {
      case '2': // Approved
        return 'Approved';
      case '3': // Disapproved
        return 'Disapproved';
      case '1': // Pending
      default:
        return 'Pending';
    }
  }
}
