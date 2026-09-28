import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers.dart';

/// 모델명 정규화 — car_image_map.csv의 pattern과 같은 규칙
/// (소문자 + 특수문자 제거)으로 부분 일치시킨다.
String _normName(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');

/// 사진 패턴 ↔ 모델명 매칭.
///
/// - 한글 패턴: 정규화 문자열 부분 일치 (한글 모델명은 토큰이 안 갈려서 OK)
/// - 라틴/숫자 패턴(a4, x5, i4…): 토큰 단위 매칭 — 부분 문자열로 걸면
///   'Arteon 2.0TDI 4Motion'(i4 오탐), 'MASADA 4밴'(a4), 'DBX707'(x7),
///   'Cadillac Escalade'(es) 같은 오매칭이 생긴다.
///   토큰이 패턴과 같거나, 패턴+나머지에서 나머지가 숫자 시작/3자 이하
///   트림 꼬리표면 일치로 본다 (rx450h→rx, gle53→gle, s90b5→s90).
bool _photoMatch(String pattern, String rawName) {
  if (pattern.isEmpty) return false;
  if (RegExp(r'[가-힣]').hasMatch(pattern)) {
    return _normName(rawName).contains(pattern);
  }
  final tokens = rawName
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9가-힣]+'))
      .where((t) => t.isNotEmpty)
      .toList();
  // 'Model Y'→['model','y'], 'CR-V'→['cr','v'] 같이 끊긴 이름은
  // 인접 토큰 결합 후보도 만든다 (최대 3토큰까지).
  final candidates = <String>[
    for (var i = 0; i < tokens.length; i++)
      for (var j = i + 1; j <= tokens.length && j <= i + 3; j++)
        tokens.sublist(i, j).join(),
  ];
  for (final t in candidates) {
    if (t == pattern) return true;
    if (!t.startsWith(pattern)) continue;
    final rest = t.substring(pattern.length);
    if (rest.isEmpty) return true;
    final digitEnd = RegExp(r'[0-9]$').hasMatch(pattern);
    if (digitEnd) {
      // 'x5'→'x5m', 's90'→'s90b5' 같은 짧은 트림 꼬리표만 허용.
      // 'a4'→'a45'(숫자 시작=다른 모델)는 거절.
      if (RegExp(r'^[a-z]').hasMatch(rest) && rest.length <= 2) {
        return true;
      }
    } else {
      // 'rx'→'rx450h', 'gle'→'gle53'(숫자 시작 꼬리표)는 허용.
      // 'es'→'esv', 'es'→'escalade' 같은 글자 꼬리표는
      // 3글자 이상 패턴 + 3자 이하 꼬리표일 때만 허용.
      if (RegExp(r'^[0-9]').hasMatch(rest)) return true;
      if (pattern.length >= 3 &&
          rest.length <= 3 &&
          !RegExp(r'[0-9]').hasMatch(rest)) {
        return true;
      }
    }
  }
  return false;
}

