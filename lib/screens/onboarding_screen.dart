import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSaving = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  int _calculateAgeInMonths(DateTime birthDate) {
    final now = DateTime.now();
    int months =
        (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) months--;
    return months < 0 ? 0 : months;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 6),
      lastDate: now,
      helpText: '아이 생년월일 선택',
      cancelText: '취소',
      confirmText: '확인',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4ECDC4),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveChildToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDate == null) return;

    final ageInMonths = _calculateAgeInMonths(_selectedDate!);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('children')
        .add({
      'name': _nameController.text.trim(),
      'birthDate': Timestamp.fromDate(_selectedDate!),
      'ageInMonths': ageInMonths,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _goToNextStep() async {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showSnackBar('아이 이름을 입력해주세요 😊');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_selectedDate == null) {
        _showSnackBar('생년월일을 선택해주세요 📅');
        return;
      }
      setState(() => _isSaving = true);
      await _saveChildToFirestore();
      setState(() {
        _isSaving = false;
        _currentStep = 2;
      });
      _animController.forward();
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        // 내비게이션 로직 변경: GoRouter를 사용해 홈으로 이동
        context.go('/');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4ECDC4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _buildProgressBar(),
              const SizedBox(height: 36),
              Expanded(
                child: _buildStepContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(3, (index) {
        final bool isCompleted = index < _currentStep;
        final bool isCurrent = index == _currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: (isCompleted || isCurrent)
                  ? const Color(0xFF4ECDC4)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1 / 3',
          style: TextStyle(
            color: const Color(0xFF4ECDC4),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '아이 이름을\n알려주세요 👶',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _goToNextStep(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: '예: 이준서',
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 22),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4ECDC4), width: 2),
            ),
          ),
        ),
        const Spacer(),
        _buildNextButton('다음'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep2() {
    final String ageText = _selectedDate != null
        ? '현재 ${_calculateAgeInMonths(_selectedDate!)}개월이에요'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2 / 3',
          style: TextStyle(
            color: Color(0xFF4ECDC4),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '아이 생년월일을\n선택해주세요 🗓️',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 48),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FAF9), // 연한 민트 배경
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedDate != null
                    ? const Color(0xFF4ECDC4)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF4ECDC4), size: 26),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.year}년 '
                              '${_selectedDate!.month}월 '
                              '${_selectedDate!.day}일'
                          : '날짜를 선택해주세요',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: _selectedDate != null
                            ? Colors.black87
                            : Colors.black38,
                      ),
                    ),
                    if (ageText.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        ageText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4ECDC4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _isSaving
            ? const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4ECDC4)),
                    SizedBox(height: 12),
                    Text('저장 중...', style: TextStyle(color: Colors.black45)),
                  ],
                ),
              )
            : _buildNextButton('저장하고 시작하기'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep3() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                color: Color(0xFF4ECDC4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 72),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            '${_nameController.text.trim()}와(과) 함께\n시작할 준비가 됐어요! 🎉',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '잠시 후 앱이 시작돼요...',
            style: TextStyle(fontSize: 15, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _goToNextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ECDC4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
