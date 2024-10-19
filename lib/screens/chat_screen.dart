import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfilePic;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfilePic,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isComposing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _messageController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final isComposing = _messageController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
  }

  void _markMessagesAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('chats').doc(widget.chatId).update({
      'unreadCount_${user.uid}': 0,
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      final chatDoc =
          await _firestore.collection('chats').doc(widget.chatId).get();

      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(widget.chatId).set({
          'participants': [user.uid, widget.otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': message,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'unreadCount_${user.uid}': 0,
          'unreadCount_${widget.otherUserId}': 1,
        });
      }

      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
      });

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.otherUserProfilePic != null
                  ? NetworkImage(widget.otherUserProfilePic!)
                  : null,
              child: widget.otherUserProfilePic == null
                  ? Text(widget.otherUserName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: _buildChatHeader());
                  }

                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildChatHeader();
                      }

                      final messageDoc = messages[index];
                      final message = messageDoc.data() as Map<String, dynamic>;
                      final isMe =
                          message['senderId'] == _auth.currentUser?.uid;
                      final timestamp = message['timestamp'] as Timestamp?;
                      final showAvatar = !isMe &&
                          (index == 0 ||
                              messages[index - 1]['senderId'] !=
                                  message['senderId']);
                      final showTimestamp = index == messages.length - 1 ||
                          _shouldShowTimestamp(
                              messages[index + 1]['timestamp'] as Timestamp?,
                              timestamp);

                      return Column(
                        children: [
                          if (showTimestamp && timestamp != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _formatTimestamp(timestamp),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe && showAvatar)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        widget.otherUserProfilePic != null
                                            ? NetworkImage(
                                                widget.otherUserProfilePic!)
                                            : null,
                                    child: widget.otherUserProfilePic == null
                                        ? Text(widget.otherUserName[0]
                                            .toUpperCase())
                                        : null,
                                  )
                                else if (!isMe)
                                  const SizedBox(width: 32),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.6,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? const Color.fromARGB(
                                              255, 180, 221, 255)
                                          : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      message['text'],
                                      style: TextStyle(
                                        color: isMe ? Colors.black : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.3))),
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        onPressed: _isComposing ? _sendMessage : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: widget.otherUserProfilePic != null
                ? NetworkImage(widget.otherUserProfilePic!)
                : null,
            child: widget.otherUserProfilePic == null
                ? Text(widget.otherUserName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24))
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            widget.otherUserName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(
      Timestamp? prevTimestamp, Timestamp? currentTimestamp) {
    if (prevTimestamp == null || currentTimestamp == null) return true;
    final prevDate = prevTimestamp.toDate();
    final currentDate = currentTimestamp.toDate();
    return currentDate.difference(prevDate).inMinutes >= 30;
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final formatter = DateFormat('h:mm a');
    if (now.difference(date).inDays == 0) {
      return 'Today ${formatter.format(date)}';
    } else if (now.difference(date).inDays == 1) {
      return 'Yesterday ${formatter.format(date)}';
    } else {
      return '${DateFormat('MM/dd/yyyy').format(date)} ${formatter.format(date)}';
    }
  }
}
