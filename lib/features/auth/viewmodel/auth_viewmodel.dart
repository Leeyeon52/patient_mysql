// C:\Users\sptzk\Desktop\t0703\lib\features\auth\viewmodel\auth_viewmodel.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/user.dart'; // User 모델 임포트

class AuthViewModel with ChangeNotifier {
  final String _baseUrl;
  User? _loggedInUser; // ✅ 로그인된 사용자 정보를 저장
  User? get loggedInUser => _loggedInUser; // ✅ 로그인된 사용자 정보 getter

  bool _isCheckingUserId = false;
  bool get isCheckingUserId => _isCheckingUserId;

  String? _duplicateCheckErrorMessage;
  String? get duplicateCheckErrorMessage => _duplicateCheckErrorMessage;

  AuthViewModel({required String baseUrl}) : _baseUrl = baseUrl;

  /// 아이디 중복 확인
  Future<bool?> checkUserIdDuplicate(String userId) async {
    _isCheckingUserId = true;
    _duplicateCheckErrorMessage = null;
    notifyListeners();

    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/check-username?username=$userId'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bool available = data['available'] == true;
        _duplicateCheckErrorMessage = available ? null : data['message'];
        return available;
      } else {
        final data = jsonDecode(res.body);
        _duplicateCheckErrorMessage = data['message'] ?? 'ID 중복검사 서버 응답 오류: StatusCode=${res.statusCode}';
        if (kDebugMode) {
          print('ID 중복검사 서버 응답 오류: StatusCode=${res.statusCode}, Body=${res.body}');
        }
        return null;
      }
    } catch (e) {
      _duplicateCheckErrorMessage = '네트워크 오류: 서버에 연결할 수 없습니다.';
      if (kDebugMode) {
        print('ID 중복검사 중 네트워크 오류: $e');
      }
      return null;
    } finally {
      _isCheckingUserId = false;
      notifyListeners();
    }
  }

  /// 사용자 회원가입
  Future<String?> registerUser(Map<String, String> userData) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (res.statusCode == 201) {
        return null; // 성공
      } else {
        final data = jsonDecode(res.body);
        return data['message'] ?? '알 수 없는 오류가 발생했습니다.';
      }
    } catch (e) {
      if (kDebugMode) {
        print('회원가입 중 네트워크 오류: $e');
      }
      return '서버와 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
    }
  }

  /// 사용자 로그인
  Future<User?> loginUser(String userId, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': userId, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        try {
          // ✅ 로그인 성공 시 _loggedInUser 업데이트
          _loggedInUser = User.fromJson(data); // 로그인 응답은 id와 username만 포함
          notifyListeners(); // 로그인 상태 변경 알림
          return _loggedInUser;
        } catch (e) {
          if (kDebugMode) {
            print('User model 파싱 오류: $e, 응답 데이터: $data');
          }
          throw '사용자 정보 파싱 중 오류가 발생했습니다. (앱 버전 업데이트 필요)';
        }
      } else {
        final data = jsonDecode(res.body);
        throw data['message']?.toString() ?? '알 수 없는 로그인 오류';
      }
    } catch (e) {
      if (kDebugMode) {
        print('로그인 중 네트워크 오류 또는 예외: $e');
      }
      if (e is String) {
        throw e;
      } else {
        throw e.toString();
      }
    }
  }

  /// 사용자 로그아웃
  void logoutUser() { // ✅ logoutUser 메서드 추가
    _loggedInUser = null; // ✅ 로그인된 사용자 정보 초기화
    notifyListeners(); // 로그아웃 상태 변경 알림
    if (kDebugMode) {
      print('User logged out.');
    }
  }

  /// 사용자 탈퇴
  Future<String?> deleteUser(String userId, String password) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/auth/delete_account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': userId, 'password': password}), // ✅ user_id 대신 username 사용
      );

      if (res.statusCode == 200) {
        logoutUser(); // 탈퇴 성공 시 로그아웃 처리
        return null;
      } else {
        final data = jsonDecode(res.body);
        return data['message'] ?? '회원 탈퇴 중 알 수 없는 오류가 발생했습니다.';
      }
    } catch (e) {
      if (kDebugMode) {
        print('회원 탈퇴 중 네트워크 오류: $e');
      }
      return '서버와 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
    }
  }
}
