import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:felamo/baseurl/baseurl.dart';

import 'package:felamo/screen/notifikasyon.dart';
import 'package:felamo/screen/parangal.dart';
import 'package:felamo/screen/ranggo.dart';
import 'package:felamo/screen/settings.dart';
import 'package:felamo/user/profile.dart';
import 'package:flutter/material.dart';

// You can remove this import if you no longer use Dashboard in this file
import 'dashboard.dart'; 

class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  final String firstName;
  final String sessionId;
  final int pointsReceived;
  final int current_streak;
  final int id;
  final int points;
  final String email;
  
  final void Function(int index) onTap;

  const CustomBottomBar({
    Key? key,
    required this.currentIndex,
    required this.firstName,
    required this.sessionId,
    required this.onTap,
    required this.pointsReceived,
    required this.current_streak,
    required this.id,
    required this.points,
    required this.email
  }) : super(key: key);

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  int unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUnreadCount();
  }

  Future<void> fetchUnreadCount() async {
    final url = Uri.parse('${baseUrl}get-unread-count.php');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"session_id": widget.sessionId}),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          setState(() {
            unreadNotifCount = body['count'];
          });
        }
      }
    } catch (e) {
      print("Error fetching unread count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD32F2F), // Lighter red
            Color(0xFFB71C1C), // Darker red
          ],
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
            context: context,
            icon: Icons.grade,
            index: 0,
            isActive: widget.currentIndex == 0,
            targetScreen: TalaNgRanggoScreen(sessionId: widget.sessionId,),
          ),
          _buildBottomNavItem(
            context: context,
            icon: Icons.diamond_outlined,
            index: 1,
            isActive: widget.currentIndex == 1,
            targetScreen: MyWidget(sessionId: widget.sessionId),
          ),
          
          // ---> HOME ICON (Target Screen Removed) <---
          _buildBottomNavItem(
            context: context,
            icon: Icons.home,
            index: 2, 
            isActive: widget.currentIndex == 2,
            // Just the icon and active state, no targetScreen provided!
          ),

          _buildBottomNavItem(
            context: context,
            icon: Icons.notifications,
            index: 3,
            isActive: widget.currentIndex == 3,
            targetScreen: Notifikasyon(sessionid: widget.sessionId),
            isNotification: true, 
          ),
          _buildBottomNavItem(
            context: context,
            icon: Icons.miscellaneous_services,
            index: 4,
            isActive: widget.currentIndex == 4,
            targetScreen: SettingsScreen(
              sessionId: widget.sessionId, 
              firstName: widget.firstName, 
              email: widget.email
            )
          ),
        ],
      ),
    );
  }

  // Notice: targetScreen is now nullable (Widget?)
  Widget _buildBottomNavItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required bool isActive,
    Widget? targetScreen, // Made optional
    bool isNotification = false,
  }) {
    
    Widget itemContainer = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: isActive ? const Color(0xFFB71C1C) : Colors.grey[600],
        size: 24,
      ),
    );

    if (isNotification && unreadNotifCount > 0) {
      itemContainer = Badge(
        label: Text(unreadNotifCount.toString()),
        backgroundColor: Colors.red.shade900,
        child: itemContainer,
      );
    }

    // Disable the tap if it's the active dashboard, OR if there is no targetScreen provided
    bool disableTap = (isActive && index == 2) || targetScreen == null;

    return GestureDetector(
      onTap: disableTap ? null : () async {
        // Safe check before navigating
        if (targetScreen != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
          
          if (isNotification) {
            fetchUnreadCount(); 
          }
        }
      },
      child: itemContainer, 
    );
  }
}