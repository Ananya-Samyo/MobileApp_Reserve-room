import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:room_reservation/front_end/navigation_student.dart';
import 'package:room_reservation/front_end/splash.dart';

class StuHistory extends StatefulWidget {
  const StuHistory({super.key});

  @override
  State<StuHistory> createState() => _StuHistoryState();
}

class _StuHistoryState extends State<StuHistory> {
  int _currentIndex = 2;

  String? _selectedMonth;
  String? _selectedYear;

  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _filteredReservations = [];

  final List<String> _months = [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12'
  ];
  final List<String> _years = ['2022', '2023', '2024'];

  @override
  void initState() {
    super.initState();
    fetchReservationHistory();
  }

  Future<void> fetchReservationHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId != null) {
      final response = await http.get(
        Uri.parse('http://172.25.212.53:3000/student/history?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _reservations = data.map((reservation) {
            return {
              'room': reservation['room_number'],
              'date': reservation['date'],
              'time': reservation['time'],
              'isApproved': reservation['booking_status'] == 2,
              'approver': reservation['approve_name'],
              'imagePath': reservation['image'],
            };
          }).toList();
          _filteredReservations = _reservations;
        });
      } else {
        print('Failed to load reservations');
      }
    }
  }

  void _filterReservations() {
    setState(() {
      _filteredReservations = _reservations.where((reservation) {
        if (_selectedMonth == null && _selectedYear == null) {
          // Show all reservations if no month or year is selected
          return true;
        }

        final reservationDate = reservation['date'];
        final monthMatch = _selectedMonth == null ||
            reservationDate.substring(5, 7) == _selectedMonth;
        final yearMatch = _selectedYear == null ||
            reservationDate.substring(0, 4) == _selectedYear;

        return monthMatch && yearMatch;
      }).toList();
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFC1E8FF),
      appBar: AppBar(
        title: const Text(
          'History',
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
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String>(
                hint: Text("Select Year"),
                value: _selectedYear,
                items: _years.map((String year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                    _filterReservations();
                  });
                },
              ),
              SizedBox(width: 16),
              DropdownButton<String>(
                hint: Text("Select Month"),
                value: _selectedMonth,
                items: _months.map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: _selectedYear != null
                    ? (value) {
                        setState(() {
                          _selectedMonth = value;
                          _filterReservations();
                        });
                      }
                    : null,
              ),
            ],
          ),
          Expanded(
            child: _filteredReservations.isEmpty
                ? Center(
                    child: Text(
                      'No reservations found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.all(8.0),
                    children: _filteredReservations.map((reservation) {
                      return buildRoomCard(
                        reservation['room'],
                        reservation['date'],
                        reservation['time'],
                        reservation['isApproved'],
                        reservation['approver'],
                        reservation['imagePath'],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationStudent(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

Widget buildRoomCard(String room, String date, String time, bool isApproved,
    String approver, String imagePath) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(imagePath,
            height: 120, width: double.infinity, fit: BoxFit.cover),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Room $room',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF042145),
                    ),
                  ),
                  Text(isApproved ? 'Approved' : 'Disapproved',
                      style: TextStyle(
                          color: isApproved ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(Icons.people, size: 16),
                  SizedBox(width: 4),
                  SizedBox(width: 16),
                  Icon(Icons.wifi, size: 16),
                  SizedBox(width: 16),
                  Icon(Icons.videocam, size: 16),
                ],
              ),
              SizedBox(height: 8.0),
              Text('Date: $date'),
              Text('Time: $time'),
              Text('Approver: $approver'),
            ],
          ),
        ),
      ],
    ),
  );
}
