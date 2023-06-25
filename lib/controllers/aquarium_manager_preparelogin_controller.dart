part of 'package:aquarium_manager/controllers/aquarium_manager_login_controller.dart';

extension MyAquariumManagerControllerPrepareLogin
    on _MyAquariumManagerLoginControllerState {

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
        print("inside future builder");
        if (snapshot.connectionState == ConnectionState.done) {
          print("account.get has returned with error or not");
          if (snapshot.hasError) {
            print("account.get has an ERROR, we will present the login screens");
            // Return the widget for login screens
            return registerLoginScreens(context, model);
          } else if (snapshot.hasData) {
            print("account.get has returned with NO error");
            // Navigate to the home screen route
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AquariumManagerHomeScreenController(),
                ),
              );
            });
          }
        }
        print("we are in circular progress");
        return CircularProgressIndicator(); // awaiting login status
      },
    );
  }
}
