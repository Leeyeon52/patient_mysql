// C:\Users\sptzk\Desktop\t0703\lib\features\auth\viewmodel\auth_viewmodel.dart

import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb을 위해 필요
import 'package:http/http.dart' as http;
import '../model/user.dart';

class AuthViewModel with ChangeNotifier {
  // ✅ 생성자를 통해 주입받도록 변경 (final 키워드 유지)
  final String _baseUrl;

  // ✅ 로딩 상태를 관리하는 변수
  bool _isCheckingUserId = false;
  bool get isCheckingUserId => _isCheckingUserId;

  // ✅ 아이디 중복 확인 관련 에러 메시지
  String? _duplicateCheckErrorMessage;
  String? get duplicateCheckErrorMessage => _duplicateCheckErrorMessage;

  // ✅ 생성자 추가: baseUrl을 필수 매개변수로 받습니다.
  AuthViewModel({required String baseUrl}) : _baseUrl = baseUrl;

  /// 아이디 중복 확인
  /// 반환값: true (사용 가능), false (중복), null (오류 발생)
  Future<bool?> checkUserIdDuplicate(String userId) async {
    _isCheckingUserId = true; // 로딩 시작
    _duplicateCheckErrorMessage = null; // 이전 에러 메시지 초기화
    notifyListeners(); // UI에 로딩 상태 반영

    try {
      // ✅ 백엔드 API 엔드포인트와 쿼리 파라미터 이름을 백엔드 예시와 일치시켰습니다.
      // 백엔드: /api/auth/check-username?username=...
      // 중요: 에뮬레이터 또는 실제 기기에서 테스트 시 _baseUrl을 적절히 설정해야 합니다.
      // - Android 에뮬레이터: 'http://10.0.2.2:3000/api'
      // - iOS 시뮬레이터: 'http://localhost:3000/api' 또는 'http://127.0.0.1:3000/api'
      // - 실제 기기: 'http://<당신의_컴퓨터_IP_주소>:3000/api'
      final res = await http.get(Uri.parse('$_baseUrl/auth/check-username?username=$userId'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bool available = data['available'] == true; // 백엔드 응답에 'available' 필드 사용
        _duplicateCheckErrorMessage = available ? null : data['message']; // 사용 가능하면 메시지 없음, 아니면 백엔드 메시지
        return available;
      } else {
        // 서버에서 200 OK가 아닌 다른 상태 코드를 보낸 경우
        final data = jsonDecode(res.body);
        _duplicateCheckErrorMessage = data['message'] ?? 'ID 중복검사 서버 응답 오류: StatusCode=${res.statusCode}';
        if (kDebugMode) {
          print('ID 중복검사 서버 응답 오류: StatusCode=${res.statusCode}, Body=${res.body}');
        }
        return null; // 오류 발생
      }
    } catch (e) {
      // 네트워크 연결 등 예외 발생 시
      _duplicateCheckErrorMessage = '네트워크 오류: 서버에 연결할 수 없습니다.';
      if (kDebugMode) {
        print('ID 중복검사 중 네트워크 오류: $e');
      }
      return null; // 오류 발생
    } finally {
      _isCheckingUserId = false; // 로딩 종료
      notifyListeners(); // UI에 로딩 상태 반영
    }
  }

  /// 사용자 회원가입
  /// 반환값: null (성공), String (오류 메시지)
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
        return data['message'] ?? '알 수 없는 오류가 발생했습니다.'; // 백엔드에서 보낸 오류 메시지 사용
      }
    } catch (e) {
      if (kDebugMode) {
        print('회원가입 중 네트워크 오류: $e');
      }
      return '서버와 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
    }
  }

  /// 사용자 로그인
  /// 반환값: User 객체 (로그인 성공), String (오류 메시지)
  Future<User?> loginUser(String userId, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': userId, 'password': password}), // 백엔드 필드명 'username'으로 변경
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // 백엔드 응답 구조에 따라 User 객체 생성 (예: data['user']가 아닌 data 자체에 사용자 정보가 있을 수 있음)
        // 백엔드 loginUser 컨트롤러가 { message: '로그인 성공', token, userId, username }을 반환하므로,
        // User.fromJson에 필요한 필드를 맞춰주거나 User 모델을 업데이트해야 합니다.
        // 현재 User 모델이 어떻게 정의되어 있는지에 따라 조정이 필요합니다.
        // 예시: User.fromJson({'id': data['userId'], 'username': data['username']});
        return User.fromJson(data); // 백엔드 응답을 직접 User.fromJson에 전달하거나 필요한 필드만 추출
      } else {
        final data = jsonDecode(res.body);
        throw data['message'] ?? '알 수 없는 로그인 오류'; // 백엔드에서 보낸 오류 메시지 사용
      }
    } catch (e) {
      if (kDebugMode) {
        print('로그인 중 네트워크 오류: $e');
      }
      if (e is String) {
        throw e;
      } else {
        throw '서버와 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
      }
    }
  }

  /// 사용자 탈퇴
  /// 반환값: null (성공), String (오류 메시지)
  Future<String?> deleteUser(String userId, String password) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/auth/delete_account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'password': password}),
      );

      if (res.statusCode == 200) {
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
