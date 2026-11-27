# My.solved
보다 편한 PS/CP를 위한 애플리케이션입니다.

새로운 모습으로 찾아온 2.0.0 버전이 플레이스토어와 앱스토어, 웹을 통해 배포 중입니다.

- AOS: https://play.google.com/store/apps/details?id=com.w8385.my_solved   
- iOS: https://apps.apple.com/kr/app/my-solved/id6444540009
- Web: ﻿https://my-solved.github.io/
     

## 기능
- 나의 solved.ac 프로필을 확인할 수 있습니다.
- solved.ac의 검색 기능을 사용할 수 있습니다.
- 스트릭 알림을 받을 수 있습니다.
- 대회 목록을 확인하고, 알림을 설정할 수 있습니다.

## 스크린샷
### 홈
<table>
<th> 프로필 상단 </th>
<th> 프로필 하단 </th>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/2783e442-c7af-4927-8f24-bc37d5d66c09" width="300"></td>
    <td><img src="https://github.com/user-attachments/assets/5871e076-783a-4ca6-97c0-8f5a379ec156" width="300"></td>
  </tr>
</table>

### 검색
<table>
<th> 문제 검색 </th>
<th> 문제 필터 </th>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/9771a5ef-f8cd-450c-b0ae-3e015a29ed77" width="300"></td>
    <td><img src="https://github.com/user-attachments/assets/4461dc40-c31c-44f1-9c8e-cac7bb9860fe" width="300"></td>
  </tr>
</table>

### 대회
<table>
<th> 대회 목록 </th>
<th> 대회 필터 </th>
<tr>
   <td>
   <img src="https://github.com/user-attachments/assets/6ebb75e3-fdbd-4bee-bc1e-54bbeb6bcbfd" width="300">
   </td>
   <td>
   <img src="https://github.com/user-attachments/assets/81b858dc-12b0-43ac-a0fa-4ad13bf4324a" width="300">
   </td>
</tr>
</table>

## 개선점
- ﻿﻿UI 변경
- ﻿로딩속도 최적화
- ﻿백준 대회 뱃지/배경 조건 표시 (@kiwiyou 님의 [baechu](https://github.com/kiwiyou/baechu) 연동)
﻿

## 추가될 기능
- 리팩터링 진행 과정에서 누락된 일부 요소들을 추가할 예정입니다.
  - 오늘의 스트릭 여부
  - 스트릭 그래프
  - 뱃지 표시
  - 태그/푼 문제 그래프

## 개발 설정

공식 solved.ac v4 API는 앱 시크릿을 요구하므로 Flutter에서 직접 호출하지
않습니다. 공개 활성화 모드와 gateway 주소만 compile-time define으로
전달할 수 있습니다.

```sh
flutter run \
  --dart-define=SOLVED_API_MODE=official-v4 \
  --dart-define=SOLVED_API_V4_PROXY_BASE_URI=https://api.example.com/solved/v4/
```

- 두 값을 모두 생략하면 기본 `legacy-v3` 모드로 현재 v3 런타임 동작을
  그대로 유지합니다.
- `official-v4` 모드는 gateway 주소가 필수이며, `legacy-v3` 모드는 gateway
  주소를 거부합니다. `official-v4` 전환은 두 define을 함께 전달해야 하며,
  mode와 주소가 어긋나면 앱 구성 단계에서 실패합니다.
- debug가 아닌 빌드는 HTTPS와 정확한 `/solved/v4/` 경로만 허용합니다.
- debug 빌드에서는 로컬 개발을 위해 loopback HTTP 주소도 허용합니다.
- Flutter는 `x-client-id`나 `x-client-secret` upstream header를 보내지 않으며,
  proxy가 두 header를 주입합니다. client secret은 `solved-proxy` runtime
  secret으로만 관리하고, 공개 client ID 값만 아래 OAuth authorization
  define으로 사용할 수 있습니다.

OAuth 로그인 계약을 로컬에서 구성하려면 위의 `official-v4` 설정에 공개
client ID와 solved.ac 개발자 콘솔에 등록한 redirect URI를 함께 추가합니다.

```sh
flutter run \
  --dart-define=SOLVED_API_MODE=official-v4 \
  --dart-define=SOLVED_API_V4_PROXY_BASE_URI=https://api.example.com/solved/v4/ \
  --dart-define=SOLVED_OAUTH_CLIENT_ID=public-client-id \
  --dart-define=SOLVED_OAUTH_REDIRECT_URI=https://app.example.com/oauth/callback
```

- OAuth define 두 개를 모두 생략하면 로그인 계약은 비활성 상태입니다.
- 둘 중 하나만 전달하거나 `official-v4` gateway 없이 전달하면 앱 구성
  단계에서 실패합니다.
- client ID와 redirect URI는 공개 프로토콜 값입니다. client secret은 OAuth
  설정에도 추가하지 않습니다.
- 현재 기본 요청 scope는 `profile`뿐이며 refresh token 저장을 결정하기 전에는
  `offline.access`를 기본 요청하지 않습니다.
 

## 영감을 주신 분들
@shiftpsh for [solved.ac](https://solved.ac/).    
@RanolP
for [solved.ac unofficial-documentation](https://solvedac.github.io/unofficial-documentation/#/)
.    
@mazassumnida for [mazandi](https://github.com/mazassumnida/mazandi).    
@utilForever for CI.    
@kiwiyou for [baechu](https://github.com/kiwiyou/baechu).
