import 'package:flutter_test/flutter_test.dart';
import 'package:rota/features/profile/data/user_profile.dart';

void main() {
  test('AccountType.parse bilinmeyen değerde bireysel döner', () {
    expect(AccountType.parse('business'), AccountType.business);
    expect(AccountType.parse('individual'), AccountType.individual);
    expect(AccountType.parse(null), AccountType.individual);
    expect(AccountType.parse('x'), AccountType.individual);
  });

  test('publicName kurumsalda işletme adını kullanır', () {
    const biz = UserProfile(
      uid: 'u',
      displayName: 'Ayşe',
      accountType: AccountType.business,
      businessName: 'Kahve Atölyesi',
    );
    expect(biz.publicName, 'Kahve Atölyesi');
    const person = UserProfile(uid: 'u', displayName: 'Ayşe');
    expect(person.publicName, 'Ayşe');
  });
}
