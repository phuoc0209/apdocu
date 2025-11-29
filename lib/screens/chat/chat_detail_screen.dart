import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  ChatModel? _chat;
  String? _otherUserName;
  String? _otherUserPhoto;
  bool _isSendingImage = false;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatInfo() async {
    if (_currentUser == null) return;

    try {
      final chat = await _chatService.getChatById(widget.chatId);
      if (!mounted || chat == null) return;

      final otherUserId = chat.participantIds.firstWhere(
        (id) => id != _currentUser!.uid,
        orElse: () => _currentUser!.uid,
      );

      setState(() {
        _chat = chat;
        _otherUserName = chat.participantNames[otherUserId];
        _otherUserPhoto = chat.participantPhotos[otherUserId];
      });
    } catch (e) {
      debugPrint('Load chat info error: $e');
    }
  }

  Future<void> _markAsRead() async {
    if (_currentUser != null) {
      await _chatService.markAsRead(widget.chatId, _currentUser!.uid);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null) return;

    try {
      final userData = await _authService.getUserData(_currentUser!.uid);
      if (userData == null) return;

      await _chatService.sendMessage(
        widget.chatId,
        _currentUser!.uid,
        userData.displayName,
        userData.photoURL,
        _messageController.text.trim(),
      );

      _messageController.clear();
      
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    if (_currentUser == null || _isSendingImage) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() => _isSendingImage = true);

      final userData = await _authService.getUserData(_currentUser!.uid);
      if (userData == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      await _chatService.sendImageMessage(
        widget.chatId,
        _currentUser!.uid,
        userData.displayName,
        userData.photoURL,
        pickedFile,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingImage = false);
      }
    }
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final theme = Theme.of(context);
    final isImageMessage =
        message.type == MessageContentType.image && message.imageUrl != null;
    final bubbleColor = isMe ? Colors.white : null;
    final bubbleGradient = isMe
        ? null
        : (isImageMessage
            ? null
            : const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF836FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ));
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomLeft: isMe ? const Radius.circular(24) : const Radius.circular(8),
      bottomRight: isMe ? const Radius.circular(8) : const Radius.circular(24),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildMessageContent(
            message: message,
            isMe: isMe,
            borderRadius: borderRadius,
            bubbleColor: bubbleColor,
            bubbleGradient: bubbleGradient,
            theme: theme,
          ),
          const SizedBox(height: 6),
          Text(
            timeago.format(message.createdAt, locale: 'vi'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9AA0C2),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _isSendingImage
                    ? null
                    : () => _handleImageSelection(ImageSource.gallery),
                icon: Icon(
                  Icons.photo_outlined,
                  color: _isSendingImage
                      ? const Color(0xFFB4B9D9)
                      : const Color(0xFF6C63FF),
                ),
                splashRadius: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                onPressed: _isSendingImage
                    ? null
                    : () => _handleImageSelection(ImageSource.camera),
                icon: Icon(
                  Icons.photo_camera_outlined,
                  color: _isSendingImage
                      ? const Color(0xFFBFC4DF)
                      : const Color(0xFFB4B9D9),
                ),
                splashRadius: 22,
              ),
              if (_isSendingImage) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ] else
                const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF836FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF2E335A),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE1E5F8),
              backgroundImage: _otherUserPhoto != null
                  ? CachedNetworkImageProvider(_otherUserPhoto!)
                  : null,
              child: _otherUserPhoto == null
                  ? const Icon(Icons.person, color: Color(0xFF6C63FF))
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _otherUserName ?? 'Đang trò chuyện',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2E335A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đang hoạt động',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9AA0C2),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            color: const Color(0xFF6C63FF),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('Bắt đầu cuộc trò chuyện'),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markAsRead();
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _currentUser?.uid;

                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent({
    required MessageModel message,
    required bool isMe,
    required BorderRadius borderRadius,
    required Color? bubbleColor,
    required Gradient? bubbleGradient,
    required ThemeData theme,
  }) {
    final isImageMessage =
        message.type == MessageContentType.image && message.imageUrl != null;

    if (isImageMessage) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: isMe
              ? Border.all(color: const Color(0xFFE1E5F8))
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              maxHeight: 320,
            ),
            child: _buildImageContent(message.imageUrl!),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bubbleColor,
        gradient: bubbleGradient,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: isMe
            ? Border.all(
                color: const Color(0xFFE1E5F8),
              )
            : null,
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      child: Text(
        message.content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isMe ? const Color(0xFF2E335A) : Colors.white,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildImageContent(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      } catch (e) {
        debugPrint('Decode chat image error: $e');
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: const Color(0xFFE6E7F5),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFE6E7F5),
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF9AA0C2),
        ),
      ),
    );
  }
}
