// C:\Users\sptzk\Desktop\t0703\lib\features\mypage\viewmodel\userinfo_viewmodel.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:t0703/features/auth/model/user.dart'; // User 모델 임포트

class UserInfoViewModel with ChangeNotifier {
  User? _user; // 현재 로그인된 사용자의 상세 프로필 정보
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final String _baseUrl;

  UserInfoViewModel({String baseUrl = "http://192.168.0.2:3000/api"}) : _baseUrl = baseUrl; // 기본값 설정 또는 main.dart에서 주입

  /// 사용자 프로필 정보 가져오기
  Future<void> fetchUserProfile(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ 백엔드 API 엔드포인트에 맞게 수정
      // 예시: GET /api/users/{id}
      final res = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_JWT_TOKEN', // ✅ 인증 토큰이 필요하다면 추가
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // 백엔드에서 반환하는 모든 사용자 정보를 User 모델에 맞게 파싱
        _user = User.fromJson(data); // User 모델이 모든 필드를 포함하도록 수정되어야 함
      } else {
        final data = jsonDecode(res.body);
        _errorMessage = data['message'] ?? '프로필 정보를 가져오는 데 실패했습니다.';
        if (kDebugMode) {
          print('프로필 가져오기 서버 응답 오류: StatusCode=${res.statusCode}, Body=${res.body}');
        }
      }
    } catch (e) {
      _errorMessage = '네트워크 오류: 서버에 연결할 수 없습니다.';
      if (kDebugMode) {
        print('프로필 가져오기 중 네트워크 오류: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자 프로필 정보 업데이트
  Future<String?> updateUserProfile(int userId, Map<String, dynamic> updatedData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ 백엔드 API 엔드포인트에 맞게 수정
      // 예시: PUT /api/users/{id}
      final res = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_JWT_TOKEN', // ✅ 인증 토큰이 필요하다면 추가
        },
        body: jsonEncode(updatedData),
      );

      if (res.statusCode == 200) {
        // 업데이트 성공 후 프로필 정보를 다시 가져오거나 로컬에서 업데이트
        await fetchUserProfile(userId); // 업데이트된 정보 다시 로드
        return null; // 성공
      } else {
        final data = jsonDecode(res.body);
        _errorMessage = data['message'] ?? '프로필 업데이트에 실패했습니다.';
        if (kDebugMode) {
          print('프로필 업데이트 서버 응답 오류: StatusCode=${res.statusCode}, Body=${res.body}');
        }
        return _errorMessage;
      }
    } catch (e) {
      _errorMessage = '네트워크 오류: 서버에 연결할 수 없습니다.';
      if (kDebugMode) {
        print('프로필 업데이트 중 네트워크 오류: $e');
      }
      return _errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사용자 정보 초기화 (로그아웃 시 등)
  void clearUser() {
    _user = null;
    notifyListeners();
    if (kDebugMode) {
      print('User info cleared.');
    }
  }

  /// ✅ User 객체를 직접 설정하는 메서드 추가 (로그인 시 사용)
  void loadUser(User user) {
    _user = user;
    notifyListeners();
    if (kDebugMode) {
      print('User info loaded into UserInfoViewModel: ${user.username}');
    }
  }
}
