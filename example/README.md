# Essentia example

`essentia_example.dart` reads who to greet from its parameters (or from `EXAMPLE_NAME` and
`EXAMPLE_TIMES`), publishes one event per greeting on an event bus and prints what the subscriber
receives:

```bash
dart run example/essentia_example.dart --name Ada -n Grace --times 2
```

A wrong value reports every problem at once, together with the usage listing:

```bash
dart run example/essentia_example.dart --times 0 --naem Ada
```
