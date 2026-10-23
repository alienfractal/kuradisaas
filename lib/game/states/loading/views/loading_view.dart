import '../../../view/screen_view.dart';

class LoadingView extends ScreenView {
  final String description;
  LoadingView({required this.description});
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    title('LOADING');
    label(description, 82, fontSize: 8);
    label('PREPARING THE NEXT WORLD...', 115);
  }
}
