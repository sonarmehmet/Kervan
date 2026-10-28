import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/moderation/data/report_repository.dart';

void main() {
  test('şikâyet nedenleri firestore.rules ile aynı kimlikleri kullanır', () {
    final ids = ReportReason.values.map((r) => r.id).toSet();
    expect(ids, <String>{'spam', 'harassment', 'unsafe', 'fake', 'other'});
  });

  test('şikâyet hedef türleri firestore.rules ile aynı', () {
    final ids = ReportTargetType.values.map((t) => t.id).toSet();
    expect(ids, <String>{'event', 'user', 'group'});
  });
}
