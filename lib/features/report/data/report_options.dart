const issueTypes = [
  '건물이나 출입구를 구분하기 어려워요',
  '이동 방향(화살표)이 틀려요',
  '층 변경 안내가 부족해요',
  '사진·설명이 현장과 달라요',
  '기타',
];

const closureTypes = ['공사 중', '통로·출입구 폐쇄', '엘리베이터 고장', '미끄럽거나 위험해요', '기타'];

// Expected closure length: days from today (null = unknown) and label
const closureDurations = <(int?, String)>[
  (0, '오늘만'),
  (6, '이번 주'),
  (null, '잘 모르겠어요'),
];

const courseTags = [
  '짐 많을 때',
  '언덕 싫어',
  '빠른 길',
  '비 올 때 실내로',
  '엘리베이터 위주',
  '한적한 길',
];

const reportMemoMax = 1000;

// The date a closure ends (YYYY-MM-DD), or null when unknown
String? untilDate(int? days, {DateTime? now}) {
  if (days == null) return null;
  final d = (now ?? DateTime.now()).add(Duration(days: days));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
