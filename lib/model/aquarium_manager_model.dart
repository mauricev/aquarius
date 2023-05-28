import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';

import 'package:aquarium_manager/model/sessionKey.dart';

import 'package:appwrite/models.dart' as models;

class MyAquariumManagerModel with ChangeNotifier {
  final cFacilityNameKey = "faciltyNameKey";
  final ManageSession _manageSession;
  String? selectedFacility; // we start out with no facility selected

  void AssignSavedFacility() async {
    selectedFacility = await _manageSession.RetrieveFromSecureStorage(cFacilityNameKey);
    print("the saved facility is ${selectedFacility}");
  }

  MyAquariumManagerModel(this._manageSession ) {
    print('aquarium_manager_model.dart ONE');
    AssignSavedFacility();
    notifyListeners();
  }

  void setSelectedFacility(String? facility_name) {
    selectedFacility = facility_name;
    _manageSession.SetToSecureStorage(cFacilityNameKey, selectedFacility);
    print("saved facility to storage");
  }

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
    setUserAccountJustCreated(); // calls notifyListeners a second time
  }

  bool getUserAccountJustCreated() {
    return _manageSession.getUserAccountJustCreated();
  }

  void setUserAccountJustCreated() {
    _manageSession.setUserAccountJustCreated();
    notifyListeners();
  }

  Future<models.User> modelRetrieveSession() async {
    return _manageSession.retrieveSession();
  }

  bool checkSetBadUserPassword(String tempSessionValue) {
    return _manageSession.checkSetBadUserPassword(tempSessionValue);
  }

  void setBadUserPassword (bool badUserPasswd) {
    _manageSession.setBadUserPassword(badUserPasswd);
    notifyListeners();
  }

  bool getIsUserPasswordBad() {
    return _manageSession.getIsUserPasswordBad();
  }
// errors we need to handle;
  // 1 user registering an already registered user
  // 2 user mistyping password twice
  // 3 user typing bad username or password
  // I don’t recognize this user/password combination

  Future<models.Session> loginUser(String username, String password) async {
    print("model loginUser, ${username} and password, ${password}");
    return _manageSession.loginUser(username, password);
  }

  Future<List<String>> getFacilityNames() async {
    List<String>? query = [
      Query.notEqual("facility_name", [""]) // empty string should bring back all facilities
    ];
    models.DocumentList documentList = await _manageSession.queryDocument("63eefc630814627ea850",query);
    // Extract the facility names from the list of documents
    List<String> facilityNames = documentList.documents
        .map((document) => document.data['facility_name'].toString())
        .toList();

    return facilityNames;
  }
}