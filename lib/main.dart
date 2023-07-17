import 'package:aquarium_manager/views/typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "package:aquarium_manager/model/aquarium_manager_model.dart";
import 'package:aquarium_manager/controllers/aquarium_manager_login_controller.dart';
import 'package:aquarium_manager/model/session_key.dart';
import 'model/aquarium_manager_facilities_model.dart';
import 'model/aquarium_manager_tanks_model.dart';
import 'package:aquarium_manager/model/aquarium_manager_search_model.dart';
import 'package:aquarium_manager/views/consts.dart';
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
        ChangeNotifierProvider<MyAquariumManagerModel>(
          create: (_) => MyAquariumManagerModel(manageSession),
        ),
        ChangeNotifierProvider<MyAquariumManagerFacilityModel>(
          create: (_) => MyAquariumManagerFacilityModel(manageSession),
        ),
        ChangeNotifierProvider<MyAquariumManagerTanksModel>(
          create: (_) => MyAquariumManagerTanksModel(manageSession),
        ),
        ChangeNotifierProvider<MyAquariumManagerSearchModel>(
          create: (_) => MyAquariumManagerSearchModel(manageSession),
        ),
      ],
      child: MaterialApp(
        title: kProgramName,
        theme: aquariumManagerTheme,
        home: const MyAquariumManagerLoginController(),
      ),
    );
  }
}
