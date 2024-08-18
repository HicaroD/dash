import 'package:dash/dash.dart';
import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database is being created successfully', () async {
    final cache = await Dash.init();
    assert(cache.isOpen());

    final version = await cache.version();
    assert(version == 0);
  });

  group("Dash operations", () {
    late Dash cache;
    late Faker faker;

    setUpAll(() {
      faker = Faker();
    });

    setUp(() async {
      cache = await Dash.init();
    });

    tearDown(() {
      cache.dropAll();
      cache.close();
    });

    test("put() for random information works properly", () async {
      for (int i = 0; i < 50; i++) {
        final key = faker.internet.userName();
        final value = faker.lorem.sentence();

        cache.put(key, value);

        final retrievedValue = await cache.get(key);
        assert(value == retrievedValue);
      }
    });

    test("put() replaces value if key already exists", () async {
      for (int i = 0; i < 50; i++) {
        final key = faker.internet.userName();
        final value = faker.lorem.sentence();

        cache.put(key, value);
        final retrievedValue = await cache.get(key);
        assert(retrievedValue != null);
        assert(value == retrievedValue);

        final newValue = faker.lorem.sentence();
        cache.put(key, newValue);

        final retrievedNewValue = await cache.get(key);
        assert(retrievedNewValue != null);
        assert(newValue == retrievedNewValue);
      }
    });

    test("get() detects non-existing entries", () async {
      for (int i = 0; i < 50; i++) {
        final nonExistingKey = faker.internet.userName();
        final nonExistingValue = await cache.get(nonExistingKey);
        assert(nonExistingValue == null);
      }
    });
  });
}
