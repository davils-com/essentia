/*
 * Copyright (c) 2026 Davils GmbH
 * All rights reserved.
 *
 * This software is the property of Davils GmbH.
 * Unauthorized copying, modification, distribution, or use of this code,
 * in whole or in part, is strictly prohibited without prior written permission.
 */

part of 'generate_tzdata.dart';

/// The zones, rules and links of the time zone database, read from its
/// source files, and the compiler that turns a zone into `ZoneRules` the
/// way the reference compiler `zic` does.
final class ZicSource {
  /// The source of [rules], [zones] and [links].
  ZicSource({required this.rules, required this.zones, required this.links})
    : lastYear = _lastYearOf(rules, zones);

  /// Reads the source files [texts].
  ///
  /// Throws a [FormatException] for a line it cannot read.
  factory ZicSource.parse(List<String> texts) {
    final rules = <String, List<ZicRule>>{};
    final zones = <String, List<ZicZoneLine>>{};
    final links = <String, String>{};
    for (final text in texts) {
      List<ZicZoneLine>? open;
      for (final String raw in text.split('\n')) {
        final int hash = raw.indexOf('#');
        final String line = hash < 0 ? raw : raw.substring(0, hash);
        final List<String> fields = line.trim().split(RegExp(r'\s+'));
        if (fields.first.isEmpty) {
          continue;
        }
        final bool continuation = line.startsWith(' ') || line.startsWith('\t');
        if (continuation) {
          final lines = open;
          if (lines == null) {
            throw FormatException('A continuation without a zone', raw);
          }
          final parsed = ZicZoneLine.parse(fields);
          lines.add(parsed);
          open = parsed.untilYear == null ? null : lines;
          continue;
        }
        open = null;
        switch (fields.first) {
          case 'Rule':
            rules
                .putIfAbsent(fields[1], () => <ZicRule>[])
                .add(ZicRule.parse(fields.sublist(2)));
          case 'Zone':
            final parsed = ZicZoneLine.parse(fields.sublist(2));
            final List<ZicZoneLine> lines = zones[fields[1]] = <ZicZoneLine>[
              parsed,
            ];
            open = parsed.untilYear == null ? null : lines;
          case 'Link':
            links[fields[2]] = fields[1];
          case String():
            throw FormatException('Not a line of the database', raw);
        }
      }
    }
    return ZicSource(rules: rules, zones: zones, links: links);
  }

  /// The year that stands for "min": before every rule of the database.
  static const firstYear = 1800;

  /// The year that stands for "max".
  static const maxYear = 1000000;

  /// The rules by name.
  final Map<String, List<ZicRule>> rules;

  /// The lines of every zone by name.
  final Map<String, List<ZicZoneLine>> zones;

  /// The target of every link by name.
  final Map<String, String> links;

  /// The last year whose transitions are compiled one by one; later ones
  /// come from the recurring rule.
  final int lastYear;

  /// The year after the last one any rule or zone line names, but at
  /// least 2040.
  static int _lastYearOf(
    Map<String, List<ZicRule>> rules,
    Map<String, List<ZicZoneLine>> zones,
  ) {
    var last = 2040;
    for (final ZicRule rule in rules.values.expand((it) => it)) {
      final int year = rule.isMax ? rule.from : rule.to;
      if (year + 1 > last) {
        last = year + 1;
      }
    }
    for (final ZicZoneLine line in zones.values.expand((it) => it)) {
      final int? year = line.untilYear;
      if (year != null && year + 1 > last) {
        last = year + 1;
      }
    }
    return last;
  }

  /// The zone [name] links to, following links to links, or [name] itself.
  ///
  /// Throws a [StateError] for a link to nothing.
  String canonical(String name) {
    var current = name;
    for (var hops = 0; hops < 16; hops += 1) {
      if (zones.containsKey(current)) {
        return current;
      }
      final String? target = links[current];
      if (target == null) {
        break;
      }
      current = target;
    }
    throw StateError('The link $name leads to no zone');
  }

  /// The rules of the zone [name], as `zic` compiles them.
  ZoneRules compile(String name) {
    final List<ZicZoneLine> lines = zones[name]!;
    final changes = <(int, int)>[];
    int initial = lines.first.standardOffset + lines.first.save;
    var save = 0;
    int? start;
    for (var index = 0; index < lines.length; index += 1) {
      final ZicZoneLine line = lines[index];
      final bool useUntil = index < lines.length - 1;
      final int standard = line.standardOffset;
      final String? ruleName = line.rules;
      final lineStart = start;
      if (ruleName == null) {
        save = line.save;
        if (lineStart == null) {
          initial = standard + save;
        }
        if (lineStart != null) {
          changes.add((lineStart, standard + save));
        }
      }
      if (ruleName != null) {
        if (lineStart == null) {
          initial = standard;
        }
        save = _applyRules(
          rules[ruleName] ?? (throw StateError('No rules $ruleName')),
          line,
          useUntil: useUntil,
          start: lineStart,
          changes: changes,
        );
      }
      if (useUntil) {
        start = line.untilUtc(save);
      }
    }
    final List<ZoneTransition> transitions = _chain(initial, changes);
    final RecurringZoneRule? recurring = _recurringOf(lines.last);
    return ZoneRules(
      initialOffset: UtcOffset.fromTotalSeconds(initial),
      transitions: recurring == null
          ? transitions
          : _trim(transitions, recurring),
      recurring: recurring,
    );
  }

