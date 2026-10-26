import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rota/core/theme/app_theme.dart';
import 'package:rota/features/authentication/data/auth_repository.dart';
import 'package:rota/features/authentication/presentation/login_screen.dart';
import 'package:rota/features/authentication/presentation/register_screen.dart';
import 'package:rota/features/event_details/data/event.dart';
import 'package:rota/features/event_discovery/presentation/event_card.dart';

class _FakeAuth implements AuthRepository {
  final List<String> signInCalls = <String>[];
  final List<String> registerCalls = <String>[];

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls.add('$email|$password');
  }

  @override
  Future<void> register({required String email, required String password}) async {
    registerCalls.add('$email|$password');
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<bool> refreshEmailVerified() async => false;

  @override
  Future<void> signOut() async {}
}

Event _event({
  int capacity = 5,
  int accepted = 0,
  EventStatus status = EventStatus.active,
  Duration startsIn = const Duration(days: 2),
}) {
  return Event(
    id: 'e1',
    ownerId: 'owner',
    ownerName: 'Sahip',
    title: 'Sabah koşusu',
    description: 'Birlikte koşalım',
    category: 'sport',
    city: 'İstanbul',
    district: 'Kadıköy',
    startsAt: DateTime.now().add(startsIn),
    capacity: capacity,
    acceptedCount: accepted,
    status: status,
  );
}

Future<void> _pumpCard(WidgetTester tester, Event event,
    {VoidCallback? onTap}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: EventCard(event: event, onTap: onTap ?? () {})),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  group('EventCard', () {
    testWidgets('başlık, konum ve doluluk gösterir', (tester) async {
      await _pumpCard(tester, _event(accepted: 2));
      expect(find.text('Sabah koşusu'), findsOneWidget);
      expect(find.text('Kadıköy, İstanbul'), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);
    });

    testWidgets('kapasite dolunca "Dolu" rozeti çıkar', (tester) async {
      await _pumpCard(tester, _event(accepted: 5));
      expect(find.text('Dolu'), findsOneWidget);
    });

    testWidgets('iptal edilen etkinlik "İptal" rozeti taşır', (tester) async {
      await _pumpCard(tester, _event(status: EventStatus.cancelled));
      expect(find.text('İptal'), findsOneWidget);
    });

    testWidgets('geçmiş etkinlik "Geçti" rozeti taşır', (tester) async {
      await _pumpCard(tester, _event(startsIn: const Duration(days: -1)));
      expect(find.text('Geçti'), findsOneWidget);
    });

    testWidgets('dokununca onTap çağrılır', (tester) async {
      var tapped = 0;
      await _pumpCard(tester, _event(), onTap: () => tapped++);
      await tester.tap(find.text('Sabah koşusu'));
      expect(tapped, 1);
    });
  });

  group('LoginScreen', () {
    Future<_FakeAuth> pumpLogin(WidgetTester tester) async {
      final auth = _FakeAuth();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LoginScreen(),
          ),
        ),
      );
      return auth;
    }

    testWidgets('boş form hata gösterir ve giriş yapmaz', (tester) async {
      final auth = await pumpLogin(tester);
      await tester.tap(find.text('Giriş yap'));
      await tester.pump();
      expect(find.text('E-posta adresini yaz.'), findsOneWidget);
      expect(find.text('Şifreni yaz.'), findsOneWidget);
      expect(auth.signInCalls, isEmpty);
    });

    testWidgets('geçersiz e-posta reddedilir', (tester) async {
      final auth = await pumpLogin(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'abc');
      await tester.enterText(find.byType(TextFormField).at(1), 'sifre123');
      await tester.tap(find.text('Giriş yap'));
      await tester.pump();
      expect(find.text('Geçerli bir e-posta adresi yaz.'), findsOneWidget);
      expect(auth.signInCalls, isEmpty);
    });

    testWidgets('geçerli bilgilerle signIn çağrılır', (tester) async {
      final auth = await pumpLogin(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'sifre123');
      await tester.tap(find.text('Giriş yap'));
      await tester.pump();
      expect(auth.signInCalls, ['a@b.com|sifre123']);
    });
  });

  group('RegisterScreen', () {
    Future<_FakeAuth> pumpRegister(WidgetTester tester) async {
      final auth = _FakeAuth();
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RegisterScreen(),
          ),
        ),
      );
      return auth;
    }

    Future<void> fill(WidgetTester tester,
        {String email = 'a@b.com',
        String password = 'abc12345',
        String confirm = 'abc12345'}) async {
      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.enterText(find.byType(TextFormField).at(2), confirm);
    }

    testWidgets('onay kutuları işaretlenmeden hesap açılmaz', (tester) async {
      final auth = await pumpRegister(tester);
      await fill(tester);
      await tester.tap(find.text('Hesap oluştur'));
      await tester.pump();
      expect(find.textContaining('18 yaşını doldurduğunu onaylamalı'), findsOneWidget);
      expect(auth.registerCalls, isEmpty);
    });

    testWidgets('zayıf şifre ve uyuşmayan tekrar reddedilir', (tester) async {
      final auth = await pumpRegister(tester);
      await fill(tester, password: '12345678', confirm: 'baska');
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.tap(find.text('Hesap oluştur'));
      await tester.pump();
      expect(find.text('Şifre en az bir harf ve bir rakam içermeli.'), findsOneWidget);
      expect(find.text('Şifreler aynı değil.'), findsOneWidget);
      expect(auth.registerCalls, isEmpty);
    });

    testWidgets('geçerli form ve onaylarla register çağrılır', (tester) async {
      final auth = await pumpRegister(tester);
      await fill(tester);
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.tap(find.text('Hesap oluştur'));
      await tester.pump();
      expect(auth.registerCalls, ['a@b.com|abc12345']);
    });
  });
}