/// 차종 → 실사/실루엣 이미지 에셋 매핑.
/// [photos](car_image_map.csv)에 모델명과 겹치는 패턴이 있으면
/// 실제 차량 사진을 우선 사용하고, 없으면 차종 실루엣으로 폴백한다.
/// [vehicleType] = CSV 차종 열(승용차/화물차/승합차…),
/// [fuelType] = CSV 유형 열(일반형/다목적형/밴형/화물…).
String carImageAsset(String vehicleType, String modelName,
    {String fuelType = '', Map<String, String>? photos}) {
  final n = _normName(modelName);
  if (photos != null) {
    String? best;
    var bestLen = 0;
    for (final e in photos.entries) {
      if (_photoMatch(e.key, modelName) && e.key.length > bestLen) {
        best = e.value;
        bestLen = e.key.length;
      }
    }
    if (best != null) return best;
  }
  const vans = [
    '카니발', '스타리아', '스타렉스', '카운티', '시에나', '마이티',
    '파비스', 'v클래스', '트라픽', '마스터', '일렉트릭버스',
  ];
  const trucks = ['포터', '봉고', '트럭', '쓰리축', '타스만', '렉스턴스포츠', '무쏘', '콜로라도', '레인저', '글래디에이터', 'f-150', 'hilux', '하이럭스', '픽업', '덤프'];
  // vehicleType이 없을 때(프로필 저장본) 이름으로 짐작하는 SUV/크로스오버 키워드
  const suvs = [
    '쏘렌토', '싼타페', '투싼', '스포티지', '코나', '셀토스', '팰리세이드',
    '모하비', '니로', '베뉴', '캐스퍼', '티볼리', '토레스', '코란도',
    '렉스턴', '액티언', '트랙스', '트레일블레이저', '이쿼녹스', '트래버스',
    '캡티바', '윈스톰', '콜레오스', '캡처', '아르카나', 'gv', 'qm', 'xm',
    '타호', '에스컬레이드', '익스플로러', '랭글러', '체로키', '컴패스',
    '레니게이드', '디펜더', '레인지로버', '디스커버리', '이보크', '벨라',
    '티구안', '투아렉', '티록', 'x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7',
    'gla', 'glb', 'glc', 'gle', 'gls', 'q2', 'q3', 'q5', 'q7', 'q8',
    'rav4', '하이랜더', '랜드크루저', 'cx-', 'xc40', 'xc60', 'xc90',
    'cr-v', '파일럿', '패스파인더', '무라노', 'ux', 'nx', 'rx', 'gx', 'lx',
    '우루스', '벤테이가', '컬리넌', 'dbx', 'e-pace', 'f-pace', 'macan',
    '마칸', '카이엔', '스텔비오', '토날레', '브롱코', '익스페디션',
    '이네오스', '그레나디어', '르반떼', '그레칼레', '스토닉', '아이오닉9',
    'ev9', 'k9', '아이오닉5', 'ioniq5',
  ];
  if (trucks.any(n.contains)) return 'assets/cars/truck.png';
  if (vans.any(modelName.contains)) return 'assets/cars/van.png';
  if (suvs.any(n.contains)) return 'assets/cars/suv.png';
  // 차종(vehicleType): 승용차/화물차/승합차/특수차…
  // 유형(fuelType): 일반형/다목적형/밴형/화물/승합/덤프형/승용겸화물형…
  const truckTypes = ['화물차', '화물', '덤프형', '승용겸화물형', '특수차', '견인차'];
  const vanTypes = ['승합차', '승합', '밴형'];
  if (truckTypes.contains(vehicleType) || truckTypes.contains(fuelType)) {
    return 'assets/cars/truck.png';
  }
  if (vanTypes.contains(vehicleType) || vanTypes.contains(fuelType)) {
    return 'assets/cars/van.png';
  }
  if (fuelType == '다목적형') return 'assets/cars/suv.png';
  return 'assets/cars/sedan.png';
}

/// 실사 에셋(assets/cars/real/)이 선택됐는지 — 출처 표기용.
bool carImageIsPhoto(String asset) => asset.startsWith('assets/cars/real/');

/// 선택된 차량의 이미지 — 실사(있으면) 또는 골드 실루엣 폴백.
class CarImage extends ConsumerWidget {
  const CarImage({
    super.key,
    required this.vehicleType,
    this.fuelType = '',
    required this.modelName,
    this.height = 96,
    this.width,
  });

  final String vehicleType;
  final String fuelType;
  final String modelName;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(carPhotoMapProvider).value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        carImageAsset(vehicleType, modelName,
            fuelType: fuelType, photos: photos),
        height: height,
        width: width,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => Container(
          height: height,
          width: width,
          color: AppColors.ink,
          alignment: Alignment.center,
          child: Icon(Icons.directions_car,
              size: 40, color: Colors.white.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
