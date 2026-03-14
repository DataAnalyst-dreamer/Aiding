// ─────────────────────────────────────────────────────────────
// lib/screens/ai_chat_screen.dart
//
// AI 육아 상담 채팅 화면
// - 카카오톡 스타일 말풍선 UI
// - Gemini API 연동
// - 무료 사용자 월 3회 제한 (Firestore chatCount 관리)
// ─────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_service.dart';

const _mint = Color(0xFF4ECDC4);
const _freeLimit = 3; // 무료 사용자 월 상담 한도

// ── 메시지 데이터 모델 ──────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading; // "..." 로딩 말풍선 여부

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });
}

// ─────────────────────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false; // 전송 버튼 비활성화용
  int _chatCount = 0;      // 이번 달 사용 횟수
  bool _isPremium = false;
  String _childName = '';
  int _ageInMonths = 0;
  String _currentMonth = ''; // "2026-03" 형식

  @override
  void initState() {
    super.initState();
    _currentMonth = _yearMonth(DateTime.now());
    _addWelcomeMessage();
    _loadUserData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── 헬퍼 ────────────────────────────────────────────────────

  String _yearMonth(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  void _addWelcomeMessage() {
    _messages.add(const ChatMessage(
      text: '안녕하세요! 저는 아이딩 AI예요 😊\n'
          '육아용품 고민, 아이 발달, 뭐든 편하게 물어보세요!',
      isUser: false,
    ));
  }

  // ── Firestore에서 사용자 정보 로드 ───────────────────────────

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data() ?? {};
      final savedMonth = data['chatCountMonth'] as String? ?? '';
      final savedCount = data['chatCount'] as int? ?? 0;

      // 달이 바뀌었으면 횟수 리셋
      final thisMonthCount = savedMonth == _currentMonth ? savedCount : 0;
      if (savedMonth != _currentMonth) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'chatCount': 0, 'chatCountMonth': _currentMonth});
      }

      // 아이 정보
      final childSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .orderBy('createdAt')
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isPremium = data['isPremium'] as bool? ?? false;
          _chatCount = thisMonthCount;
          if (childSnap.docs.isNotEmpty) {
            final c = childSnap.docs.first.data();
            _childName = c['name'] as String? ?? '';
            _ageInMonths = c['ageInMonths'] as int? ?? 0;
          }
        });
      }
    } catch (_) {}
  }

  // ── 메시지 전송 ──────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    // 무료 한도 초과 체크
    if (!_isPremium && _chatCount >= _freeLimit) {
      _showLimitDialog();
      return;
    }

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      // 로딩 말풍선 추가
      _messages.add(
        const ChatMessage(text: '', isUser: false, isLoading: true),
      );
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final answer = await GeminiService.instance.generateText(
        _buildPrompt(text),
      );

      setState(() {
        _messages.removeLast(); // 로딩 말풍선 제거
        _messages.add(ChatMessage(text: answer, isUser: false));
        _isSending = false;
      });

      // 횟수 차감 (프리미엄은 제외)
      if (!_isPremium) await _incrementCount();
    } catch (_) {
      setState(() {
        _messages.removeLast();
        _messages.add(const ChatMessage(
          text: '답변을 가져오지 못했어요. 잠시 후 다시 시도해주세요.',
          isUser: false,
        ));
        _isSending = false;
      });
    }

    _scrollToBottom();
  }

  String _buildPrompt(String question) => '''
[시스템 지침]
당신은 친절하고 따뜻한 육아 도우미 AI입니다.
육아 관련 질문에 실용적이고 공감 어린 답변을 해주세요.
의료적 진단이나 처방은 하지 않으며, 필요한 경우 전문 의료진 상담을 권유합니다.
답변은 3~5문장으로 간결하게 해주세요.

[현재 상담 아이 정보]
- 이름: ${_childName.isEmpty ? '아이' : _childName}
- 나이: $_ageInMonths개월

[부모의 질문]
$question
''';

  Future<void> _incrementCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _chatCount++);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'chatCount': _chatCount, 'chatCountMonth': _currentMonth});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── 한도 초과 팝업 ───────────────────────────────────────────

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🔒 ', style: TextStyle(fontSize: 20)),
            Text(
              '무료 상담 소진',
              style: GoogleFonts.notoSans(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          '이번 달 무료 상담을 모두 사용했어요.\n'
          '프리미엄 구독 시 무제한으로 이용할 수 있어요!',
          style: GoogleFonts.notoSans(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('닫기', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _mint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 프리미엄 구독 화면으로 이동
            },
            child: Text(
              '프리미엄 시작하기',
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 빌드 ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 채팅 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),
          // 무료 사용자 남은 횟수 배너
          if (!_isPremium) _buildCountBanner(),
          // 입력창
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'AI 육아 상담',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          Text(
            'Powered by Gemini',
            style: GoogleFonts.notoSans(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── 말풍선 ─────────────────────────────────────────────────

  Widget _buildBubble(ChatMessage msg) {
    if (msg.isUser) {
      // ── 사용자 말풍선 (오른쪽, 민트그린) ─────────────────────
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 64),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── AI 말풍선 (왼쪽, 흰색) ─────────────────────────────────
    return Padding(
      padding: const EdgeInsets.only(top: 12, right: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "아이딩 AI" 이름 표시
          Padding(
            padding: const EdgeInsets.only(left: 46, bottom: 4),
            child: Text(
              '아이딩 AI',
              style: GoogleFonts.notoSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _mint,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI 아바타
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _mint.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 18)),
                ),
              ),
              // 말풍선
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: msg.isLoading
                      ? const _LoadingDots()
                      : Text(
                          msg.text,
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: const Color(0xFF333333),
                            height: 1.6,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 남은 횟수 배너 ─────────────────────────────────────────

  Widget _buildCountBanner() {
    final remaining = _freeLimit - _chatCount;
    final isExhausted = remaining <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      color: isExhausted
          ? Colors.red.withValues(alpha: 0.08)
          : _mint.withValues(alpha: 0.08),
      child: Text(
        isExhausted
            ? '이번 달 무료 상담 횟수를 모두 사용했어요. 프리미엄으로 무제한 이용하세요!'
            : '이번 달 무료 상담 $remaining회 남았어요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isExhausted ? Colors.red[700] : _mint,
        ),
      ),
    );
  }

  // ── 입력창 ─────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8, // 하단 안전 영역 대응
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 텍스트 입력창
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.notoSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: '육아 고민을 입력해보세요...',
                hintStyle: GoogleFonts.notoSans(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey[300] : _mint,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 로딩 점 애니메이션 (".  ..  ...") ──────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() {
        final next = (_ctrl.value * 3).floor();
        if (next != _step) setState(() => _step = next);
      });
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1개 → 2개 → 3개 점이 반복됨
    final dots = '●' * (_step + 1);
    return Text(
      dots,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[400],
        letterSpacing: 4,
      ),
    );
  }
}
