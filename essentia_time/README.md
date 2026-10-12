# Essentia Time

Time for [Essentia](../README.md): time sources and clocks, instants, dates, times and periods,
every IANA time zone with its rules and transitions, the formats of dates and times, and the
recurrence of RFC 5545.

| Library | What it holds |
|---|---|
| `package:essentia_time/essentia_time.dart` | Time sources, clocks, dates, times, time zones, formats |
| `package:essentia_time/recurrence.dart` | Recurrence rules and sets that expand repetitions across time zones |
| `package:essentia_time/testing.dart` | `TestTimeSource`, a time source that only moves when a test advances it |

The time zone database lies in `IANA/tzdata`; `dart run tool/generate_tzdata.dart` compiles it into
`lib/src/internal/tzdata.dart`, and `--check` tells whether that file is current.