  /// Applies the rules [named] to [line], which starts at [start], adding
  /// the changes of offset to [changes].
  ///
  /// As in `zic`, nothing is taken to be saved when the line starts until
  /// a rule before [start] says otherwise.
  ///
  /// Returns the seconds saved when the line ends.
  int _applyRules(
    List<ZicRule> named,
    ZicZoneLine line, {
    required bool useUntil,
    required int? start,
    required List<(int, int)> changes,
  }) {
    final int standard = line.standardOffset;
    var saving = 0;
    var startOffset = standard;
    var useStart = start != null;
    final int first = named
        .map((rule) => rule.from)
        .reduce((a, b) => a < b ? a : b);
    final int last = useUntil ? line.untilYear! : lastYear;
    for (var year = first; year <= last; year += 1) {
      final todo = <ZicRule>[
        for (final ZicRule rule in named)
          if (rule.covers(year)) rule,
      ];
      while (todo.isNotEmpty) {
        ZicRule? earliest;
        var earliestTime = 0;
        for (final rule in todo) {
          final int time = ZicTime.toUtc(
            rule.localSecondsIn(year),
            rule.at.definition,
            standard,
            saving,
          );
          if (earliest == null || time < earliestTime) {
            earliest = rule;
            earliestTime = time;
          }
        }
        final ZicRule rule = earliest!;
        todo.remove(rule);
        if (useUntil && earliestTime >= line.untilUtc(saving)) {
          break;
        }
        saving = rule.save;
        if (useStart && earliestTime == start) {
          useStart = false;
        }
        if (useStart && earliestTime < start!) {
          startOffset = standard + saving;
          continue;
        }
        changes.add((earliestTime, standard + saving));
      }
    }
    if (useStart) {
      changes.add((start!, startOffset));
    }
    return saving;
  }

  /// The transitions of [changes] from [initial] on, in time order.
  ///
  /// As `zic` does, the last change at one time wins, and a change that
  /// takes effect, read on the clock before it, no later than the one
  /// before it merges into that one; changes to the same offset are left
  /// out.
  static List<ZoneTransition> _chain(int initial, List<(int, int)> changes) {
    final ordered =
        <(int, int, int)>[
          for (var index = 0; index < changes.length; index += 1)
            (changes[index].$1, index, changes[index].$2),
        ]..sort((a, b) {
          final int byTime = a.$1.compareTo(b.$1);
          return byTime != 0 ? byTime : a.$2.compareTo(b.$2);
        });
    final merged = <(int, int)>[];
    for (final (int time, int _, int offset) in ordered) {
      if (merged.isNotEmpty) {
        final (int lastTime, int lastOffset) = merged.last;
        final int before = merged.length >= 2
            ? merged[merged.length - 2].$2
            : initial;
        if (time == lastTime || time + lastOffset <= lastTime + before) {
          merged.last = (lastTime, offset);
          continue;
        }
      }
      merged.add((time, offset));
    }
    final transitions = <ZoneTransition>[];
    var offset = initial;
    for (final (int time, int next) in merged) {
      if (next == offset) {
        continue;
      }
      transitions.add(
        ZoneTransition(
          Instant.fromEpochSeconds(time),
          UtcOffset.fromTotalSeconds(offset),
          UtcOffset.fromTotalSeconds(next),
        ),
      );
      offset = next;
    }
    return transitions;
  }

  /// The rule [line] repeats every year once its rules run forever, or
  /// `null` when it has none.
  RecurringZoneRule? _recurringOf(ZicZoneLine line) {
    final String? name = line.rules;
    if (name == null) {
      return null;
    }
    final forever = <ZicRule>[
      for (final ZicRule rule in rules[name]!)
        if (rule.isMax) rule,
    ];
    if (forever.isEmpty) {
      return null;
    }
    return RecurringZoneRule(
      standardOffset: UtcOffset.fromTotalSeconds(line.standardOffset),
      rules: <ZoneTransitionRule>[
        for (final rule in forever) rule.toTransitionRule(line.standardOffset),
      ],
    );
  }

  /// [transitions] without the longest tail [recurring] reproduces
  /// exactly up to [lastYear], from the transition before it on; the first
  /// transition always stays, so the history keeps its start.
  List<ZoneTransition> _trim(
    List<ZoneTransition> transitions,
    RecurringZoneRule recurring,
  ) {
    final end = Instant.parse('${lastYear + 1}-01-01T00:00:00Z');
    int keep = transitions.length;
    while (keep > 1) {
      final ZoneTransition last = transitions[keep - 2];
      final rules = ZoneRules(
        initialOffset: last.offsetBefore,
        transitions: <ZoneTransition>[last],
        recurring: recurring,
      );
      final List<ZoneTransition> expected = rules.transitionsBetween(
        last.instant + const Duration(seconds: 1),
        end,
      );
      if (!_same(expected, transitions.sublist(keep - 1))) {
        break;
      }
      keep -= 1;
    }
    return transitions.sublist(0, keep);
  }

  /// Whether [a] and [b] hold the same transitions.
  static bool _same(List<ZoneTransition> a, List<ZoneTransition> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
