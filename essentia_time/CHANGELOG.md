# Changelog

All notable changes to this package are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package adheres to
[Semantic Versioning](https://semver.org/).

## 1.0.0

Split out of `essentia` 3.3.0, whose history is in the [workspace changelog](https://github.com/davils-com/essentia/blob/main/CHANGELOG.md).

### Added

- `package:essentia_time/essentia_time.dart`: time sources and clocks, instants, dates, times,
  periods, every IANA time zone and the formats of dates and times.
- `package:essentia_time/recurrence.dart`: the RFC 5545 recurrence rules and sets, which
  `package:essentia/icalendar.dart` exported before.
- `package:essentia_time/testing.dart`: `TestTimeSource`, which `package:essentia/essentia.dart`
  exported before.
- The time zone database lies in `IANA/tzdata`.
