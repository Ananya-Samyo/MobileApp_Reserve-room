import 'package:flutter/material.dart';
import 'package:room_reservation/front_end/navigation_lect.dart';
import 'package:room_reservation/front_end/splash.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LectRequest extends StatefulWidget {
  const LectRequest({super.key});

  @override
  State<LectRequest> createState() => _LectRequestState();
}

class _LectRequestState extends State<LectRequest> {
  int _currentIndex = 2;

  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    const url = 'http://172.25.212.53:3000/request';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          requests = data
              .map((item) => {
                    'book_id': item['book_id'].toString(),
                    'studentID': item['user_id'],
                    'room': item['room_number'],
                    'time': item['time'],
                    'objective': item['objective'],
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to load requests');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _approve(String bookId) async {
    final url = 'http://172.25.212.53:3000/approve';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');

      if (userId == null) {
        print('User ID not found in preferences');
        return;
      }

      // Prepare the POST request with user_id and book_id
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'book_id': bookId,
        }),
      );

      // Handle response
      if (response.statusCode == 200) {
        print('Booking approved successfully');
        _fetchRequests();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking approved successfully!')),
        );
      } else {
        print('Failed to approve booking: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showApproveDialog(String bookId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Icon(
                Icons.check_box,
                color: Colors.greenAccent,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Confirm Approve',
                style: TextStyle(
                  color: Color(0xFF052659),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '  Are you sure you want to approve it?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
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
                _approve(bookId);
              },
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF7DA0CA),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _disapprove(String bookId) async {
    final url = 'http://172.25.212.53:3000/disapprove';

    try {
      // Retrieve user_id from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');

      if (userId == null) {
        print('User ID not found in preferences');
        return;
      }

      // Prepare the POST request with user_id and book_id
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'book_id': bookId,
        }),
      );

      // Handle response
      if (response.statusCode == 200) {
        print('Booking disapproved successfully');
        _fetchRequests();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking disapproved successfully!')),
        );
      } else {
        print('Failed to disapprove booking: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showDisapproveDialog(String bookId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Icon(
                Icons.cancel,
                color: Colors.redAccent,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'Confirm Disapprove',
                style: TextStyle(
                  color: Color(0xFF052659),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '   Are you sure you want to disapprove it?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
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
                _disapprove(bookId);
              },
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF7DA0CA),
              ),
            ),
          ],
        );
      },
    );
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
          'Booking Request',
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
        child: requests.isEmpty
            ? Center(
                child: Text(
                  'No booking requests.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Column(
                    children: [
                      RequestCard(
                        studentID: request['studentID']!,
                        room: request['room']!,
                        time: request['time']!,
                        objective: request['objective']!,
                        onApprove: () => _showApproveDialog(request['book_id']),
                        onDisapprove: () =>
                            _showDisapproveDialog(request['book_id']),
                      ),
                      SizedBox(height: 16),
                    ],
                  );
                },
              ),
      ),
      bottomNavigationBar: NavigationLect(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final String studentID;
  final String room;
  final String time;
  final String objective;
  final VoidCallback onApprove;
  final VoidCallback onDisapprove;

  const RequestCard({
    required this.studentID,
    required this.room,
    required this.time,
    required this.objective,
    required this.onApprove,
    required this.onDisapprove,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Color(0xFF042145),
    );

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Student ID:', style: labelStyle),
                SizedBox(width: 8),
                Text(studentID, style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Room:', style: labelStyle),
                SizedBox(width: 8),
                Text(room, style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Time:', style: labelStyle),
                SizedBox(width: 8),
                Text(time, style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Objective:', style: labelStyle),
                SizedBox(width: 8),
                Text(objective, style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF40EC85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onApprove,
                  child: Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFA8484),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onDisapprove,
                  child: Text(
                    'Disapprove',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
