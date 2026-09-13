import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// One position in the demo portfolio.
@immutable
class Holding {
  /// Creates a holding.
  const Holding({
    required this.symbol,
    required this.name,
    required this.price,
    required this.units,
    required this.volatility,
  });

  /// The ticker symbol shown in the row.
  final String symbol;

  /// The company name.
  final String name;

  /// The current price per unit.
  final double price;

  /// How many units are held.
  final int units;

  /// How hard this holding moves per tick, as a fraction of [price].
  final double volatility;

  /// The rounded value of the position, which is what the demo animates.
  int get value => (price * units).round();

  /// A copy at a new price.
  Holding at(double next) => Holding(
    symbol: symbol,
    name: name,
    price: next,
    units: units,
    volatility: volatility,
  );
}

/// A fake market feed: a seeded random walk over a handful of holdings.
///
/// Seeded deliberately. The README GIFs are recorded from this, and a feed that
/// produced a different sequence on every run would make a re-recording
/// impossible to match against the one it replaces.
class PortfolioTicker extends ChangeNotifier {
  /// Creates a ticker, stopped, at its opening prices.
  PortfolioTicker({int seed = 7, this.interval = const Duration(seconds: 2)})
    : _random = Random(seed),
      _holdings = List<Holding>.of(_openingBell);

  static const List<Holding> _openingBell = <Holding>[
    Holding(
      symbol: 'ARLO',
      name: 'Arlo Systems',
      price: 1284.50,
      units: 64,
      volatility: 0.018,
    ),
    Holding(
      symbol: 'KVAN',
      name: 'Kavan Energy',
      price: 342.10,
      units: 210,
      volatility: 0.026,
    ),
    Holding(
      symbol: 'MRDN',
      name: 'Meridian Foods',
      price: 88.75,
      units: 480,
      volatility: 0.012,
    ),
    Holding(
      symbol: 'TSVA',
      name: 'Tesva Mobility',
      price: 2610.00,
      units: 12,
      volatility: 0.034,
    ),
  ];

  /// How often [start] advances the feed.
  final Duration interval;

  final Random _random;
  List<Holding> _holdings;
  Timer? _timer;

  /// The current positions.
  List<Holding> get holdings => List<Holding>.unmodifiable(_holdings);

  /// The whole portfolio, which is the number the hero shows.
  int get total =>
      _holdings.fold<int>(0, (int sum, Holding h) => sum + h.value);

  /// Whether the feed is running.
  bool get running => _timer != null;

  /// Advances every holding by one step of the walk.
  ///
  /// Public so tests can step the feed deterministically instead of waiting on
  /// a real timer.
  void tick() {
    _holdings = <Holding>[
      for (final Holding holding in _holdings)
        holding.at(_nextPrice(holding)),
    ];
    notifyListeners();
  }

  /// Starts the feed, if it is not already running.
  void start() {
    if (running) {
      return;
    }
    _timer = Timer.periodic(interval, (_) => tick());
    notifyListeners();
  }

  /// Stops the feed.
  void stop() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  /// Starts a stopped feed, or stops a running one.
  void toggle() => running ? stop() : start();

  /// Returns every holding to its opening price.
  void reset() {
    _holdings = List<Holding>.of(_openingBell);
    notifyListeners();
  }

  /// A step of the walk, biased very slightly upward so a long recording
  /// trends rather than drifting to zero, and floored so a price cannot go
  /// negative and turn the whole demo into a minus sign.
  double _nextPrice(Holding holding) {
    final double swing = (_random.nextDouble() - 0.48) * 2 * holding.volatility;
    final double next = holding.price * (1 + swing);
    return max(next, holding.price * 0.5);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
