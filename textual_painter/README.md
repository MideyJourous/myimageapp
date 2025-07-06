# Textual Painter

AI 기반 이미지 생성 앱입니다. 다양한 테마 카드를 선택하여 고품질 이미지를 생성할 수 있습니다.

## 🚀 시작하기

### 필수 환경 변수 설정

1. 프로젝트 루트에 `.env` 파일을 생성하세요:

```bash
# TheHive AI API Key (필수)
THEHIVE_API_KEY=your_thehive_api_key_here

# Google Translate API Key (선택사항)
GOOGLE_API_KEY=your_google_api_key_here
```

2. TheHive AI API 키를 발급받으세요:
   - [TheHive AI](https://thehive.ai)에서 계정을 생성
   - API 키를 발급받아 `.env` 파일에 추가

### 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 🧪 테스트

```bash
# 모든 테스트 실행
flutter test

# 코드 분석
flutter analyze
```

## 📱 주요 기능

- **테마 카드 선택**: 미리 정의된 스타일로 이미지 생성
- **프롬프트 자동 설정**: 카드 선택 시 해당 스타일이 자동으로 적용
- **사용자 정의 입력**: 400자 이내의 추가 설명 입력 가능
- **이미지 저장**: 생성된 이미지를 갤러리에 저장
- **Pro 구독**: 무제한 이미지 생성 (테스트 모드)

## 🔧 기술 스택

- **Flutter**: 크로스 플랫폼 앱 개발
- **Provider**: 상태 관리
- **TheHive AI**: 이미지 생성 API
- **SharedPreferences**: 로컬 데이터 저장
- **Image Gallery Saver**: 갤러리 저장

## 🐛 알려진 문제점

### 해결된 문제들 ✅
- [x] TextEditingController 메모리 누수 방지
- [x] 에러 처리 개선 (타임아웃, 네트워크 오류)
- [x] API 키 검증 로직 강화
- [x] 기본 테스트 코드 추가

### 개선 권장사항 🔄
- [ ] 더 많은 단위 테스트 추가
- [ ] 오프라인 모드 지원
- [ ] 이미지 캐싱 전략 구현
- [ ] 성능 최적화

## 📊 테스트 결과

### 기본 기능 테스트 ✅
- 앱 시작 및 초기화
- Provider 상태 관리
- 테마 카드 로딩
- 기본 위젯 렌더링

### 에러 처리 테스트 ✅
- API 키 누락 시 적절한 에러 메시지
- 네트워크 타임아웃 처리 (60초)
- 서버 오류 응답 처리
- 빈 프롬프트 검증

### 코드 품질 ✅
- Flutter analyze 통과
- 의존성 충돌 없음
- 메모리 누수 방지

## 🚨 중요 사항

1. **API 키 보안**: `.env` 파일을 절대 Git에 커밋하지 마세요
2. **테스트 모드**: 현재 Pro 기능은 테스트 모드로 작동합니다
3. **이미지 제한**: 무료 사용자는 하루 3개, Pro는 100개까지 생성 가능

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. `.env` 파일이 올바르게 설정되었는지
2. 인터넷 연결 상태
3. API 키의 유효성
