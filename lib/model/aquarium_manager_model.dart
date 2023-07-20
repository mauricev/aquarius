import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:aquarium_manager/model/session_key.dart';
import 'package:appwrite/models.dart' as models;
import 'package:aquarium_manager/views/consts.dart';
import 'package:aquarium_manager/views/utility.dart';

class MyAquariumManagerModel with ChangeNotifier {
  final cFacilityNameKey = "faciltyNameKey";
  final ManageSession _manageSession;
  String? selectedFacility; // we start out with no facility selected; this value is null

  void assignSavedFacility() async {
    // when we need to test with no saved facility
    _manageSession.deleteSecureStorage(cFacilityNameKey);

    selectedFacility = await _manageSession.retrieveFromSecureStorage(cFacilityNameKey);


    myPrint("the saved facility is $selectedFacility");
  }

  MyAquariumManagerModel(this._manageSession ) {
    assignSavedFacility();
    notifyListeners();
  }

  void setSelectedFacility(String? facilityName) {
    selectedFacility = facilityName;
    _manageSession.setToSecureStorage(cFacilityNameKey, selectedFacility);
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
    myPrint("about to register 1");
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

  void callNotifyListeners() {
    notifyListeners();
  }

  Future<dynamic> logOut() async {
    return _manageSession.logOut();
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
    return _manageSession.loginUser(username, password);
  }

  /*Future<List<String>> getFacilityNames() async {
    List<String>? query = [
      Query.notEqual("facility_name", [""]) // empty string should bring back all facilities
    ];
    models.DocumentList documentList = await _manageSession.queryDocument(kFacilityCollection,query);
    // Extract the facility names from the list of documents
    List<String> facilityNames = documentList.documents
        .map((document) => document.data['facility_name'].toString())
        .toList();
    return facilityNames;
  }*/

  Future<List<Map<String, String>>> getFacilityNames2() async {
    List<Map<String, String>> facilitiesNameList = [];

    List<String>? query = [
      Query.notEqual("facility_name", [""]) // empty string should bring back all facilities
    ];

    models.DocumentList facilitiesDocumentList = await _manageSession.queryDocument(kFacilityCollection,query);

    for (int theIndex = 0; theIndex < facilitiesDocumentList.total; theIndex++) {
      models.Document theFacility = facilitiesDocumentList.documents[theIndex];

      Map<String, String> facilityData = {
        'facility_name': theFacility.data['facility_name'].toString(),
        'facility_fk': theFacility.$id,
      };

      myPrint("the facility map is ${facilityData}");
      facilitiesNameList.add(facilityData);
    }

    return facilitiesNameList;
  }

  String? returnSelectedFacility() {
   return selectedFacility;
  }
}