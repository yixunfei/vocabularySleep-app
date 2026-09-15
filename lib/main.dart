import 'main_native.dart' if (dart.library.html) 'main_web.dart' as platform;

void main() => platform.main();
