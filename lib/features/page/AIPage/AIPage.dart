import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────
// Chat message model
// ─────────────────────────────────────────────────────────────────────
enum MessageRole { user, assistant }

class ChatMessage {
  final String      id;
  final MessageRole role;
  final String      content;
  final DateTime    timestamp;
  final bool        isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({String? content, bool? isLoading}) => ChatMessage(
    id:        id,
    role:      role,
    content:   content   ?? this.content,
    timestamp: timestamp,
    isLoading: isLoading ?? this.isLoading,
  );
}

// ─────────────────────────────────────────────────────────────────────
// AIPage
// ─────────────────────────────────────────────────────────────────────
class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> with TickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────
  static const _bg            = Color(0xFF0A0A0F);
  static const _surface       = Color(0xFF13131A);
  static const _card          = Color(0xFF1C1C26);
  static const _gold          = Color(0xFFD4A843);
  static const _goldDeep      = Color(0xFF9A721C);
  static const _goldLight     = Color(0xFFF5D07A);
  static const _textPrimary   = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border        = Color(0xFF2A2A38);
  static const _aiBubble      = Color(0xFF1A1A26);

  // ── Controllers ────────────────────────────────────────────────
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  late final AnimationController _headerCtrl;
  late final Animation<double>   _headerAnim;
  late final AnimationController _dotCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  // ── State ──────────────────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  bool _isTyping     = false;
  bool _inputFocused = false;

  // ── Suggestion chips ────────────────────────────────────────────
  static const _suggestions = [
    _Suggestion('📊', 'Tháng này tôi chi tiêu thế nào?'),
    _Suggestion('💡', 'Gợi ý cắt giảm chi phí'),
    _Suggestion('🎯', 'Lập kế hoạch tiết kiệm'),
    _Suggestion('📈', 'Phân tích xu hướng chi tiêu'),
    _Suggestion('💰', 'Tôi có thể tiết kiệm bao nhiêu?'),
    _Suggestion('🍔', 'Chi ăn uống của tôi ra sao?'),
    _Suggestion('🏠', 'Chi phí nhà ở có hợp lý không?'),
    _Suggestion('📱', 'Tôi đang chi gì nhiều nhất?'),
  ];

  // ── System prompt ───────────────────────────────────────────────
  static const _systemPrompt = '''
Bạn là DoctorĐồng AI — trợ lý tài chính thông minh của ứng dụng quản lý chi tiêu DoctorĐồng.

Vai trò:
- Phân tích chi tiêu và đưa ra gợi ý tài chính thông minh
- Giúp người dùng lập kế hoạch tiết kiệm và ngân sách
- Trả lời các câu hỏi về quản lý tài chính cá nhân

Phong cách:
- Tiếng Việt, thân thiện, chuyên nghiệp
- Ngắn gọn, súc tích, dùng emoji nổi bật điểm quan trọng
- Dùng **bold** để nhấn mạnh số liệu quan trọng
- Kết thúc bằng câu hỏi hoặc gợi ý hành động cụ thể
''';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _headerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _headerAnim = CurvedAnimation(
      parent: _headerCtrl, curve: Curves.easeOut,
    );
    _headerCtrl.forward();

    _dotCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _dotCtrl.dispose();
    _pulseCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id:        'welcome',
        role:      MessageRole.assistant,
        content:   'Xin chào! Tôi là **DoctorĐồng AI** ✨\n\nTôi có thể giúp bạn:\n• 📊 Phân tích chi tiêu hàng tháng\n• 💡 Gợi ý cắt giảm & tiết kiệm\n• 🎯 Lập kế hoạch ngân sách\n\nBạn muốn hỏi gì hôm nay?',
        timestamp: DateTime.now(),
      ));
    });
  }

  // ── Send message ────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    final userMsg = ChatMessage(
      id:        '${DateTime.now().millisecondsSinceEpoch}_user',
      role:      MessageRole.user,
      content:   text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    final loadingId = '${DateTime.now().millisecondsSinceEpoch}_loading';
    setState(() {
      _messages.add(ChatMessage(
        id:        loadingId,
        role:      MessageRole.assistant,
        content:   '',
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });
    _scrollToBottom();

    try {
      await _callGeminiAPI(text, loadingId);
    } catch (e) {
      _replaceLoadingMessage(
        loadingId,
        '⚠️ Xin lỗi, tôi gặp sự cố kết nối. Vui lòng thử lại sau.',
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  // ── Call Gemini API ─────────────────────────────────────────────
  Future<void> _callGeminiAPI(String userText, String loadingId) async {
    // TODO: Thay bằng API key thật hoặc dùng backend proxy
    const apiKey = 'YOUR_GEMINI_API_KEY';
    const model  = 'gemini-1.5-flash';
    final url    =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    // Build history (bỏ qua loading message)
    final history = _messages
        .where((m) => !m.isLoading && m.id != loadingId)
        .map((m) => {
      'role':  m.role == MessageRole.user ? 'user' : 'model',
      'parts': [{'text': m.content}],
    })
        .toList();

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _systemPrompt}],
      },
      'contents': history,
      'generationConfig': {
        'temperature':     0.7,
        'maxOutputTokens': 1024,
      },
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final json   = jsonDecode(response.body);
      final aiText = json['candidates']?[0]?['content']?['parts']?[0]?['text']
      as String? ??
          'Tôi không hiểu câu hỏi này, bạn có thể hỏi lại không?';
      _replaceLoadingMessage(loadingId, aiText);
    } else {
      _replaceLoadingMessage(
          loadingId, '⚠️ Lỗi ${response.statusCode}. Vui lòng thử lại.');
    }
  }

  void _replaceLoadingMessage(String loadingId, String content) {
    if (!mounted) return;
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == loadingId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(
          content:   content,
          isLoading: false,
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            FadeTransition(opacity: _headerAnim, child: _buildHeader()),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: (!_inputFocused && _messages.length <= 1)
                  ? _buildSuggestions()
                  : const SizedBox.shrink(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1.h)),
      ),
      child: Row(
        children: [
          // AI avatar — pulse animation
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            ),
            child: Stack(
              children: [
                // Outer glow
                Container(
                  width: 46.w, height: 46.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _gold.withOpacity(0.2),
                      Colors.transparent,
                    ]),
                  ),
                ),
                // Inner circle
                Container(
                  width: 46.w, height: 46.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _surface,
                    border: Border.all(
                        color: _gold.withOpacity(0.5), width: 1.5.w),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_goldDeep, _goldLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(b),
                      child: Text('✦',
                          style: TextStyle(
                            fontSize: 22.sp, color: Colors.white,
                          )),
                    ),
                  ),
                ),
                // Online dot
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 12.w, height: 12.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2ECC8A),
                      border: Border.all(color: _bg, width: 2.w),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('DoctorĐồng AI',
                        style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w700,
                          color: _textPrimary, letterSpacing: -0.3,
                        )),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(
                            color: _gold.withOpacity(0.3), width: 1.w),
                      ),
                      child: Text('AI',
                          style: TextStyle(
                            fontSize: 9.sp, color: _gold,
                            fontWeight: FontWeight.w800, letterSpacing: 0.5,
                          )),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      width: 6.w, height: 6.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2ECC8A),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      _isTyping ? 'Đang soạn...' : 'Trợ lý tài chính thông minh',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _isTyping ? _gold : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Clear chat
          if (_messages.length > 1)
            GestureDetector(
              onTap: () => setState(() {
                _messages.clear();
                _addWelcomeMessage();
              }),
              child: Container(
                width: 36.w, height: 36.w,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1.w),
                ),
                child: Icon(Icons.refresh_rounded,
                    color: _textSecondary, size: 17.sp),
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✦',
              style: TextStyle(fontSize: 52.sp, color: _gold)),
          SizedBox(height: 16.h),
          Text('Hỏi tôi bất cứ điều gì',
              style: TextStyle(
                fontSize: 18.sp, fontWeight: FontWeight.w700,
                color: _textPrimary,
              )),
          SizedBox(height: 6.h),
          Text('về tài chính của bạn',
              style: TextStyle(fontSize: 14.sp, color: _textSecondary)),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg      = _messages[i];
        final prev     = i > 0 ? _messages[i - 1] : null;
        final showTime = prev == null ||
            msg.timestamp.difference(prev.timestamp).inMinutes >= 5;
        return Column(
          children: [
            if (showTime) _buildTimestamp(msg.timestamp),
            _buildBubble(msg,
                showAvatar: prev == null || prev.role != msg.role),
          ],
        );
      },
    );
  }

  Widget _buildTimestamp(DateTime dt) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        _formatTime(dt),
        style: TextStyle(fontSize: 10.sp, color: _textSecondary.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, {required bool showAvatar}) {
    final isUser = msg.role == MessageRole.user;
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          if (!isUser) ...[
            if (showAvatar)
              Container(
                width: 28.w, height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _surface,
                  border: Border.all(
                      color: _gold.withOpacity(0.35), width: 1.w),
                ),
                child: Center(
                  child: Text('✦',
                      style: TextStyle(fontSize: 12.sp, color: _gold)),
                ),
              )
            else
              SizedBox(width: 28.w),
            SizedBox(width: 8.w),
          ],

          // Content
          Flexible(
            child: msg.isLoading
                ? _buildTypingBubble()
                : _buildTextBubble(msg, isUser),
          ),

          // User avatar
          if (isUser) ...[
            SizedBox(width: 8.w),
            if (showAvatar)
              Container(
                width: 28.w, height: 28.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_goldDeep, _gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text('Bạn',
                      style: TextStyle(
                        fontSize: 7.sp, fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1200),
                      )),
                ),
              )
            else
              SizedBox(width: 28.w),
          ],
        ],
      ),
    );
  }

  Widget _buildTextBubble(ChatMessage msg, bool isUser) {
    return Container(
      constraints: BoxConstraints(maxWidth: 265.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isUser ? _gold.withOpacity(0.13) : _aiBubble,
        borderRadius: BorderRadius.only(
          topLeft:     Radius.circular(isUser ? 18.r : 4.r),
          topRight:    Radius.circular(isUser ? 4.r : 18.r),
          bottomLeft:  Radius.circular(18.r),
          bottomRight: Radius.circular(18.r),
        ),
        border: Border.all(
          color: isUser ? _gold.withOpacity(0.25) : _border,
          width: 1.w,
        ),
      ),
      child: _parseMarkdown(msg.content, isUser),
    );
  }

  // ── Markdown parser: **bold** ───────────────────────────────────
  Widget _parseMarkdown(String text, bool isUser) {
    final lines   = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        if (widgets.isNotEmpty) widgets.add(SizedBox(height: 4.h));
        continue;
      }
      widgets.add(_parseLine(line, isUser));
      if (i < lines.length - 1) widgets.add(SizedBox(height: 2.h));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _parseLine(String line, bool isUser) {
    final regex  = RegExp(r'\*\*(.+?)\*\*');
    final spans  = <InlineSpan>[];
    int   last   = 0;

    for (final m in regex.allMatches(line)) {
      if (m.start > last) {
        spans.add(TextSpan(text: line.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text:  m.group(1),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isUser ? _goldLight : _gold,
        ),
      ));
      last = m.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14.sp,
          color:  _textPrimary,
          height: 1.45,
        ),
        children: spans,
      ),
    );
  }

  // ── Typing indicator (3 gold dots) ──────────────────────────────
  Widget _buildTypingBubble() {
    return Container(
      width: 70.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _aiBubble,
        borderRadius: BorderRadius.only(
          topLeft:     Radius.circular(4.r),
          topRight:    Radius.circular(18.r),
          bottomLeft:  Radius.circular(18.r),
          bottomRight: Radius.circular(18.r),
        ),
        border: Border.all(color: _border, width: 1.w),
      ),
      child: AnimatedBuilder(
        animation: _dotCtrl,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t  = (_dotCtrl.value + i * 0.33) % 1.0;
              final op = (t < 0.5 ? 0.3 + t * 1.4 : 1.0 - (t - 0.5) * 1.4)
                  .clamp(0.2, 1.0);
              final sc = t < 0.5 ? 0.7 + t * 0.6 : 1.3 - (t - 0.5) * 0.6;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Transform.scale(
                  scale: sc.clamp(0.7, 1.3),
                  child: Container(
                    width: 7.w, height: 7.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withOpacity(op),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ── Suggestion chips ────────────────────────────────────────────
  Widget _buildSuggestions() {
    return Column(
      key: const ValueKey('suggestions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
          child: Row(
            children: [
              Container(
                width: 4.w, height: 4.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withOpacity(0.7),
                ),
              ),
              SizedBox(width: 6.w),
              Text('Gợi ý câu hỏi',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  )),
            ],
          ),
        ),
        SizedBox(
          height: 82.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _suggestions.length,
            itemBuilder: (_, i) => _buildChip(_suggestions[i]),
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildChip(_Suggestion s) {
    return GestureDetector(
      onTap: () => _sendMessage(s.text),
      child: Container(
        margin: EdgeInsets.only(right: 10.w),
        width:  155.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _border, width: 1.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.emoji, style: TextStyle(fontSize: 12.sp)),
            SizedBox(height: 5.h),
            Text(
              s.text,
              style: TextStyle(
                fontSize: 10.sp,
                color: _textSecondary,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          top: BorderSide(
            color: _inputFocused ? _gold.withOpacity(0.2) : _border,
            width: 1.h,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(maxHeight: 130.h),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: _inputFocused
                      ? _gold.withOpacity(0.45)
                      : _border,
                  width: _inputFocused ? 1.5.w : 1.w,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: 16.w),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _textPrimary,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Hỏi về tài chính của bạn...',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: _textSecondary.withOpacity(0.45),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 11.h),
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty && !_isTyping) {
                          _sendMessage(v);
                        }
                      },
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Send button
          ListenableBuilder(
            listenable: _inputCtrl,
            builder: (_, __) {
              final hasText = _inputCtrl.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: hasText && !_isTyping
                    ? () => _sendMessage(_inputCtrl.text)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46.w, height: 46.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasText && !_isTyping ? _gold : _surface,
                    border: Border.all(
                      color: hasText && !_isTyping ? _gold : _border,
                      width: 1.w,
                    ),
                  ),
                  child: _isTyping
                      ? Padding(
                    padding: EdgeInsets.all(13.w),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _textSecondary,
                    ),
                  )
                      : Icon(
                    Icons.arrow_upward_rounded,
                    color: hasText
                        ? const Color(0xFF1A1200)
                        : _textSecondary,
                    size: 20.sp,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Suggestion data ──────────────────────────────────────────────────
class _Suggestion {
  final String emoji;
  final String text;
  const _Suggestion(this.emoji, this.text);
}