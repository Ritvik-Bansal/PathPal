import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pathpal/screens/chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Messages'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                final chatsWithMessages = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['lastMessage'] != null;
                }).toList();

                if (chatsWithMessages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                chatsWithMessages.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aUnread =
                      (aData['unreadCount_${currentUser?.uid}'] ?? 0) > 0;
                  final bUnread =
                      (bData['unreadCount_${currentUser?.uid}'] ?? 0) > 0;

                  if (aUnread != bUnread) {
                    return aUnread ? -1 : 1;
                  } else {
                    final aTimestamp =
                        aData['lastMessageTimestamp'] as Timestamp?;
                    final bTimestamp =
                        bData['lastMessageTimestamp'] as Timestamp?;
                    if (aTimestamp == null || bTimestamp == null) return 0;
                    return bTimestamp.compareTo(aTimestamp);
                  }
                });

                return ListView.separated(
                  itemCount: chatsWithMessages.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chat = chatsWithMessages[index];
                    final chatData = chat.data() as Map<String, dynamic>;
                    final participants =
                        List<String>.from(chatData['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                      (id) => id != currentUser?.uid,
                      orElse: () => '',
                    );

                    if (otherUserId.isEmpty) return const SizedBox.shrink();

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const ListTile(title: Text('Loading...'));
                        }

                        final otherUserData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        final otherUserName =
                            otherUserData['name'] ?? 'Unknown';
                        final profilePicture = otherUserData['profile_picture'];

                        if (_searchQuery.isNotEmpty &&
                            !otherUserName
                                .toLowerCase()
                                .contains(_searchQuery) &&
                            !((chatData['lastMessage'] as String?) ?? '')
                                .toLowerCase()
                                .contains(_searchQuery)) {
                          return const SizedBox.shrink();
                        }

                        final hasUnread =
                            (chatData['unreadCount_${currentUser?.uid}'] ?? 0) >
                                0;
                        final lastMessageTime =
                            chatData['lastMessageTimestamp'] as Timestamp?;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profilePicture != null
                                ? NetworkImage(profilePicture)
                                : null,
                            child: profilePicture == null
                                ? Text(otherUserName[0].toUpperCase())
                                : null,
                          ),
                          title: Text(
                            otherUserName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: hasUnread
                                  ? theme.colorScheme.onSurface
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            chatData['lastMessage'] ?? 'No messages yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: hasUnread
                                  ? theme.colorScheme.onSurface
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (lastMessageTime != null)
                                Text(
                                  timeago.format(lastMessageTime.toDate(),
                                      allowFromNow: true),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: hasUnread
                                        ? theme.colorScheme.onSurface
                                        : null,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              if (hasUnread)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${chatData['unreadCount_${currentUser?.uid}'] ?? 0}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chat.id,
                                  otherUserId: otherUserId,
                                  otherUserName: otherUserName,
                                  otherUserProfilePic: profilePicture,
                                ),
                              ),
                            );
                            FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chat.id)
                                .update({'unreadCount_${currentUser?.uid}': 0});
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
