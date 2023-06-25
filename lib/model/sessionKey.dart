import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aquarium_manager/views/consts.dart';

enum loginStatus {
  loginNotYetAttempted,
  loginAwaiting,
  loginSuccessful,
  loginFailed
}

class ManageSession {
  Client _client = Client(); // prepared inside _create
  final _storage = const FlutterSecureStorage();
  //late final SharedPreferences _storage;

  bool _doesUserWantToRegister = false;
  bool _userAccountJustCreated = false;
  bool _userAccountFailedToRegister = false;
  bool _badUserPassword = false;

  ManageSession._create() {
    print('sessionKey THREE, ManageSession._create');
    _client.setEndpoint(kIPAddress);
    _client.setProject(kProjectId);
    _client.setSelfSigned(status: true); // For self signed certificates, only use for development
  }

  Future<String?> RetrieveFromSecureStorage(String keyToRetrieve) async {
    return await _storage.read(key: keyToRetrieve);
  }

  void SetToSecureStorage(String keyToSave, String? valueToSave) async {
    _storage.write(key: keyToSave, value: valueToSave);
  }

  static Future<ManageSession> create() async {
    print('sessionKey TWO, Future<ManageSession> create');

    // Call the private constructor
    ManageSession managedSession = ManageSession._create();

    print('FOUR, ManageSession');
    // Return the fully initialized object
    return managedSession;
  }

  bool getDoesUserWantToRegister() {
    return _doesUserWantToRegister;
  }

  bool getFailedToRegister() {
    return _userAccountFailedToRegister; // true is unexpected response
  }

  void setFailedToRegister(bool failedToRegister) {
    _userAccountFailedToRegister = failedToRegister;
  }

  void setDoesUserWantToRegister(bool userRegisterState) {
    _doesUserWantToRegister = userRegisterState;
    //setUserAccountJustCreated(); // must be called by model because model notfies listeners
  }

  bool getUserAccountJustCreated() {
    return _userAccountJustCreated;
  }

  void setUserAccountJustCreated() {
    _userAccountJustCreated = true;
  }

  Future<dynamic> logOut() async {
    Account theAccount = Account(_client);

     return theAccount.deleteSession(
      sessionId: 'current',
    );
  }

  Future<models.User> retrieveSession() async {
    Account theAccount = Account(_client);

    print("inside retrieveSession, about to account.get()");
    return theAccount.get();
  }

  // this class intentionally ignores the return string
  Future<models.User> registerUser(String email, String password) async {
    Account theAccount = Account(_client);

    print("about to register 2");

    models.User theUser = await theAccount.create(
      userId: ID.unique(),
      email: email,
      password: password,
    );
    print("about to register 3, ${theUser}");
    return theUser;
  }

  bool checkSetBadUserPassword(String tempSessionValue) {
    bool passwordInvalid = (tempSessionValue == "bad user/password");
    setBadUserPassword (passwordInvalid);
    return passwordInvalid;
  }

  void setBadUserPassword (bool badUserPasswd) {
    _badUserPassword = badUserPasswd;
  }

  bool getIsUserPasswordBad() {
    return _badUserPassword;
  }

  Future<models.Session> loginUser(String email, String password) async {
    Account theAccount = Account(_client);

    setBadUserPassword(false); // controller will reset this in the then clause

    print("we are in session, loginUser");
    return theAccount.createEmailSession(
      email: email,
      password: password,
    );
  }

  Future<models.Document> createDocument(Map<dynamic, dynamic> data, String collectionId) {
    Databases theDatabase = Databases(_client);

    String theDocumentID = ID.unique();
    print("the document id is ${theDocumentID}");
    return theDatabase.createDocument(
      databaseId: kDatabaseId,
      collectionId: collectionId,
      documentId: theDocumentID,
      data: data, // we pass the data raw!
    );
  }

  Future<models.Document> updateDocument(Map<dynamic, dynamic> data, String collectionId, String documentId) {
    Databases theDatabase = Databases(_client);

    return theDatabase.updateDocument(
      databaseId: kDatabaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: data, // we pass the data raw!
    );
  }

  Future<void> deleteDocument(String collectionId, String documentId) {
    Databases theDatabase = Databases(_client);

    return theDatabase.deleteDocument(
      databaseId: kDatabaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }

  Future<models.DocumentList> queryDocument(String collectionId, List<String>? queries) {
    Databases theDatabase = Databases(_client);
    return theDatabase.listDocuments(
        databaseId: kDatabaseId,
        collectionId: collectionId,
        queries: queries,
    );
  }
}
