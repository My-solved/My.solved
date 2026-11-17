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
않습니다. 공개 gateway 주소만 compile-time define으로 전달할 수 있습니다.

```sh
flutter run \
  --dart-define=SOLVED_API_V4_PROXY_BASE_URI=https://api.example.com/solved/v4/
```

- 값을 생략하면 현재 v3 런타임 동작을 그대로 유지합니다.
- debug가 아닌 빌드는 HTTPS와 정확한 `/solved/v4/` 경로만 허용합니다.
- debug 빌드에서는 로컬 개발을 위해 loopback HTTP 주소도 허용합니다.
- `x-client-id`, `x-client-secret` 등 solved.ac 자격 증명은 Flutter define이나
  저장소에 넣지 않고 `solved-proxy` runtime secret으로만 관리합니다.
 

## 영감을 주신 분들
@shiftpsh for [solved.ac](https://solved.ac/).    
@RanolP
for [solved.ac unofficial-documentation](https://solvedac.github.io/unofficial-documentation/#/)
.    
@mazassumnida for [mazandi](https://github.com/mazassumnida/mazandi).    
@utilForever for CI.    
@kiwiyou for [baechu](https://github.com/kiwiyou/baechu).
