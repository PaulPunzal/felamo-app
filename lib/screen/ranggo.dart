import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:felamo/baseurl/baseurl.dart';
import 'package:felamo/services/error_helper.dart';

class TalaNgRanggoScreen extends StatefulWidget {
  final String sessionId;
  const TalaNgRanggoScreen({super.key, required this.sessionId});

  @override
  State<TalaNgRanggoScreen> createState() => _TalaNgRanggoScreenState();
}

class _TalaNgRanggoScreenState extends State<TalaNgRanggoScreen> {
  List<RankingItem> rankings = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = false;
  int? myRank;

  static const int firstPageSize = 13; // podium (3) + 10 rows
  static const int nextPageSize = 10;

  List<RankingItem> get topThree => rankings.take(3).toList();
  List<RankingItem> get otherRankings => rankings.skip(3).toList();

  @override
  void initState() {
    super.initState();
    fetchLeaderBoard();
  }

  Future<void> fetchLeaderBoard({bool loadMore = false}) async {
    if (loadMore) {
      if (isLoadingMore) return;
      setState(() => isLoadingMore = true);
    }

    final url = Uri.parse('${baseUrl}get-overall-leader-boards.php');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'session_id': widget.sessionId,
              'limit': loadMore ? nextPageSize : firstPageSize,
              'offset': loadMore ? rankings.length : 0,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final newItems = (data['data'] as List).map((item) {
          final pts = int.tryParse(item['total_points'].toString()) ?? 0;
          return RankingItem(
            id: int.tryParse(item['id'].toString()) ?? 0,
            name: item['first_name'] ?? '',
            points: "$pts Puntos",
            rawPoints: pts,
            rank: int.tryParse(item['rank'].toString()) ?? 0,
          );
        }).toList();

        if (!mounted) return;
        setState(() {
          if (loadMore) {
            rankings.addAll(newItems);
          } else {
            rankings = newItems;
          }
          hasMore = data['has_more'] == true;
          myRank = int.tryParse(data['my_rank'].toString());
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        throw Exception(data['message'] ?? 'failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      ErrorHelper.showSnack(context, ErrorHelper.fromException(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF330006),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tala ng Ranggo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Podium
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildPodiumCard(topThree.length > 1 ? topThree[1] : null, 2),
                          _buildPodiumCard(topThree.isNotEmpty ? topThree[0] : null, 1),
                          _buildPodiumCard(topThree.length > 2 ? topThree[2] : null, 3),
                        ],
                      ),
                    ),
                    
                    // List Container
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFE9DFC7),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Ranggo ng mga Mag-aaral',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: otherRankings.length + (hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == otherRankings.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: isLoadingMore
                                            ? const CircularProgressIndicator(color: Color(0xFF4e0506))
                                            : OutlinedButton.icon(
                                                onPressed: () => fetchLeaderBoard(loadMore: true),
                                                icon: const Icon(Icons.expand_more, color: Color(0xFF4e0506)),
                                                label: const Text('Magpakita pa',
                                                    style: TextStyle(color: Color(0xFF4e0506))),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFF4e0506)),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20)),
                                                ),
                                              ),
                                      ),
                                    );
                                  }
                                  return _buildRankingListItem(otherRankings[index]);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Bottom Info Bar
                    Container(
                      color: const Color(0xFF330006),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                myRank != null ? 'Iyong Ranggo: #$myRank' : 'Iyong Ranggo: --',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Patuloy sa pagkatuto upang umaangat pa.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPodiumCard(RankingItem? item, int position) {
    IconData medalIcon;
    Color medalColor;
    const double cardHeight = 130; // Uniform height for all positions

    switch (position) {
      case 1:
        medalIcon = Icons.emoji_events;
        medalColor = Colors.amber;
        break;
      case 2:
        medalIcon = Icons.military_tech;
        medalColor = Colors.grey;
        break;
      case 3:
        medalIcon = Icons.workspace_premium;
        medalColor = Colors.brown;
        break;
      default:
        medalIcon = Icons.emoji_events;
        medalColor = Colors.amber;
    }

    return SizedBox(
      width: 85,
      child: Column(
        mainAxisSize: MainAxisSize.min, // <--- ADD THIS LINE HERE
        children: [
          Container(
            width: 85,
            constraints: const BoxConstraints(minHeight: cardHeight - 35),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: item == null
                ? const Center(child: Text("-", style: TextStyle(fontSize: 18, color: Colors.grey)))
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(medalIcon, color: medalColor, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.points,
                          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: medalColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingListItem(RankingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4e0506),
            radius: 20,
            child: Text(
              '${item.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.points,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.star, color: Color(0xFF4e0506), size: 24),
        ],
      ),
    );
  }
}

class RankingItem {
  final int id;
  final String name;
  final String points;
  final int rawPoints;
  final int rank;

  RankingItem({
    required this.id,
    required this.name,
    required this.points,
    required this.rawPoints,
    required this.rank,
  });

  RankingItem copyWith({int? id, String? name, String? points, int? rawPoints, int? rank}) {
    return RankingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      rawPoints: rawPoints ?? this.rawPoints,
      rank: rank ?? this.rank,
    );
  }
}