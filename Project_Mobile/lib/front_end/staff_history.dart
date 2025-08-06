import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:room_reservation/front_end/navigation_staff.dart';
import 'package:room_reservation/front_end/splash.dart';

class StaffHistory extends StatefulWidget {
  const StaffHistory({super.key});

  @override
  State<StaffHistory> createState() => _StaffHistoryState();
}

class _StaffHistoryState extends State<StaffHistory> {
  int _currentIndex = 2;
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
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    try {
      final response = await http
          .get(Uri.parse('http://172.25.212.53:3000/staff/history'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _reservations = List<Map<String, dynamic>>.from(data);
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _reservations = [];
        });
      } else {
        throw Exception('Failed to load reservations');
      }
    } catch (e) {
      setState(() {
        _reservations = [];
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load reservations: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
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
          title: const Column(
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
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Splash()),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF5483B3)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1E8FF),
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
        backgroundColor: const Color(0xFFC1E8FF),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Color(0xFF5483B3)),
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

                return ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: filteredReservations.map((reservation) {
                    return buildRoomCard(
                      reservation['room'],
                      reservation['reservationId'],
                      reservation['date'],
                      reservation['time'],
                      reservation['approver'],
                      reservation['isApproved'] ? 'Approved' : 'Disapproved',
                      reservation['imagePath'],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationStaff(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

Widget buildRoomCard(String room, String reservationId, String date,
    String time, String approver, String status, String imagePath) {
  bool isApproved = status == 'Approved';
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    room,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF042145),
                    ),
                  ),
                  Text(
                    isApproved ? 'Approved' : 'Disapproved',
                    style: TextStyle(
                      color: isApproved ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text('Reservation ID: $reservationId'),
              const SizedBox(height: 8.0),
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
