import 'package:flutter/material.dart';
import 'package:room_reservation/front_end/staff_dashboard.dart';
import 'package:room_reservation/front_end/staff_history.dart';
import 'package:room_reservation/front_end/staff_roomlist.dart';

class NavigationStaff extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigationStaff({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Color(0xFF7DA0CA),
      selectedItemColor: Color(0xFF042145),
      unselectedItemColor: Colors.white,
      currentIndex: currentIndex,
      onTap: (index) {
        onTap(index);
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StaffRoomlist()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StaffDashboard()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StaffHistory()),
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Room List',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.update),
          label: 'History',
        ),
      ],
    );
  }
}
