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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ManageSession manageSession = ManageSession();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp,DeviceOrientation.portraitDown]
  )
      .then((_) {
    runApp(MyApp(manageSession: manageSession));
  });
}

class MyApp extends StatelessWidget {
  final ManageSession manageSession;

  const MyApp({required this.manageSession, Key? key}) : super(key: key);

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
      ],
      child: MaterialApp(
        title: kProgramName,
        theme: aquariumManagerTheme,
        home: const LoginView(),
      ),
    );
  }
}
