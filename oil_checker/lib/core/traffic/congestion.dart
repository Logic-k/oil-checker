/// 교통 혼잡도 모델 — 요일·시간대별 예상 혼잡 가중치
///
/// OSRM의 기본 duration은 도로 제한속도 기반 "원활" 상태 시간이다.
/// 여기에 시간대별 혼잡 가중치를 곱해 실제 예상 도착 시간을 근사한다.
///
/// 근거 (한국 도시부 일반도로 혼잡 패턴):
/// - 출퇴근 시간대(오전 7-9시, 오후 18-20시): 가장 혼잡 → 1.5배
/// - 주간(09-18시): 평시보다 다소 혼잡 → 1.2배
/// - 심야(20-07시) / 주말: 원활 → 1.0배
enum CongestionLevel {
  /// 원활 — 심야·주말
  smooth,

  /// 보통 — 주간 평시
  moderate,

  /// 혼잡 — 출퇴근 시간대
  heavy,
}

/// 시간대별 혼잡 가중치.
///
/// [time] 기준으로 [CongestionLevel]과 예상 시간 배수를 반환한다.
class CongestionModel {
  const CongestionModel({
    this.rushHourFactor = 1.5,
    this.daytimeFactor = 1.2,
  });

  /// 출퇴근 시간대 배수 (기본 1.5배)
  final double rushHourFactor;

  /// 주간 평시 배수 (기본 1.2배)
  final double daytimeFactor;

  /// 주어진 시각의 혼잡 단계
  CongestionLevel levelAt(DateTime time) {
    // 주말(토·일)은 출퇴근 혼잡이 없음
    if (time.weekday == DateTime.saturday ||
        time.weekday == DateTime.sunday) {
      return CongestionLevel.smooth;
    }
    final hour = time.hour;
    // 출퇴근: 오전 7-9시, 오후 18-20시
    if ((hour >= 7 && hour < 9) || (hour >= 18 && hour < 20)) {
      return CongestionLevel.heavy;
    }
    // 주간: 오전 9시 - 오후 18시
    if (hour >= 9 && hour < 18) {
      return CongestionLevel.moderate;
    }
    // 심야: 20시 - 07시
    return CongestionLevel.smooth;
  }

  /// 주어진 시각의 예상 시간 배수 (혼잡 가중치)
  double factorAt(DateTime time) {
    return switch (levelAt(time)) {
      CongestionLevel.heavy => rushHourFactor,
      CongestionLevel.moderate => daytimeFactor,
      CongestionLevel.smooth => 1.0,
    };
  }

  /// 혼잡 단계의 한글 라벨
  static String labelOf(CongestionLevel level) {
    return switch (level) {
      CongestionLevel.smooth => '원활',
      CongestionLevel.moderate => '보통',
      CongestionLevel.heavy => '혼잡',
    };
  }
}
