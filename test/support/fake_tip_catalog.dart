import 'package:green_friend/domain/tips.dart';

/// In-memory [TipCatalog] for tests.
class FakeTipCatalog implements TipCatalog {
  FakeTipCatalog(this.all);

  @override
  final List<CareTip> all;
}
