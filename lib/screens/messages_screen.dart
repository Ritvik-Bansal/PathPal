import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pathpal/screens/chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser?.uid)
            .where('deleted_${currentUser?.uid}', isEqualTo: false)
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
            final aUnread = (aData['unreadCount_${currentUser?.uid}'] ?? 0) > 0;
            final bUnread = (bData['unreadCount_${currentUser?.uid}'] ?? 0) > 0;

            if (aUnread != bUnread) {
              return aUnread ? -1 : 1;
            } else {
              final aTimestamp = aData['lastMessageTimestamp'] as Timestamp?;
              final bTimestamp = bData['lastMessageTimestamp'] as Timestamp?;
              if (aTimestamp == null || bTimestamp == null) return 0;
              return bTimestamp.compareTo(aTimestamp);
            }
          });

          return ListView.separated(
            itemCount: chatsWithMessages.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
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
                  final otherUserName = otherUserData['name'] ?? 'Unknown';
                  final profilePicture = otherUserData['profile_picture'];
                  final hasUnread =
                      (chatData['unreadCount_${currentUser?.uid}'] ?? 0) > 0;
                  final lastMessageTime =
                      chatData['lastMessageTimestamp'] as Timestamp?;

                  return Dismissible(
                    key: Key(chat.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm"),
                            content: const Text(
                                "Are you sure you want to delete this chat?"),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("CANCEL"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("DELETE"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chat.id)
                          .update({'deleted_${currentUser?.uid}': true});
                    },
                    background: Container(
                      color: Colors.red,
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 20.0),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    child: Container(
                      color: hasUnread
                          ? const Color.fromARGB(255, 180, 221, 255)
                              .withOpacity(0.3)
                          : null,
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage: profilePicture != null
                                  ? NetworkImage(profilePicture)
                                  : null,
                              child: profilePicture == null
                                  ? Text(otherUserName[0].toUpperCase())
                                  : null,
                            ),
                            if (hasUnread)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          otherUserName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                hasUnread ? FontWeight.bold : FontWeight.normal,
                            color:
                                hasUnread ? theme.colorScheme.onSurface : null,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
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
                            ),
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
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
