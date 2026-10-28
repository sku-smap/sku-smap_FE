import '../../campus/data/campus_models.dart';

enum LocateError {
  unavailable('위치를 찾지 못했어요. 실내라면 검색이나 지도에서 골라주세요.'),
  outside('지금 학교 밖이에요. 학교에 오면 쓸 수 있어요 — 정문에서 출발하려면 아래에서 ‘정문’을 고르세요.');

  const LocateError(this.message);

  final String message;
}

typedef LocateResult = ({CampusPlace? spot, LocateError? error});

// Device location mapped to the nearest 360 spot
abstract interface class LocationService {
  Future<LocateResult> locate();
}
