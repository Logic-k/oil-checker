import 'package:oil_checker/core/theme/app_theme.dart';
import 'package:oil_checker/domain/economy/economy_ranking.dart';

/// 절약액이 무엇과 비교한 값인지 화면마다 같은 말로 보여주기 위한 문구 모음.
///
/// 숫자만 크게 보여주고 가정을 숨기면 과장처럼 읽힌다. 비교 기준(주변 시세 /
/// 가장 가까운 곳)과 1회 주유량을 항상 함께 적는다.

/// 리터 표기 — 정수면 '40', 아니면 소수 한 자리 '37.5'
String formatLiters(double liters) {
  final rounded = (liters * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
}

/// 홈 시트 헤더용 — '주변 시세 1,878원 기준'
String savingsBasisShort(EconomyRankingResult r) =>
    r.baselineKind == SavingsBaseline.nearest
        ? '가장 가까운 곳 ${formatWon(r.baselinePrice)}원 기준'
        : '주변 시세 ${formatWon(r.baselinePrice)}원 기준';

/// 히어로 캡션용 — '주변 시세(1,878원) 대비'
String savingsBasisVs(EconomyRankingResult r) =>
    r.baselineKind == SavingsBaseline.nearest
        ? '가장 가까운 곳(${formatWon(r.baselinePrice)}원) 대비'
        : '주변 시세(${formatWon(r.baselinePrice)}원) 대비';

/// 주유량 문구 — '1회 40L' / '최근 주유 평균 37.5L'
String fillUpPhrase(EconomyRankingResult r) =>
    r.fillUpBasis == FillUpBasis.recentHistory
        ? '최근 주유 평균 ${formatLiters(r.fillUpLiters)}L'
        : '1회 ${formatLiters(r.fillUpLiters)}L';

/// 절약할 곳이 없을 때 — '주변 시세보다 더 아끼기는 어려워요'
String noSavingsMessage(EconomyRankingResult r) =>
    r.baselineKind == SavingsBaseline.nearest
        ? '가장 가까운 곳보다 더 아끼기는 어려워요'
        : '주변 시세보다 더 아끼기는 어려워요';

/// 계산 방식 각주 — 시세의 정의와 우회비용의 정의
String savingsFootnote(EconomyRankingResult r) {
  final basis = r.baselineKind == SavingsBaseline.nearest
      ? '가장 가까운 주유소 가격과 비교했어요.'
      : '주변 시세는 반경 5km ${r.stationCount}곳 가격의 중앙값이에요.';
  return '$basis 우회비용은 가장 가까운 곳에 다녀올 때보다 더 드는 연료·시간 비용이에요.';
}
