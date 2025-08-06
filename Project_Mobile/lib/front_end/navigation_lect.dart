import 'package:flutter/material.dart';
import 'package:room_reservation/front_end/lect_dashboard.dart';
import 'package:room_reservation/front_end/lect_history.dart';
import 'package:room_reservation/front_end/lect_request.dart';
import 'package:room_reservation/front_end/lect_roomlist.dart';

class NavigationLect extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigationLect({
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
              MaterialPageRoute(builder: (context) => LectRoomlist()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LectDashboard()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LectRequest()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LectHistory()),
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
          icon: Icon(Icons.list),
          label: 'Booking Request',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.update),
          label: 'History',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
    );
  }
}
