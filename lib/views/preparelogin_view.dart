part of '../views/login_view.dart';

extension _ViewPrepareLogin
    on _LoginViewState {

  Widget registerLoginScreens(BuildContext context,AquariusViewModel model) {
    if (model.getDoesUserWantToRegister()) {
      return registerUserNamePassword(context);
    } else {
      return loginUserNamePassword(context);
    }
  }

  Widget prepareLoginScreen(BuildContext context) {
    AquariusViewModel model = Provider.of<AquariusViewModel>(context);

    return FutureBuilder(
      future: model.modelRetrieveSession(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {

          if (snapshot.hasError) {
            return registerLoginScreens(context, model);
          } else if (snapshot.hasData) {

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreenView(),
                ),
              );
            });
          }
        }
        return const CircularProgressIndicator(); // awaiting login status
      },
    );
  }
}
