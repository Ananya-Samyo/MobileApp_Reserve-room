import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:room_reservation/front_end/navigation_lect.dart';
import 'package:room_reservation/front_end/splash.dart';

class LectHistory extends StatefulWidget {
  const LectHistory({super.key});

  @override
  State<LectHistory> createState() => _LectHistoryState();
}

class _LectHistoryState extends State<LectHistory> {
  int _currentIndex = 3;

  String? _selectedMonth;
  String? _selectedYear;

  List<Map<String, dynamic>> _reservations = [];

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
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    final response = await http.get(
      Uri.parse('http://172.25.212.53:3000/lecturer/history?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _reservations =
            List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      print('Error fetching reservations: ${response.statusCode}');
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
                hint: const Text("Select Year"),
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
                    _selectedMonth = null;
                  });
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                hint: const Text("Select Month"),
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
                        });
                      }
                    : null,
              ),
            ],
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                // Apply filtering to _reservations
                final filteredReservations = _reservations.where((reservation) {
                  final reservationDate = reservation['date'];
                  final monthMatch = _selectedMonth == null ||
                      reservationDate.substring(5, 7) == _selectedMonth;
                  final yearMatch = _selectedYear == null ||
                      reservationDate.substring(0, 4) == _selectedYear;

                  return monthMatch && yearMatch;
                }).toList();

                // Display message if there are no filtered results
                if (filteredReservations.isEmpty) {
                  return const Center(
                    child: Text(
                      'No reservations found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                // Otherwise, display the filtered list of reservations
                return ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: filteredReservations.map((reservation) {
                    return buildRoomCard(
                      reservation['room_number'],
                      'Reserved ID: ${reservation['user_id']}',
                      reservation['date'],
                      reservation['time'],
                      reservation['booking_status'],
                      reservation['image'],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationLect(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

Widget buildRoomCard(String room, String reservationId, String date,
    String time, int bookingStatus, String imagePath) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          imagePath,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
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
                  Text(
                    bookingStatus == 2 ? 'Approved' : 'Disapproved',
                    style: TextStyle(
                      color: bookingStatus == 2 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Text(reservationId),
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
            ],
          ),
        ),
      ],
    ),
  );
}
