import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../views/consts.dart';
import '../views/utility.dart';

enum LoginStatus {
  loginNotYetAttempted,
  loginAwaiting,
  loginSuccessful,
  loginFailed
}

class ManageSession {
  final Client _client = Client();
  // BUGfixed 2024-03-02
  // I added FlutterSecureFileStorage because for some reason FlutterSecureStorage wasn't saving to the keychain
  // this is true for MacOS and might relate to needing applicationSupportsSecureRestorableState on the Mac
  // FlutterSecureFileStorage is showing in unhandled exception, reported as a bug
  //final _storage = FlutterSecureFileStorage(const FlutterSecureStorage());
  final _storage = const FlutterSecureStorage();

  bool _doesUserWantToRegister = false;
  bool _userAccountJustCreated = false;
  bool _userAccountFailedToRegister = false;
  bool _badUserPassword = false;

  ManageSession() {
    _client.setEndpoint(kIPAddress);
    _client.setProject(kProjectId);
    // local, real-world difference
    if(kRunningLocal) {
      _client.setSelfSigned(status: true);
    }
  }

  Future<String?> retrieveFromSecureStorage(String keyToRetrieve) async {
    return await _storage.read(key: keyToRetrieve);
  }

  void setToSecureStorage(String keyToSave, String? valueToSave) async {
    _storage.write(key: keyToSave, value: valueToSave);
  }

  void deleteSecureStorage(String keyToDelete) async {
    await _storage.delete(key: keyToDelete);
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

  void setUserAccountJustCreated(bool accountCreated) {
    _userAccountJustCreated = accountCreated;
  }

  Future<dynamic> logOut() async {
    Account theAccount = Account(_client);

     return theAccount.deleteSession(
      sessionId: 'current',
    );
  }

  Future<models.User> retrieveSession() async {
    Account theAccount = Account(_client);
    return theAccount.get();
  }

  // this class intentionally ignores the return string
  Future<models.User> registerUser(String email, String password) async {
    Account theAccount = Account(_client);

    models.User theUser = await theAccount.create(
      userId: ID.unique(),
      email: email,
      password: password,
    );
    return theUser;
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

    myPrint("we are in session, loginUser");
    return theAccount.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  Future<models.Document> createDocument(Map<dynamic, dynamic> data, String collectionId) {
    Databases theDatabase = Databases(_client);

    String theDocumentID = ID.unique();

    return theDatabase.createDocument(
      databaseId: kDatabaseId,
      collectionId: collectionId,
      documentId: theDocumentID,
      data: data, // we pass the data raw!
    );
  }

  Future<models.Document> updateDocument(Map<dynamic, dynamic> data, String collectionId, String documentId) async {
    try {
      Databases theDatabase = Databases(_client);

      return await theDatabase.updateDocument(
        databaseId: kDatabaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data, // we pass the data raw!
      );
    } catch (e) {
      myPrint("Error updating document: $e");
      rethrow;  // we rethrow so the caller can put up a dialog
    }
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

  Future<models.Document> getDocument(String collectionId, String documentId) {
    Databases theDatabase = Databases(_client);

    return theDatabase.getDocument(
      databaseId: kDatabaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }
}
