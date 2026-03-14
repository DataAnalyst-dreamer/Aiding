import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _childName = '';
  bool _isPremium = false;
  bool _isLoading = true;

  // 더미 상품 데이터 8개
  final List<Map<String, dynamic>> _products = [
    {'name': '신생아 속싸개', 'brand': '베베숲', 'price': '29,900원', 'emoji': '🍼'},
    {'name': '아기 체온계', 'brand': '브라운', 'price': '45,000원', 'emoji': '🌡️'},
    {'name': '유아 카시트', 'brand': '다이치', 'price': '189,000원', 'emoji': '🚗'},
    {'name': '젖병 소독기', 'brand': '필립스 아벤트', 'price': '89,000원', 'emoji': '🧴'},
    {'name': '아기 모니터', 'brand': '샤오미', 'price': '65,000원', 'emoji': '📷'},
    {'name': '유아 식판', 'brand': '리첼', 'price': '18,000원', 'emoji': '🍽️'},
    {'name': '아기 욕조', 'brand': '스토케', 'price': '55,000원', 'emoji': '🛁'},
    {'name': '수유 쿠션', 'brand': '마마스앤파파스', 'price': '39,000원', 'emoji': '🤱'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final childSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .limit(1)
          .get();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          if (childSnap.docs.isNotEmpty) {
            _childName = childSnap.docs.first.data()['name'] ?? '';
          }
          _isPremium = userDoc.data()?['isPremium'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      // AI상담 탭(2)일 때: 외부 AppBar 숨김 → AiChatScreen 자체 AppBar 사용
      appBar: _selectedIndex == 2 ? null : _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // ── Tab 0: 홈 ──────────────────────────────────────────
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4ECDC4),
                  ),
                )
              : _buildHomeBody(),

          // ── Tab 1: 추천관 (준비 중) ────────────────────────────
          _buildComingSoon('추천관', Icons.recommend_rounded),

          // ── Tab 2: AI상담 ─────────────────────────────────────
          // AiChatScreen은 자체 Scaffold(AppBar 포함)를 가짐
          // 외부 Scaffold의 appBar: null일 때 자연스럽게 전체화면처럼 보임
          const AiChatScreen(),

          // ── Tab 3: 리포트 (준비 중) ───────────────────────────
          _buildComingSoon('리포트', Icons.bar_chart_rounded),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── 준비 중 탭 공용 위젯 ────────────────────────────────────

  Widget _buildComingSoon(String name, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '$name 준비 중',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '곧 업데이트될 예정이에요!',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF4ECDC4),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _childName.isEmpty ? '아이딩' : '$_childName 맘을 위한',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Text(
            '오늘의 추천 육아용품',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        if (_isPremium)
          Container(
            margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Text('PRO',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _signOut,
          tooltip: '로그아웃',
        ),
      ],
    );
  }

  // ── 홈 탭 본문 ──────────────────────────────────────────────

  Widget _buildHomeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isPremium) _buildPremiumBanner(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final isLocked = !_isPremium && index >= 3;
                return _buildProductCard(_products[index], isLocked);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44B89D)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('프리미엄으로 업그레이드',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text('모든 추천 상품을 무제한으로 확인하세요',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4ECDC4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('시작하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isLocked) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8FAF9),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(product['emoji'],
                        style: const TextStyle(fontSize: 52)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(product['brand'],
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45)),
                    const SizedBox(height: 4),
                    Text(product['price'],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4ECDC4))),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isLocked)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.5),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 32, color: Color(0xFF4ECDC4)),
                      SizedBox(height: 8),
                      Text('프리미엄 전용',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4ECDC4))),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── 하단 네비게이션 ─────────────────────────────────────────
  // context.push / Navigator.push 없이 setState만으로 탭 전환

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4ECDC4),
      unselectedItemColor: Colors.black38,
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
        BottomNavigationBarItem(
            icon: Icon(Icons.recommend_rounded), label: '추천관'),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded), label: 'AI상담'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded), label: '리포트'),
      ],
    );
  }
}
