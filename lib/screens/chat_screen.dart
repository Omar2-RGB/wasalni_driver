import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;     // رقم الرحلة لربط المحادثة بها
  final String myUserId;   // الـ ID الخاص بالكابتن (أو الراكب) لتمييز المرسل

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.myUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    // جلب الرسائل الخاصة بهذه الرحلة فقط، وترتيبها من الأحدث للأقدم
    _messagesStream = supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('ride_id', widget.rideId)
        .order('created_at', ascending: false);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear(); // تفريغ الحقل فوراً لتجربة مستخدم سريعة

    try {
      await supabase.from('chat_messages').insert({
        'ride_id': widget.rideId,
        'sender_id': widget.myUserId,
        'message': text,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إرسال الرسالة، تأكد من اتصالك')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('المحادثة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // منطقة عرض الرسائل
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('لا توجد رسائل بعد.. ابدأ المحادثة الآن 💬', style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true, // مهم جداً: يجعل الرسائل الجديدة تظهر في الأسفل
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == widget.myUserId;

                    return _buildMessageBubble(msg['message'], isMe);
                  },
                );
              },
            ),
          ),

          // منطقة كتابة الرسالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'Cairo'),
                        filled: true,
                        fillColor: const Color(0xFF0B1120),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sendMessage,
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

  // تصميم "فقاعة" الرسالة (Bubble)
  Widget _buildMessageBubble(String message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? Radius.zero : const Radius.circular(20),
            bottomRight: isMe ? const Radius.circular(20) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cairo'),
        ),
      ),
    );
  }
}