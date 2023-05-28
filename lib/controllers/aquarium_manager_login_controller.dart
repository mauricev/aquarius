import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aquarium_manager/model/aquarium_manager_model.dart';

import 'aquarium_manager_homescreen_controller.dart';

import 'package:aquarium_manager/views/utility.dart';

part 'aquarium_manager_preparelogin_controller.dart';

class MyAquariumManagerLoginController extends StatefulWidget {
  MyAquariumManagerLoginController({super.key});

  @override
  State<MyAquariumManagerLoginController> createState() =>
      _MyAquariumManagerLoginControllerState();
}

class _MyAquariumManagerLoginControllerState
    extends State<MyAquariumManagerLoginController> {
  bool doPasswordsMatch = true;
  String registerError = "look here";
  TextEditingController controllerForEmail = TextEditingController();
  TextEditingController controllerForNewPassword1 = TextEditingController();
  TextEditingController controllerForNewPassword2 = TextEditingController();

  TextEditingController controllerForLoginEmail = TextEditingController();
  TextEditingController controllerForPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Widget loginUserNamePassword(BuildContext context) {
    MyAquariumManagerModel model = Provider.of<MyAquariumManagerModel>(context);

    return Expanded(
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
          TextField(
            decoration: const InputDecoration(
              hintText: 'email',
            ),
            controller: controllerForLoginEmail,
          ),
          TextField(
            decoration: const InputDecoration(
              hintText: 'password',
            ),
            controller: controllerForPassword,
          ),
          ElevatedButton(
            onPressed: () {
              model
                  .loginUser(controllerForLoginEmail.text,
                      controllerForPassword.text)
                  .then((sessionValue) {
                print("calling homescreen route");
                // we are done with the login screens, remove them from the stack
                // but we might be losing the scaffold
                // and what happens if we add a new one?
                Navigator.pushReplacementNamed(context, '/homescreen');
              }).catchError((error) {
                print("login session failed");
                print(error.response);
              });
            },
            child: const Text("Login"),
          ),
          model.getIsUserPasswordBad()
              ? const Text("user/password is incorrect")
              : Container(),
        ],
      ),
    );
  }

 bool doPasswordsMatchFunction() {
   return (controllerForNewPassword1.text == controllerForNewPassword2.text);
  }

  Widget registerUserNamePassword(BuildContext context) {
    MyAquariumManagerModel model = Provider.of<MyAquariumManagerModel>(context);

    return Expanded(
      child: Column(
        children: <Widget>[
          model.getFailedToRegister()
              ? const Text(
                  "User account couldn’t be created; perhaps it’s already registered")
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
              hintText: 'make up a password',
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
          if (!doPasswordsMatch) const Text("passwords don’t match") else Text(""),
          Text(registerError),
          Expanded(
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    model.setDoesUserWantToRegister(false);
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
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
                              print("inside setstate 2");
                              registerError = onError.toString();
                            });
                            // we can set a variable here to true to indicate there
                            // was an error and call setstate on it
                            // somewhere else we check it and display the error message here
                          });
                        },
                  child: const Text("Submit"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kProgramName),),
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
