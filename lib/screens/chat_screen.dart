import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pathpal/services/block_service.dart';
import 'package:pathpal/widgets/forgot_password_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final BlockService _blockService = BlockService();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  bool _isBlocked = false;
  bool _hasBlocked = false;

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
    _scrollController.dispose();
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

  void _showReportConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Report'),
          content: Text(
            'Are you sure you want to report ${widget.otherUserName}? This action cannot be undone.\n\n'
            'You should report users who:\n'
            '• Send inappropriate or offensive content\n'
            '• Engage in harassment or bullying\n'
            '• Violate PathPal\'s terms of service',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitReport();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Report User'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReport() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final previousReport = await _firestore
          .collection('reports')
          .where('reportedBy', isEqualTo: user.uid)
          .where('reportedUser', isEqualTo: widget.otherUserId)
          .get();

      if (previousReport.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already reported this user'),
            ),
          );
        }
        return;
      }

      await _firestore.collection('reports').add({
        'reportedUser': widget.otherUserId,
        'reportedBy': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': widget.otherUserName,
      });

      final totalReports = await _firestore
          .collection('reports')
          .where('reportedUser', isEqualTo: widget.otherUserId)
          .get();

      final emailContent = _buildEmailContent(
        title: 'New User Report',
        introText: 'A user has been reported on PathPal.',
        details: '''
      <strong>Reported User:</strong> ${widget.otherUserName}<br>
      <strong>User ID:</strong> ${widget.otherUserId}<br>
      <strong>Total Reports:</strong> ${totalReports.docs.length}<br>
      <strong>Reported By:</strong> ${user.email}<br>
      <strong>Report Time:</strong> ${DateTime.now()}<br>
    ''',
        callToAction: totalReports.docs.length >= 3
            ? "⚠️ This user has received 3 or more reports and should be reviewed for removal."
            : "Please review this report and take appropriate action.",
      );

      final response = await http.post(
        Uri.parse('https://api.mailjet.com/v3.1/send'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${dotenv.env["MAILAPI"]}'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Messages': [
            {
              'From': {'Email': 'noreply@pathpal.org', 'Name': 'PathPal'},
              'To': [
                {'Email': 'info@pathpal.org', 'Name': 'PathPal Admin'}
              ],
              'Subject': 'PathPal: User Report Alert',
              'HTMLPart': emailContent,
              'CustomID': 'PathPalReportEmail'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Report submitted successfully. Our team will review and take appropriate action.',
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to send report: ${response.body}');
      }
    } catch (e) {
      print('Error reporting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting report')),
        );
      }
    }
  }

  String _buildEmailContent({
    required String title,
    required String introText,
    required String details,
    required String callToAction,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #f8f9fa; padding: 20px; text-align: center; }
        .content { padding: 20px; }
        .details { background-color: #f8f9fa; padding: 15px; margin: 15px 0; }
        .footer { text-align: center; padding: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>$title</h1>
        </div>
        <div class="content">
          <p>$introText</p>
          <div class="details">
            $details
          </div>
          <p>$callToAction</p>
        </div>
        <div class="footer">
          <p>This is an automated message from PathPal</p>
        </div>
      </div>
    </body>
    </html>
  ''';
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

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Help & Safety",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "If you're experiencing issues with this conversation, you can take the following actions:",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              Forgetpasswordbtn(
                icon: _hasBlocked ? Icons.person_add : Icons.block,
                descText: _hasBlocked
                    ? 'Allow user to contact you again'
                    : 'Prevent user from contacting you',
                titleText: _hasBlocked ? "Unblock User" : "Block User",
                onTap: () async {
                  Navigator.pop(context);
                  if (_hasBlocked) {
                    await _blockService.unblockUser(widget.otherUserId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Unblocked ${widget.otherUserName}'),
                        ),
                      );
                    }
                  } else {
                    await _blockService.blockUser(widget.otherUserId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Blocked ${widget.otherUserName}'),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              Forgetpasswordbtn(
                icon: Icons.report_problem,
                titleText: "Report Abuse",
                descText: "Report inappropriate behavior or content",
                onTap: () {
                  Navigator.pop(context);
                  _showReportConfirmation();
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockedMessage(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _isBlocked
                ? "You have been blocked by this user"
                : "You have blocked this user",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (_hasBlocked) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _blockService.unblockUser(widget.otherUserId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unblocked ${widget.otherUserName}'),
                    ),
                  );
                }
              },
              child: const Text('Unblock User'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatBody() {
    return SafeArea(
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
                    final isMe = message['senderId'] == _auth.currentUser?.uid;
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
                              style: Theme.of(context).textTheme.bodySmall,
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
                                      ? Text(
                                          widget.otherUserName[0].toUpperCase())
                                      : null,
                                )
                              else if (!isMe)
                                const SizedBox(width: 32),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color.fromARGB(
                                            255, 180, 221, 255)
                                        : Theme.of(context).colorScheme.surface,
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
          if (!_isBlocked && !_hasBlocked)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
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
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _blockService.isUserBlocked(widget.otherUserId),
      builder: (context, hasBlockedSnapshot) {
        return StreamBuilder<bool>(
          stream: _blockService.amIBlocked(widget.otherUserId),
          builder: (context, amBlockedSnapshot) {
            final hasBlocked = hasBlockedSnapshot.data ?? false;
            final amBlocked = amBlockedSnapshot.data ?? false;
            _isBlocked = amBlocked;
            _hasBlocked = hasBlocked;

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: AppBar(
                actions: [
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => _showHelpSheet(context),
                  ),
                ],
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
              body: _isBlocked || _hasBlocked
                  ? _buildBlockedMessage(context)
                  : _buildChatBody(),
            );
          },
        );
      },
    );
  }
}
