import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/viewmodel.dart';
import 'homescreen_view.dart';
import '../views/consts.dart';
import '../views/utility.dart';
part 'preparelogin_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() =>
      _LoginViewState();
}

class _LoginViewState
    extends State<LoginView> {
  bool doPasswordsMatch = true;
  String registerError = ""; // this now defaults to an empty string
  TextEditingController controllerForEmail = TextEditingController();
  TextEditingController controllerForNewPassword1 = TextEditingController();
  TextEditingController controllerForNewPassword2 = TextEditingController();

  TextEditingController controllerForLoginEmail = TextEditingController();
  TextEditingController controllerForPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Dispose of the TextEditingController instances
    controllerForEmail.dispose();
    controllerForNewPassword1.dispose();
    controllerForNewPassword2.dispose();
    controllerForLoginEmail.dispose();
    controllerForPassword.dispose();

    super.dispose();
  }

  Widget loginUserNamePassword(BuildContext context) {
    AquariusViewModel model = Provider.of<AquariusViewModel>(context, listen: true);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left:kIndentWidth,right: kIndentWidth),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // this button tells the app to register a new user
                model.setDoesUserWantToRegister(true);
              },
              child: const Text("Register"),
            ),
            if (model.getUserAccountJustCreated())
              const Text("Your account was just created. Proceed to login."),
            const Text(""),
            TextField(
              decoration: const InputDecoration(
                hintText: 'email',
              ),
              controller: controllerForLoginEmail,
            ),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'password',
              ),
              controller: controllerForPassword,
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () {
                model
                    .loginUser(controllerForLoginEmail.text,
                        controllerForPassword.text)
                    .then((sessionValue) {
                  // we are done with the login screens, remove them from the navigation stack
                  // we can get it back by navigating to it again
                  //Navigator.pushReplacementNamed(context, '/homescreen');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreenView(),
                    ),
                  );
                }).catchError((error) {
                  myPrint("Login failed. Might you have entered the wrong credentials");
                  //myPrint(error.response); <- this is a bug
                  model.setBadUserPassword(true);
                });
              },
              child: const Text("Login"),
            ),
            model.getIsUserPasswordBad()
                ? const Text("Login failed. Might you have entered the wrong credentials?")
                : Container(),
          ],
        ),
      ),
    );
  }

 bool doPasswordsMatchFunction() {
   return (controllerForNewPassword1.text == controllerForNewPassword2.text);
  }

  Widget registerUserNamePassword(BuildContext context) {
    AquariusViewModel model = Provider.of<AquariusViewModel>(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left:kIndentWidth,right: kIndentWidth),
        child: Column(
          children: <Widget>[
            model.getFailedToRegister()
                ? const Text(
                    "User account couldn’t be created; perhaps it’s already registered.")
                : Container(),
            TextField(
              decoration: const InputDecoration(
                hintText: 'enter your email',
              ),
              controller: controllerForEmail,
            ),
            TextField(
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'make up a strong password',
              ),
              controller: controllerForNewPassword1,
            ),
            TextField(
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'type your password again',
              ),
              controller: controllerForNewPassword2,
            ),
            if (!doPasswordsMatch) const Text("passwords don’t match") else const Text(""),
            Text(registerError),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      model.setDoesUserWantToRegister(false);
                    },
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(
                  width: 100,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (!doPasswordsMatchFunction())
                        ? () {
                      setState(() {
                        doPasswordsMatch = false;
                      });
                    }
                        : () {
                            setState(() {
                              doPasswordsMatch = true;
                              registerError ="";
                            });
                            model
                                .registerUser(controllerForEmail.text,
                                    controllerForNewPassword1.text)
                                .then((registeredUserResult) {
                              model.setDoesUserWantToRegister(false);
                            }).catchError((onError) {
                              model.setDoesUserWantToRegister(true);
                              setState(() {
                                registerError = onError.toString();
                              });
                              // we can set a variable here to true to indicate there
                              // was an error and call setstate on it
                              // somewhere else we check it and display the error message here
                            });
                          },
                    child: const Text("Submit"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Column(
                children: <Widget>[
                  prepareLoginScreen(context),
                ],
              ),
            ),
          ),
    );
  }
}
