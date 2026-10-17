import 'package:green_friend/domain/care_widget.dart';

/// Records what the home-screen widget would show.
class FakeCareWidget implements CareWidget {
  final shown = <CareWidgetContent>[];

  CareWidgetContent? get last => shown.isEmpty ? null : shown.last;

  @override
  Future<void> show(CareWidgetContent content) async => shown.add(content);
}
