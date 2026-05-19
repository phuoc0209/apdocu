import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final UserModel? _currentUser = AuthService().currentUser;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatChatTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(timestamp);
    }

    if (difference.inDays < 7) {
      return DateFormat('EEE', 'en_US').format(timestamp);
    }

    return timeago.format(timestamp, locale: 'vi');
  }

  Widget _buildChatTile(ChatModel chat, String otherUserId) {
    final otherUserName = chat.participantNames[otherUserId] ?? 'Người dùng';
    final otherUserPhoto = chat.participantPhotos[otherUserId];
    final unreadCount = chat.unreadCount[_currentUser!.uid] ?? 0;
    final isUnread = unreadCount > 0;
    final isActive = chat.lastMessageTime != null &&
        DateTime.now().difference(chat.lastMessageTime!).inMinutes <= 5;
    final previewText = chat.lastMessageType == MessageContentType.image
        ? 'Đã gửi một ảnh'
        : (chat.lastMessage ?? 'Chưa có tin nhắn');

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/chat-detail',
          arguments: chat.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFEAE8FF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFD9DDF4),
                  backgroundImage: otherUserPhoto != null
                      ? CachedNetworkImageProvider(otherUserPhoto)
                      : null,
                  child: otherUserPhoto == null
                      ? Text(
                          otherUserName.isNotEmpty
                              ? otherUserName[0].toUpperCase()
                              : 'N',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C63FF),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF49D67D)
                          : const Color(0xFFCBD0E8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                      color: const Color(0xFF2E335A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnread
                          ? const Color(0xFF4C4F6B)
                          : const Color(0xFF8389A8),
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chat.lastMessageTime != null)
                      Text(
                        _formatChatTime(chat.lastMessageTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8389A8),
                        ),
                      ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Color(0xFFB0B4D4),
                      ),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xóa cuộc trò chuyện'),
                              content: const Text(
                                  'Bạn có chắc muốn xóa toàn bộ tin nhắn với người này không?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await _chatService.deleteChat(chat.id);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Không thể xóa cuộc trò chuyện: $e'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Xóa cuộc trò chuyện'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isUnread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để sử dụng chat'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E335A),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Kết nối và trò chuyện',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8389A8),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      color: const Color(0xFF6C63FF),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFF8389A8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Tìm kiếm',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ChatModel>>(
                future: _chatService.getUserChats(_currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }

                  final chats = snapshot.data ?? [];

                  final filteredChats = chats.where((chat) {
                    final otherUserId = chat.participantIds
                        .firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
                    final name = chat.participantNames[otherUserId] ?? '';
                    final lastMessage = chat.lastMessage ?? '';

                    if (_searchQuery.isEmpty) return true;

                    return name.toLowerCase().contains(_searchQuery) ||
                        lastMessage.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredChats.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không tìm thấy cuộc trò chuyện',
                        style: TextStyle(
                          color: Color(0xFF8389A8),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final otherUserId = chat.participantIds
                          .firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
                      return _buildChatTile(chat, otherUserId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
