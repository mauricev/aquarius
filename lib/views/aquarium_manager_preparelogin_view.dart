part of 'package:aquarium_manager/views/aquarium_manager_login_view.dart';

extension _MyAquariumManagerViewPrepareLogin
    on _MyAquariumManagerLoginViewState {

  Widget registerLoginScreens(BuildContext context,MyAquariumManagerModel model) {
    if (model.getDoesUserWantToRegister()) {
      return registerUserNamePassword(context);
    } else {
      return loginUserNamePassword(context);
    }
  }

  Widget prepareLoginScreen(BuildContext context) {
    MyAquariumManagerModel model = Provider.of<MyAquariumManagerModel>(context);

    return FutureBuilder(
      future: model.modelRetrieveSession(), // retrieves the session
      builder: (ctx, snapshot) {
        myPrint("inside future builder");
        if (snapshot.connectionState == ConnectionState.done) {
          myPrint("account.get has returned with error or not");
          if (snapshot.hasError) {
            myPrint("account.get has an ERROR, we will present the login screens");
            // Return the widget for login screens
            return registerLoginScreens(context, model);
          } else if (snapshot.hasData) {
            myPrint("account.get has returned with NO error");
            // Navigate to the home screen route
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AquariumManagerHomeScreenView(),
                ),
              );
            });
          }
        }
        myPrint("we are in circular progress");
        return const CircularProgressIndicator(); // awaiting login status
      },
    );
  }
}
