import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// RevenueCat 활성화 플래그 - 테스트 버전 출시 시 false로 설정
const bool _enableRevenueCat = false; // 테스트 버전 출시 시 false, 실제 연동 시 true로 변경

class UserService {
  static const String _userIdKey = 'user_id';
  static const String _proUserKey = 'is_pro_user'; // 로컬 저장용
  // RevenueCat Public API Key - Google Play Store용
  static const String _revenueCatApiKey = 'goog_QtedLHnMwAYbMfuTRbXYAzdMPas';

  Future<void> initialize() async {
    if (!_enableRevenueCat) {
      debugPrint('RevenueCat 기능이 비활성화되었습니다. 테스트 모드로 작동합니다.');
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(_revenueCatApiKey));

      final String? userId = await _getUserId();
      if (userId != null) {
        await Purchases.logIn(userId);
      }
    } on PlatformException catch (e) {
      debugPrint('RevenueCat 초기화 오류: ${e.message}');
    }
  }

  // 사용자 ID 가져오기 또는 생성
  Future<String> _getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId == null) {
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_userIdKey, userId);
    }

    return userId;
  }

  // 현재 사용자 ID 가져오기
  Future<String> getCurrentUserId() async {
    return await _getOrCreateUserId();
  }

  // RevenueCat과 구매 정보 동기화
  Future<void> _syncPurchaserInfo() async {
    if (!_enableRevenueCat) return;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      debugPrint('구매 정보 동기화 완료: ${customerInfo.activeSubscriptions}');
    } catch (e) {
      debugPrint('구매 정보 동기화 실패: $e');
    }
  }

  // Pro 구독 상태 확인
  Future<bool> isProUser() async {
    if (!_enableRevenueCat) {
      // 개발 모드에서는 로컬 설정 사용
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_proUserKey) ?? false; // 테스트 버전에서는 무료 사용자로 시작
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      // 'pro' 엔타이틀먼트 확인 (RevenueCat 대시보드에서 설정한 이름과 일치해야 함)
      return customerInfo.entitlements.active.containsKey('pro');
    } catch (e) {
      debugPrint('Pro 상태 확인 실패: $e');
      return false;
    }
  }

  // 구독 상품 목록 가져오기
  Future<List<Package>> getSubscriptionPackages() async {
    if (!_enableRevenueCat) {
      // 개발 모드에서는 빈 리스트 반환
      return [];
    }

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      debugPrint('구독 상품 목록 가져오기 실패: $e');
      return [];
    }
  }

  // 구독 구매 처리
  Future<bool> purchasePackage(Package package) async {
    if (!_enableRevenueCat) {
      // 개발 모드에서는 구매 성공으로 처리하고 로컬에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_proUserKey, true);
      return true;
    }

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.active.containsKey('pro');
    } catch (e) {
      debugPrint('구독 구매 실패: $e');
      return false;
    }
  }

  // 복원 구매
  Future<bool> restorePurchases() async {
    if (!_enableRevenueCat) {
      // 개발 모드에서는 현재 상태 반환
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_proUserKey) ?? false;
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.containsKey('pro');
    } catch (e) {
      debugPrint('구매 복원 실패: $e');
      return false;
    }
  }

  // 테스트용: Pro 상태 토글 (개발 모드에서만 사용)
  Future<bool> toggleProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStatus = prefs.getBool(_proUserKey) ?? false;
    final newStatus = !currentStatus;
    await prefs.setBool(_proUserKey, newStatus);
    return newStatus;
  }

  // 랜덤 문자열 생성 (사용자 ID 생성에 사용)
  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(List.generate(
        length,
        (index) => chars.codeUnitAt(
            (DateTime.now().millisecondsSinceEpoch + index) % chars.length)));
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
}
