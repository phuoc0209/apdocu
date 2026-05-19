import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();

  // Create or get existing chat
  Future<String> createOrGetChat(
    String user1Id,
    String user1Name,
    String? user1Photo,
    String user2Id,
    String user2Name,
    String? user2Photo,
  ) async {
    // TODO: Implement API endpoint
    // final response = await _apiService.post('chats/create.php', { ... });
    // return response['id'];
    return const Uuid().v4();
  }

  // Get user chats
  Future<List<ChatModel>> getUserChats(String userId) async {
    // TODO: Implement API endpoint
    // final response = await _apiService.get('chats/list.php?userId=$userId');
    // return (response as List).map((e) => ChatModel.fromMap(e)).toList();
    return [];
  }

  Future<ChatModel?> getChatById(String chatId) async {
    // TODO: Implement API endpoint
    // final response = await _apiService.get('chats/detail.php?chatId=$chatId');
    // return ChatModel.fromMap(response);
    return null;
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
    // TODO: Implement API endpoint
    // await _apiService.post('messages/send.php', { ... });
  }

  Future<void> sendImageMessage(
    String chatId,
    String senderId,
    String senderName,
    String? senderPhoto,
    XFile image, {
    String caption = '',
  }) async {
    // TODO: Implement API endpoint with image upload
    // final imageUrl = await _apiService.uploadImage(File(image.path));
    // await sendMessage(..., imageUrl: imageUrl, ...);
  }

  // Get messages
  Future<List<MessageModel>> getMessages(String chatId) async {
    // TODO: Implement API endpoint
    // final response = await _apiService.get('messages/list.php?chatId=$chatId');
    // return (response as List).map((e) => MessageModel.fromMap(e)).toList();
    return [];
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    // TODO: Implement API endpoint
    // await _apiService.post('chats/mark_read.php', { ... });
  }

  // Delete single message
  Future<void> deleteMessage(String chatId, String messageId) async {
    // TODO: Implement API endpoint
    // await _apiService.post('messages/delete.php', { ... });
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    // TODO: Implement API endpoint
    // await _apiService.post('chats/delete.php', { ... });
  }
}
