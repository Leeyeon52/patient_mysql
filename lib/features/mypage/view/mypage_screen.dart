// C:\Users\sptzk\Desktop\t0703\lib\features\mypage\view\mypage_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:t0703/features/auth/model/user.dart'; // ✅ User 모델 임포트 확인
import 'package:t0703/features/auth/viewmodel/auth_viewmodel.dart'; // AuthViewModel 임포트
import 'package:t0703/features/mypage/viewmodel/userinfo_viewmodel.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userInfoViewModel = Provider.of<UserInfoViewModel>(context, listen: false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      final loggedInUserId = authViewModel.loggedInUser?.id;

      if (loggedInUserId != null) {
        userInfoViewModel.fetchUserProfile(loggedInUserId);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
          _showSnack(context, '로그인이 필요합니다.');
        });
      }
    });
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final userInfoViewModel = context.read<UserInfoViewModel>();
    final authViewModel = context.read<AuthViewModel>();

    if (userInfoViewModel.user == null) {
      _showSnack(context, '로그인 정보가 없습니다.');
      return;
    }

    final passwordController = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            '회원 탈퇴',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '정말로 회원 탈퇴하시겠습니까?',
                style: TextStyle(fontSize: 15),
              ),
              const Text(
                '모든 데이터가 삭제되며 복구할 수 없습니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호를 다시 입력해주세요',
                  hintText: '비밀번호 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final userIdToDelete = userInfoViewModel.user!.username; // ✅ userId 대신 username 사용
                final password = passwordController.text;

                if (password.isEmpty) {
                  _showSnack(dialogContext, '비밀번호를 입력해주세요.');
                  return;
                }

                final error = await authViewModel.deleteUser(userIdToDelete, password);

                if (error == null) {
                  Navigator.of(dialogContext).pop(true);
                } else {
                  _showSnack(dialogContext, error);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('탈퇴', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      userInfoViewModel.clearUser();
      _showSnack(context, '회원 탈퇴가 완료되었습니다.');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoViewModel = context.watch<UserInfoViewModel>();
    final user = userInfoViewModel.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 30),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내 정보',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Divider(height: 20, thickness: 1),
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '이름: ${user?.name ?? '로그인 필요'}',
                          style: const TextStyle(fontSize: 17, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.email, color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '아이디: ${user?.username ?? '로그인 필요'}', // ✅ userId 대신 username 사용
                          style: const TextStyle(fontSize: 17, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.male, color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '성별: ${user?.gender ?? '정보 없음'}',
                          style: const TextStyle(fontSize: 17, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.cake, color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '생년월일: ${user?.birth ?? '정보 없음'}',
                          style: const TextStyle(fontSize: 17, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '전화번호: ${user?.phone ?? '정보 없음'}',
                          style: const TextStyle(fontSize: 17, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.home, color: Colors.grey, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          '주소: ${user?.address ?? '정보 없음'}',
                          style: const TextStyle(fontSize: 17, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Text(
              '계정 설정',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go('/mypage/edit');
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  '개인정보 수정',
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final authViewModel = context.read<AuthViewModel>();
                  authViewModel.logoutUser();
                  userInfoViewModel.clearUser();
                  _showSnack(context, '로그아웃 되었습니다.');
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.black87),
                label: const Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 17, color: Colors.black87),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmationDialog(context),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  '회원탈퇴',
                  style: TextStyle(fontSize: 17, color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
