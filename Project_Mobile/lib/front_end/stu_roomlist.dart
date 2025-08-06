import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:room_reservation/front_end/navigation_student.dart';
import 'package:room_reservation/front_end/splash.dart';
import 'package:room_reservation/front_end/stu_check.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StuRoomlist extends StatefulWidget {
  const StuRoomlist({super.key});

  @override
  State<StuRoomlist> createState() => _StuRoomlistState();
}

class _StuRoomlistState extends State<StuRoomlist> {
  int _currentIndex = 0;

  List<Map<String, dynamic>> rooms = [];

  // Fetch room data from API
  Future<void> fetchRooms() async {
    final response =
        await http.get(Uri.parse('http://172.25.212.53:3000/roomlist/student'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        rooms = data.map((room) => room as Map<String, dynamic>).toList();
      });
    } else {
      // Handle error
      print('Failed to load rooms');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  final List<String> objectives = [
    '-',
    'Meeting',
    'Studying',
    'Doing Project',
  ];

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

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  void _showBookingDialog(Map<String, dynamic> room) async {
    String? selectedTimeSlot;
    String? selectedObjective;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Color(0xFF052659),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Divider(
                color: Color(0xFF5483B3),
                thickness: 1,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Room: ${room['room']}',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF042145),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Time:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF042145),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedTimeSlot,
                      hint: Text('Select'),
                      onChanged: (value) {
                        setState(() {
                          selectedTimeSlot = value;
                        });
                      },
                      items: room.keys
                          .where(
                              (key) => key.startsWith('slot') && room[key] == 1)
                          .map((slotKey) {
                        String timeSlotText = '';
                        if (slotKey == 'slot1') timeSlotText = '8:00 - 10:00';
                        if (slotKey == 'slot3') timeSlotText = '13:00 - 15:00';
                        if (slotKey == 'slot2') timeSlotText = '10:00 - 12:00';
                        if (slotKey == 'slot4') timeSlotText = '15:00 - 17:00';
                        return DropdownMenuItem(
                          value:
                              timeSlotText, // Use the time string here instead of the slot key
                          child: Text(timeSlotText),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Objective:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF042145),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedObjective,
                      hint: Text('Select'),
                      onChanged: (value) {
                        setState(() {
                          selectedObjective = value;
                        });
                      },
                      items: objectives.map((objective) {
                        return DropdownMenuItem(
                          value: objective,
                          child: Text(objective),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF5483B3),
                ),
                onPressed: () async {
                  if (selectedTimeSlot != null && selectedObjective != null) {
                    String? userId = await getUserId();
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User not logged in!')),
                      );
                      return;
                    }

                    final response = await http.post(
                      Uri.parse('http://172.25.212.53:3000/booking'),
                      headers: <String, String>{
                        'Content-Type': 'application/json',
                      },
                      body: json.encode({
                        'user_id': userId,
                        'room_id': room['room_id'],
                        'time': selectedTimeSlot,
                        'objective': selectedObjective,
                      }),
                    );

                    if (response.statusCode == 200) {
                      // Booking successful
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => StuCheck()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response.body)),
                      );
                    }
                  }
                },
                child: Text('Book Now'),
              ),
            ),
          ],
        );
      },
    );
  }

  String getSlotStatus(int status) {
    switch (status) {
      case 0:
        return 'Close';
      case 1:
        return 'Free';
      case 2:
        return 'Pending';
      case 3:
        return 'Reserved';
      default:
        return '';
    }
  }

  Color getSlotColor(int status) {
    switch (status) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.green;
      case 2:
        return Colors.amber;
      case 3:
        return Color(0xFF5483B3);
      default:
        return Colors.black;
    }
  }

  bool hasFreeSlot(Map<String, dynamic> room) {
    return room['slot1'] == 1 ||
        room['slot2'] == 1 ||
        room['slot3'] == 1 ||
        room['slot4'] == 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFC1E8FF),
      appBar: AppBar(
        title: const Text(
          'Room List',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            children: rooms.map((room) {
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: room['image'] != null &&
                                    room['image'].startsWith('uploads/')
                                ? Image.network(
                                    'http://172.25.212.53:3000/${room['image']}', // Use the full URL based on your backend
                                    fit: BoxFit.cover,
                                    height: 100,
                                  )
                                : Image.asset(
                                    room['image'] ??
                                        'assets/images/room101.jpg',
                                    fit: BoxFit.cover,
                                    height: 100,
                                  ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room: ${room['room']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF042145),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Description:',
                                  style: TextStyle(
                                      color: Color(0xFF042145),
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  room['description'],
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '8:00 - 10:00  ',
                            style: TextStyle(
                              color: Color(0xFF042145),
                            ),
                          ),
                          Text(
                            getSlotStatus(room['slot1']),
                            style:
                                TextStyle(color: getSlotColor(room['slot1'])),
                          ),
                          Spacer(),
                          Text(
                            '13:00 - 15:00  ',
                            style: TextStyle(
                              color: Color(0xFF042145),
                            ),
                          ),
                          Text(
                            getSlotStatus(room['slot3']),
                            style:
                                TextStyle(color: getSlotColor(room['slot3'])),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            '10:00 - 12:00  ',
                            style: TextStyle(
                              color: Color(0xFF042145),
                            ),
                          ),
                          Text(
                            getSlotStatus(room['slot2']),
                            style:
                                TextStyle(color: getSlotColor(room['slot2'])),
                          ),
                          Spacer(),
                          Text(
                            '15:00 - 17:00  ',
                            style: TextStyle(
                              color: Color(0xFF042145),
                            ),
                          ),
                          Text(
                            getSlotStatus(room['slot4']),
                            style:
                                TextStyle(color: getSlotColor(room['slot4'])),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFF052659),
                          ),
                          onPressed: hasFreeSlot(room)
                              ? () => _showBookingDialog(room)
                              : null,
                          child: Text('Booking'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      bottomNavigationBar: NavigationStudent(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
