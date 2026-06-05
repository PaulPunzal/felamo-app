import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:felamo/baseurl/baseurl.dart';

class Notifikasyon extends StatefulWidget {
  final String sessionid;

  const Notifikasyon({super.key, required this.sessionid});

  @override
  State<Notifikasyon> createState() => _NotifikasyonState();
}

class _NotifikasyonState extends State<Notifikasyon> {
  List<dynamic> _notifications = [];
  bool isLoading = true;
  String _currentFilter = 'All'; // Can be 'All' or 'Unread'

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // Getter to filter notifications dynamically based on selected tab
  List<dynamic> get filteredNotifications {
    if (_currentFilter == 'Unread') {
      return _notifications.where((n) => n["is_read"] == 0).toList();
    }
    return _notifications;
  }

  Future<void> fetchNotifications() async {
    final url = Uri.parse('${baseUrl}get-student-notification.php');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"session_id": widget.sessionid}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body["status"] == "success" && body["data"] != null) {
          setState(() {
            _notifications = body["data"];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching notifications: $e");
    }
  }

  Future<void> markAsRead(int notificationId) async {
    setState(() {
      final index = _notifications.indexWhere((n) => n["id"].toString() == notificationId.toString());
      if (index != -1) {
        _notifications[index]["is_read"] = 1;
      }
    });

    final url = Uri.parse('${baseUrl}mark-notification-read.php');
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "session_id": widget.sessionid,
          "action": "single", // Tell PHP it's a single read
          "notification_id": notificationId
        }),
      );
    } catch (e) {
      print("Error marking as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    setState(() {
      for (var notif in _notifications) {
        notif["is_read"] = 1;
      }
    });

    final url = Uri.parse('${baseUrl}mark-notification-read.php');
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "session_id": widget.sessionid,
          "action": "all" // Tell PHP to bulk process
        }),
      );
    } catch (e) {
      print("Error marking all as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEF2525), 
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Notipikasyon',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Mark All as Read Button
                  TextButton(
                    onPressed: _notifications.where((n) => n["is_read"] == 0).isEmpty 
                        ? null 
                        : markAllAsRead,
                    child: Text(
                      "Mark all as read",
                      style: GoogleFonts.leagueSpartan(
                        color: _notifications.where((n) => n["is_read"] == 0).isEmpty 
                            ? Colors.white38 
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Filter Tabs (All / Unread)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Unread'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF2525)))
                    : filteredNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  "Walang notipikasyon",
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 18,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredNotifications.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final notif = filteredNotifications[index];
                              
                              String timeString = notif["created_at"];
                              if (!timeString.endsWith("Z")) {
                                timeString += "Z";
                              }
                              final createdAt = DateTime.parse(timeString).toLocal();
                              final timeAgo = timeago.format(createdAt, locale: 'en_short');
                              
                              bool isRead = notif["is_read"] == 1;

                              return GestureDetector(
                                onTap: () {
                                  if (!isRead) {
                                    markAsRead(int.parse(notif["id"].toString()));
                                  }
                                },
                                child: _buildCleanNotificationCard(
                                  title: notif["title"],
                                  message: notif["description"],
                                  timeAgo: timeAgo,
                                  isRead: isRead,
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter Tab UI
  Widget _buildFilterChip(String label) {
    bool isSelected = _currentFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.leagueSpartan(
            color: isSelected ? const Color(0xFFEF2525) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Individual Notification Card UI
  Widget _buildCleanNotificationCard({
    required String title,
    required String message,
    required String timeAgo,
    required bool isRead,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : const Color(0xFFFFD6D6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isRead ? 0.02 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red dot indicator for unread
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRead ? Colors.transparent : const Color(0xFFEF2525),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.leagueSpartan(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 16,
                          color: isRead ? Colors.black87 : Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 12,
                        color: isRead ? Colors.grey.shade500 : const Color(0xFFEF2525),
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14,
                    color: isRead ? Colors.grey.shade600 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}