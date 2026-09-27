import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 차종 → 실루엣 이미지 에셋 매핑.
/// [vehicleType] = CSV 차종 열(승용차/화물차/승합차…),
/// [fuelType] = CSV 유형 열(일반형/다목적형/밴형/화물…).
/// 이름 키워드가 차종 분류보다 우선한다.
String carImageAsset(String vehicleType, String modelName,
    {String fuelType = ''}) {
  const vans = [
    '카니발', '스타리아', '스타렉스', '카운티', '시에나', '마이티',
    '파비스', 'v클래스', 'v클래스', '트라픽', '마스터', '일렉트릭버스',
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
  final n = modelName.toLowerCase();
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

/// 선택된 차량의 실루엣 카드 이미지 — 골드 실루엣 + 잉크 배경.
/// 이미지 전체가 잉크색이므로 위젯 자체에 배경이 필요 없다.
class CarImage extends StatelessWidget {
  const CarImage({
    super.key,
    required this.vehicleType,
    this.fuelType = '',
    required this.modelName,
    this.height = 96,
  });

  final String vehicleType;
  final String fuelType;
  final String modelName;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        carImageAsset(vehicleType, modelName, fuelType: fuelType),
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => Container(
          height: height,
          color: AppColors.ink,
          alignment: Alignment.center,
          child: Icon(Icons.directions_car,
              size: 40, color: Colors.white.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
