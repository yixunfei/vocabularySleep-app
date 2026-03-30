import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/app/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化环境变量
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('环境变量已加载');
  } catch (e) {
    debugPrint('警告：无法加载.env 文件，使用系统环境变量 ($e)');
  }

  runVocabularySleepApp();
}
