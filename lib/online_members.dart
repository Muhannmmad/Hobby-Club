import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineMembersRow extends StatefulWidget {
  final void Function(String receiverId, String receiverFullName)
      showPrivateChatScreen;

  const OnlineMembersRow({Key? key, required this.showPrivateChatScreen})
      : super(key: key);

  @override
  _OnlineMembersRowState createState() => _OnlineMembersRowState();
}

class _OnlineMembersRowState extends State<OnlineMembersRow> {
  final ScrollController _scrollController = ScrollController();
  bool _scrollForward = true;

  @override
  void initState() {
    super.initState();
    // Delay starting the auto-scroll to ensure the ListView is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3)); // Pause before moving

      if (!_scrollController.hasClients) continue; // Ensure ListView exists

      double maxScroll = _scrollController.position.maxScrollExtent;
      double targetScroll = _scrollForward ? maxScroll : 0;

      await _scrollController.animateTo(
        targetScroll,
        duration: const Duration(seconds: 5),
        curve: Curves.linear,
      );

      _scrollForward = !_scrollForward; // Toggle direction
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildOnlineMembersRow() {
    return Container(
      color: Colors.black.withOpacity(0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
          ),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('isOnline', isEqualTo: true)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox(
                    height: 100,
                    child: Center(child: Text("No online members")));
              }
              return SizedBox(
                height: 70,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var user = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    String profileImage = user['profileImage'] ?? '';
                    String name = "${user['firstName'] ?? 'Unknown'}";
                    String userId = snapshot.data!.docs[index].id;

                    return GestureDetector(
                      onTap: () {
                        widget.showPrivateChatScreen(userId, name);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.transparent,
                              backgroundImage: profileImage.isNotEmpty
                                  ? NetworkImage(profileImage)
                                  : null,
                              child: profileImage.isEmpty
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            Container(
                              width: 70,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildOnlineMembersRow();
  }
}
