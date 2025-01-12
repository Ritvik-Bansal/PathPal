// functions/index.js

const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendChatNotification = onCall(async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new Error('Unauthenticated');
  }

  const { recipientId, message, senderName, chatId } = request.data;

  try {
    // Get recipient's FCM token
    const recipientDoc = await getFirestore()
      .collection('users')
      .doc(recipientId)
      .get();

    const recipientToken = recipientDoc.data()?.fcmToken;
    if (!recipientToken) {
      console.log('No FCM token found for recipient:', recipientId);
      return;
    }

    // Construct and send the notification
    const notificationMessage = {
      token: recipientToken,
      notification: {
        title: senderName,
        body: message,
      },
      data: {
        chatId: chatId,
        type: 'chat_message',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_messages',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    await getMessaging().send(notificationMessage);
    console.log('Notification sent successfully to:', recipientId);
    
    return { success: true };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new Error('Error sending notification');
  }
});

// Trigger notifications on new messages
exports.onNewMessage = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const message = event.data.data();
    const chatId = event.params.chatId;

    if (!message) return;

    try {
      // Get chat document to find recipient
      const chatDoc = await getFirestore()
        .collection('chats')
        .doc(chatId)
        .get();

      const chatData = chatDoc.data();
      if (!chatData) return;

      // Find recipient (the user who didn't send the message)
      const recipientId = chatData.participants.find(id => id !== message.senderId);
      if (!recipientId) return;

      // Get sender's name
      const senderDoc = await getFirestore()
        .collection('users')
        .doc(message.senderId)
        .get();

      const senderName = senderDoc.data()?.name ?? 'User';

      // Send the notification using the same logic as above
      const recipientDoc = await getFirestore()
        .collection('users')
        .doc(recipientId)
        .get();

      const recipientToken = recipientDoc.data()?.fcmToken;
      if (!recipientToken) {
        console.log('No FCM token found for recipient:', recipientId);
        return;
      }

      const notificationMessage = {
        token: recipientToken,
        notification: {
          title: senderName,
          body: message.text,
        },
        data: {
          chatId: chatId,
          type: 'chat_message',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'chat_messages',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      await getMessaging().send(notificationMessage);
      console.log('Notification sent successfully to:', recipientId);
    } catch (error) {
      console.error('Error in onNewMessage function:', error);
    }
  }
);