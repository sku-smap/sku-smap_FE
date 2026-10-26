import 'campus_models.dart';

const quickPlaces = [
  (label: '본관', place: CampusPlace(id: 'b-bonkwan', name: '본관')),
  (label: '골프장', place: CampusPlace(id: 'r-yudam-303', name: '스크린골프 (303호)')),
  (label: '수인관', place: CampusPlace(id: 'b-suin', name: '수인관')),
  (label: '청운관', place: CampusPlace(id: 'b-chungwoon', name: '청운관')),
];

const demoClosures = [
  Closure(place: '본관 오르막 2갈래', type: '엘리베이터 고장', until: '10/12'),
  Closure(place: '북악관 지하1층 중앙', type: '공사 중'),
];

const undergroundLinkNote =
    '지하 제1주차장은 본관·북악관·한림관·문예관·대일관·상승관·청운관·혜인관·은주1·2관과 이어져요.';
