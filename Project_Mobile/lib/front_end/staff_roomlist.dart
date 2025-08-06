import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:room_reservation/front_end/navigation_staff.dart';
import 'package:room_reservation/front_end/splash.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';

class StaffRoomlist extends StatefulWidget {
  const StaffRoomlist({super.key});

  @override
  State<StaffRoomlist> createState() => _StaffRoomlistState();
}

class _StaffRoomlistState extends State<StaffRoomlist> {
  int _currentIndex = 0;

  String? selectedTimeSlot;

  List<Map<String, dynamic>> rooms = [];

  Future<void> fetchRooms() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.25.212.53:3000/roomlist/staff'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          rooms = data.map((room) => room as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception('Failed to fetch rooms.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  void _showAddRoomDialog() {
    final TextEditingController roomNumberController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    String? selectedImagePath;
    String? selectedFileName;

    final ImagePicker _picker = ImagePicker();

    Future<void> _pickImage() async {
      try {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          if (mounted) {
            setState(() {
              selectedImagePath = image.path;
              selectedFileName = path.basename(image.path);
            });
          }
        }
      } catch (e) {
        print("Error picking image: $e");
      }
    }

    Future<void> _saveRoom() async {
      if (roomNumberController.text.isEmpty ||
          descriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Room number and description are required'),
        ));
        return;
      }

      var uri = Uri.parse('http://172.25.212.53:3000/addroom');
      var request = http.MultipartRequest('POST', uri);

      request.fields['room_number'] = roomNumberController.text;
      request.fields['description'] = descriptionController.text;

      if (selectedImagePath != null) {
        var imageFile = File(selectedImagePath!);
        var imageBytes = await imageFile.readAsBytes();
        var imageMultipart = http.MultipartFile.fromBytes(
          'image', // This should match the field name in the backend (multer)
          imageBytes,
          filename: selectedFileName,
          contentType: MediaType(
              'image',
              selectedFileName!
                  .split('.')
                  .last), // Dynamic MIME type based on file extension
        );
        request.files.add(imageMultipart);
      }

      try {
        var response = await request.send();

        if (response.statusCode == 201) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Room added successfully!'),
          ));
          fetchRooms();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to add room'),
          ));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
        ));
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Add Room',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    color: Color(0xFF052659)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: roomNumberController,
                      decoration: InputDecoration(
                        labelText: 'Room Number',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add_photo_alternate,
                              color: Color(0xFF042145)),
                          onPressed: () async {
                            await _pickImage();
                            setState(() {});
                          },
                        ),
                        Text(
                          selectedFileName ?? 'Add Image',
                          style: TextStyle(color: Color(0xFF052659)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF5483B3)),
                  onPressed: _saveRoom,
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> room) {
    final TextEditingController descriptionController =
        TextEditingController(text: room['description']);

    String? selectedImagePath = room['image']; // Start with current image path
    String? selectedFileName; // Holds the new image file name if selected

    final ImagePicker _picker = ImagePicker();

    Future<void> _pickImage() async {
      try {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            selectedImagePath = image.path; // Update to new image path
            selectedFileName =
                path.basename(image.path); // Extract the file name
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image selected: $selectedFileName')),
          );
        }
      } catch (e) {
        print("Error picking image: $e");
      }
    }

    Future<void> _saveChanges() async {
      final String apiUrl =
          'http://172.25.212.53:3000/edit'; // Replace with your backend URL

      try {
        var request = http.MultipartRequest('PUT', Uri.parse(apiUrl));

        // Add fields (description)
        request.fields['room_id'] = room['room_id'].toString();
        request.fields['description'] = descriptionController.text;

        // Only add the image if it has been selected or changed
        if (selectedImagePath != null && selectedImagePath != room['image']) {
          var imageFile =
              await http.MultipartFile.fromPath('image', selectedImagePath!);
          request.files.add(imageFile);
        }

        // Send the request
        var response = await request.send();

        if (response.statusCode == 200) {
          setState(() {
            room['description'] = descriptionController.text;
            if (selectedImagePath != null) {
              room['image'] =
                  selectedImagePath; // Update the image path locally
            }
          });
          Navigator.of(context).pop(); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Room details updated successfully.')),
          );
          fetchRooms();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update room details.')),
          );
        }
      } catch (e) {
        print("Error updating room: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An error occurred while updating room details.')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Room Detail',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: Color(0xFF052659),
                ),
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
              const SizedBox(height: 18),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_photo_alternate,
                      color: Color(0xFF042145),
                    ),
                    onPressed: _pickImage,
                  ),
                  Text(
                    selectedFileName ?? 'Change Image',
                    style: TextStyle(
                      color: Color(0xFF052659),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF5483B3),
              ),
              onPressed: _saveChanges, // Call the save changes method
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> disableSlot(int roomId, String selectedTimeSlot) async {
    final url = Uri.parse('http://172.25.212.53:3000/disable');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_id': roomId,
          'selectedTimeSlot': selectedTimeSlot,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(responseData['message']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']);
      }
    } catch (e) {
      print('Failed to disable slot: $e');
      throw Exception('Failed to disable slot');
    }
  }

  void _showDisableDialog(String roomNumber, Map<String, dynamic> room) {
    List<String> availableSlots = [];
    if (room['slot1'] == 1) availableSlots.add('8:00 - 10:00');
    if (room['slot2'] == 1) availableSlots.add('10:00 - 12:00');
    if (room['slot3'] == 1) availableSlots.add('13:00 - 15:00');
    if (room['slot4'] == 1) availableSlots.add('15:00 - 17:00');

    String? selectedTimeSlot;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Disable',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: Color(0xFF052659),
                ),
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
                'Room: $roomNumber',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF042145),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                hint: const Text("Select Time Slot"),
                items: availableSlots.map((slot) {
                  return DropdownMenuItem(
                    value: slot,
                    child: Text(slot),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedTimeSlot = value;
                },
                value: selectedTimeSlot,
                isExpanded: true,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF5483B3),
              ),
              onPressed: () async {
                if (selectedTimeSlot != null) {
                  // Send data to backend
                  await disableSlot(room['room_id'], selectedTimeSlot!);

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Room $roomNumber Time "$selectedTimeSlot" disabled successfully!'),
                    ),
                  );
                  fetchRooms();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: hasFreeSlot(room)
                                ? () => _showDisableDialog(room['room'], room)
                                : null,
                            child: const Text('Disable'),
                          ),
                          const SizedBox(width: 30),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xFF5483B3),
                            ),
                            onPressed: () {
                              _showEditDialog(room);
                            },
                            child: Text('Edit'),
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
      // add button
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            onPressed: _showAddRoomDialog,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.add,
              color: Color(0xFF042145),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationStaff(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
