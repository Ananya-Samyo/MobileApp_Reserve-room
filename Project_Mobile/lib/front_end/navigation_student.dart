import 'package:flutter/material.dart';
import 'package:room_reservation/front_end/stu_check.dart';
import 'package:room_reservation/front_end/stu_history.dart';
import 'package:room_reservation/front_end/stu_roomlist.dart';

class NavigationStudent extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigationStudent({
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
        // Handle navigation based on the tapped index
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StuRoomlist()),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StuCheck()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StuHistory()),
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
          icon: Icon(Icons.check_box),
          label: 'Check Status',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.update),
          label: 'History',
        ),
      ],
    );
  }
}
