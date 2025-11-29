import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/message_model.dart';
import 'firestore_image_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreImageService _imageService = FirestoreImageService();

  // Create or get existing chat
  Future<String> createOrGetChat(
    String user1Id,
    String user1Name,
    String? user1Photo,
    String user2Id,
    String user2Name,
    String? user2Photo,
  ) async {
    try {
      // Check if chat already exists
      QuerySnapshot existingChats = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: user1Id)
          .get();

      for (var doc in existingChats.docs) {
        ChatModel chat = ChatModel.fromDocument(doc);
        if (chat.participantIds.contains(user2Id)) {
          return doc.id;
        }
      }

      // Create new chat
      ChatModel newChat = ChatModel(
        id: _firestore.collection('chats').doc().id,
        participantIds: [user1Id, user2Id],
        participantNames: {
          user1Id: user1Name,
          user2Id: user2Name,
        },
        participantPhotos: {
          user1Id: user1Photo,
          user2Id: user2Photo,
        },
        unreadCount: {
          user1Id: 0,
          user2Id: 0,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('chats')
          .doc(newChat.id)
          .set(newChat.toMap());

      return newChat.id;
    } catch (e) {
      print('Create or get chat error: $e');
      rethrow;
    }
  }

  // Get user chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs.map((doc) => ChatModel.fromDocument(doc)).toList();
          chats.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });
          return chats;
        });
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return ChatModel.fromDocument(doc);
    } catch (e) {
      print('Get chat by id error: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String senderName,
    String? senderPhoto,
    String content, {
    String? imageUrl,
    MessageContentType contentType = MessageContentType.text,
  }) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      MessageModel message = MessageModel(
        id: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoURL: senderPhoto,
        content: content,
        imageUrl: imageUrl,
        type: contentType,
        createdAt: DateTime.now(),
      );

      await messageRef.set(message.toMap());

      DocumentSnapshot chatDoc =
          await _firestore.collection('chats').doc(chatId).get();
      ChatModel chat = ChatModel.fromDocument(chatDoc);

      Map<String, int> newUnreadCount = Map.from(chat.unreadCount);
      for (String participantId in chat.participantIds) {
        if (participantId != senderId) {
          newUnreadCount[participantId] = (newUnreadCount[participantId] ?? 0) + 1;
        }
      }

      final lastMessagePreview = contentType == MessageContentType.image
          ? 'Đã gửi một ảnh'
          : content;

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': lastMessagePreview,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'lastMessageSenderId': senderId,
        'unreadCount': newUnreadCount,
        'lastMessageType': contentType.name,
      });
    } catch (e) {
      print('Send message error: $e');
      rethrow;
    }
  }

  Future<void> sendImageMessage(
    String chatId,
    String senderId,
    String senderName,
    String? senderPhoto,
    XFile image, {
    String caption = '',
  }) async {
    try {
      final imageDataUrl = await _imageService.encodeImageAsDataUrl(
        image,
        targetSizeKB: 280,
      );

      await sendMessage(
        chatId,
        senderId,
        senderName,
        senderPhoto,
        caption,
        imageUrl: imageDataUrl,
        contentType: MessageContentType.image,
      );
    } catch (e) {
      print('Send image message error: $e');
      rethrow;
    }
  }

  // Get messages
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromDocument(doc))
            .toList());
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      print('Mark as read error: $e');
      rethrow;
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Delete chat
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      print('Delete chat error: $e');
      rethrow;
    }
  }
}
