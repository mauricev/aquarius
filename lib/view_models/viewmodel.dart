import 'package:flutter/material.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;

class AquariusViewModel with ChangeNotifier {

  final ManageSession _manageSession;

  bool badPassword = false;

  AquariusViewModel(this._manageSession );

  bool getDoesUserWantToRegister() {
    return _manageSession.getDoesUserWantToRegister();
  }

  bool getFailedToRegister() {
    return _manageSession.getFailedToRegister();
  }

  void setFailedToRegister(bool failedToRegister) {
    _manageSession.setFailedToRegister(failedToRegister);
    notifyListeners();
  }

  // even this class temporarily ignores the return string
  Future registerUser(String email, String password) {
    setFailedToRegister(false);
    return _manageSession.registerUser(email, password);
  }

  void setDoesUserWantToRegister(bool userRegisterState) {
    _manageSession.setDoesUserWantToRegister(userRegisterState);
    notifyListeners();
    setUserAccountJustCreated(userRegisterState); // calls notifyListeners a second time
  }

  bool getUserAccountJustCreated() {
    return _manageSession.getUserAccountJustCreated();
  }

  void setUserAccountJustCreated(bool accountCreated) {
    _manageSession.setUserAccountJustCreated(accountCreated);
    notifyListeners();
  }

  Future<models.User> modelRetrieveSession() async {
    return _manageSession.retrieveSession();
  }

  Future<dynamic> logOut() async {
    return _manageSession.logOut();
  }

  void setBadUserPassword (bool badUserPasswd) {
    _manageSession.setBadUserPassword(badUserPasswd);
    badPassword = badUserPasswd;
    notifyListeners();
  }

  bool getIsUserPasswordBad() {
    return badPassword;
  }
// errors we need to handle;
  // 1 user registering an already registered user
  // 2 user mistyping password twice
  // 3 user typing bad username or password
  // I don’t recognize this user/password combination

  Future<models.Session> loginUser(String username, String password) async {
    return _manageSession.loginUser(username, password);
  }
}