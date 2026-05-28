import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_world_clock_service.dart';

void main() {
  group('ToolboxWorldClockService', () {
    const service = ToolboxWorldClockService();

    test('formats offsets and calculates city snapshots', () {
      final tokyo = service.cityById('tokyo');
      final snapshot = service.snapshotForCity(
        tokyo,
        utcNow: DateTime.utc(2026, 5, 27, 0, 30),
        deviceOffsetMinutes: 480,
      );

      expect(snapshot.offsetMinutes, 540);
      expect(snapshot.offsetLabel, 'UTC+09:00');
      expect(snapshot.differenceFromDeviceMinutes, 60);
      expect(ToolboxWorldClockService.formatTime(snapshot.localTime), '09:30');
    });

    test('applies northern daylight saving rules', () {
      final london = service.cityById('london');
      final newYork = service.cityById('new_york');

      expect(
        service.effectiveOffsetMinutes(london, DateTime.utc(2026, 1, 15, 12)),
        0,
      );
      expect(
        service.effectiveOffsetMinutes(london, DateTime.utc(2026, 7, 15, 12)),
        60,
      );
      expect(
        service.effectiveOffsetMinutes(newYork, DateTime.utc(2026, 1, 15, 12)),
        -300,
      );
      expect(
        service.effectiveOffsetMinutes(newYork, DateTime.utc(2026, 7, 15, 12)),
        -240,
      );
    });

    test('applies southern hemisphere daylight saving rules', () {
      final sydney = service.cityById('sydney');
      final auckland = service.cityById('auckland');

      expect(
        service.effectiveOffsetMinutes(sydney, DateTime.utc(2026, 1, 15, 12)),
        660,
      );
      expect(
        service.effectiveOffsetMinutes(sydney, DateTime.utc(2026, 7, 15, 12)),
        600,
      );
      expect(
        service.effectiveOffsetMinutes(auckland, DateTime.utc(2026, 1, 15, 12)),
        780,
      );
    });

    test('searches cities and filters by business hours', () {
      final matches = service.searchCities('new');
      expect(matches.map((city) => city.id), contains('new_york'));
      expect(matches.map((city) => city.id), contains('auckland'));

      final openCities = service.searchCities(
        '',
        utcNow: DateTime.utc(2026, 5, 27, 2),
        businessHoursOnly: true,
      );

      expect(openCities.map((city) => city.id), contains('beijing'));
      expect(
        openCities.every((city) {
          return service
              .snapshotForCity(city, utcNow: DateTime.utc(2026, 5, 27, 2))
              .isBusinessHours;
        }),
        isTrue,
      );
    });
  });
}
