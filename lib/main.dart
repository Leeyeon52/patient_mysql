// C:\Users\user\Desktop\0703flutter_v2\lib\main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform; // defaultTargetPlatform 임포트 유지

import 'app/router.dart';
import 'app/theme.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/mypage/viewmodel/userinfo_viewmodel.dart';
import 'features/chatbot/viewmodel/chatbot_viewmodel.dart';
import 'features/diagnosis/viewmodel/diagnosis_viewmodel.dart';

// ✅ 새로운 기능 ViewModel 임포트 추가 (경로 확인)
import 'features/history/viewmodel/history_viewmodel.dart';
import 'features/non_face_to_face/viewmodel/consultation_viewmodel.dart';
import 'features/nearby_clinics/viewmodel/clinic_viewmodel.dart';


void main() {
  // ✅ 중요: 아래 globalBaseUrl을 현재 Flutter 앱이 실행되는 환경에 맞게 정확히 설정해주세요.
  // 백엔드 서버(Node.js Express)는 'http://localhost:3000'에서 실행 중입니다.
  // Flutter 앱이 백엔드에 접근하려면, 앱이 실행되는 환경에서 'localhost:3000'에 어떻게 접근해야 하는지 알아야 합니다.

  final String globalBaseUrl;

  if (kIsWeb) {
    // 웹 환경 (Flutter 웹 앱을 브라우저에서 실행할 때)
    // 백엔드 서버가 실행 중인 컴퓨터의 localhost에 직접 접근
    globalBaseUrl = "http://127.0.0.1:3000/api";
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    // Android 에뮬레이터 환경
    // 에뮬레이터에서 컴퓨터의 localhost에 접근하려면 '10.0.2.2'를 사용합니다.
    globalBaseUrl = "http://10.0.2.2:3000/api";
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    // iOS 시뮬레이터 환경
    // 시뮬레이터는 컴퓨터의 localhost에 직접 접근할 수 있습니다.
    globalBaseUrl = "http://localhost:3000/api";
  } else {
    // 실제 Android/iOS 기기 또는 기타 데스크톱 플랫폼 환경
    // ✅ 이 부분을 현재 백엔드 서버가 실행 중인 컴퓨터의 실제 IP 주소로 변경해야 합니다.
    // 컴퓨터의 IP 주소 확인 방법:
    //   - Windows: 명령 프롬프트(CMD)에서 'ipconfig' 입력 후 'IPv4 주소' 확인 (예: 192.168.0.100)
    //   - macOS/Linux: 터미널에서 'ifconfig' 또는 'ip addr' 입력 후 활성 네트워크 인터페이스의 IP 주소 확인
    // 예시: globalBaseUrl = "http://192.168.0.100:3000/api";
    // 현재는 기본값으로 localhost를 설정했지만, 실제 기기에서는 작동하지 않을 것입니다.
    globalBaseUrl = "http://192.168.0.2:3000/api"; // <-- 제공해주신 IP 주소로 변경되었습니다!
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (context) => UserInfoViewModel()), // UserInfoViewModel에 baseUrl이 필요하다면 추가
        ChangeNotifierProvider(create: (context) => ChatbotViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (context) => DiagnosisViewModel(baseUrl: globalBaseUrl)),
        // ✅ 새로운 기능 ViewModel 추가
        ChangeNotifierProvider(create: (context) => HistoryViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (context) => ConsultationViewModel(baseUrl: globalBaseUrl)),
        ChangeNotifierProvider(create: (context) => ClinicViewModel(baseUrl: globalBaseUrl)),
      ],
      child: const MediToothApp(),
    ),
  );
}

class MediToothApp extends StatelessWidget {
  const MediToothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MediTooth',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
