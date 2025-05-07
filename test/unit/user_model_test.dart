import 'package:flutter_test/flutter_test.dart';
import 'package:taskgenius/state/auth_provider.dart';

void main() {
  group('User Model Tests', () {
    test('User serialization and deserialization', () {
      final user = User(
        id: '123',
        name: 'Test User',
        email: 'test@example.com',
        photoUrl: 'http://photo.com/user.png',
      );

      final map = user.toMap();
      expect(map['id'], '123');
      expect(map['name'], 'Test User');

      final json = user.toJson();
      final fromJson = User.fromJson(json);
      expect(fromJson.id, '123');
      expect(fromJson.name, 'Test User');
    });

    test('User.fromMap with missing fields', () {
      final user = User.fromMap({'id': '1'});
      expect(user.name, '');
      expect(user.email, '');
    });
  });
}
