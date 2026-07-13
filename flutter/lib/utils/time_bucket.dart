import '../models/link_item.dart';
import 'i18n.dart';

enum TimeBucket { today, yesterday, thisWeek, thisMonth, earlier }

TimeBucket bucketFor(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return TimeBucket.today;
  if (diff == 1) return TimeBucket.yesterday;
  if (diff <= 7) return TimeBucket.thisWeek;
  if (diff <= 30) return TimeBucket.thisMonth;
  return TimeBucket.earlier;
}

String bucketLabel(TimeBucket bucket) {
  switch (bucket) {
    case TimeBucket.today:
      return t('home.groupToday');
    case TimeBucket.yesterday:
      return t('home.groupYesterday');
    case TimeBucket.thisWeek:
      return t('home.groupThisWeek');
    case TimeBucket.thisMonth:
      return t('home.groupThisMonth');
    case TimeBucket.earlier:
      return t('home.groupEarlier');
  }
}

/// Groups [links] into an ordered map keyed by [TimeBucket], skipping
/// empty buckets. Iteration order follows [TimeBucket.values].
Map<TimeBucket, List<LinkItem>> groupByTimeBucket(List<LinkItem> links) {
  final grouped = <TimeBucket, List<LinkItem>>{};
  for (final link in links) {
    grouped.putIfAbsent(bucketFor(link.createdAt), () => []).add(link);
  }
  return grouped;
}
