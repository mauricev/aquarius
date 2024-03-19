import 'views/typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "view_models/viewmodel.dart";
import 'views/login_view.dart';
import 'view_models/session_key.dart';
import 'view_models/facilities_viewmodel.dart';
import 'view_models/tanks_viewmodel.dart';
import 'view_models/search_viewmodel.dart';
import 'views/consts.dart';
import 'package:flutter/services.dart';
import 'view_models/tanklines_viewmodel.dart';

// 5 of 6 remove for real-world web
import 'package:window_manager/window_manager.dart';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ManageSession manageSession = ManageSession();

  // real-world 5 of 5, comment out for web
  /*if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS) {

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(810, 1080), // 10.2 inch iPad portrait size
      minimumSize: Size(810, 1080), //BUGfixed
      maximumSize: Size(810, 1080), //BUGfixed
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal, // BUGfixed, had been TitleBarStyle.hidden, but this hides the draggable part of the window under Windows
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }*/

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp,DeviceOrientation.portraitDown]
  )
      .then((_) {
    runApp(MyApp(manageSession: manageSession));
  });

}

// another option for sending messages between providers is to have a class like managesession
// and pass it to each provider. each provider registers itself
// we have to wait until the user logins and then send a message to the common class
// that we are ready to accept messages from each ChangeNotifierProvider
// ChangeNotifierProvider.startAcceptingMessages();

// this class then calls each ChangeNotifierProvider letting it know that the app has been logged in
// and stuff can be initialized.
// it initializes TanksLineViewModel and sends a message to TanksViewModel that messages can be received
// TanksLineViewModel
class MyApp extends StatelessWidget {
  final ManageSession manageSession;

  const MyApp({required this.manageSession, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AquariusViewModel>(
          create: (_) => AquariusViewModel(manageSession),
        ),
        ChangeNotifierProvider<FacilityViewModel>(
          create: (_) => FacilityViewModel(manageSession),
        ),
        ChangeNotifierProvider<TanksViewModel>(
          create: (_) => TanksViewModel(manageSession),
        ),
        ChangeNotifierProvider<SearchViewModel>(
          create: (_) => SearchViewModel(manageSession),
        ),
        ChangeNotifierProvider<TanksLineViewModel>(
          create: (_) => TanksLineViewModel(manageSession),
        ),
      ],
      child: MaterialApp(
        title: kProgramName,
        theme: aquariumManagerTheme,
        home: const LoginView(),
      ),
    );
  }
}
