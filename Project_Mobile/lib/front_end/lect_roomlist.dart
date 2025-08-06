import 'package:flutter/material.dart';
import 'package:room_reservation/front_end/navigation_lect.dart';
import 'package:room_reservation/front_end/splash.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LectRoomlist extends StatefulWidget {
  const LectRoomlist({super.key});

  @override
  State<LectRoomlist> createState() => _LectRoomlistState();
}

class _LectRoomlistState extends State<LectRoomlist> {
  int _currentIndex = 0;

  List<dynamic> rooms = [];
  bool isLoading = true;
  final String apiUrl = 'http://172.25.212.53:3000/roomlist/lecturer';

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          rooms = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load rooms');
      }
    } catch (e) {
      print('Error fetching rooms: $e');
      setState(() {
        isLoading = false;
      });
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
                                    'http://172.25.212.53:3000/${room['image']}',
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
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      bottomNavigationBar: NavigationLect(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
