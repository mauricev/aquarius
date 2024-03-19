import 'package:flutter/material.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../views/consts.dart';
import '../models/rack_model.dart';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class FacilityViewModel with ChangeNotifier {
  final ManageSession _manageSession;
  List<Rack> rackList = <Rack>[];

  String? facilityName;
  String documentId = "";
  String facilitySite = "";
  String facilityBuilding = "";
  String facilityRoom = "";
  int maxShelves = 0;
  int maxTanks = 0;
  int gridHeight = 0;
  int gridWidth = 0;
  bool? entranceBottom;

  String?
      selectedFacility; // we start out with no facility selected; this value is null
  String? lastSelectedFacility;

  Future<void> loadUpSavedFacility() async {
    // when we need to test with no saved facility
    // 5 of 5
    // remove for real-world
    //_manageSession.deleteSecureStorage(cFacilityNameKey); //<- must be commented out for real-world

    selectedFacility =
        await _manageSession.retrieveFromSecureStorage(cFacilityNameKey);
  }

  FacilityViewModel(this._manageSession) {
    loadUpSavedFacility().then((value) => notifyListeners());
  }

  void setSelectedFacility(String? facilityFk) {
    selectedFacility = facilityFk;
    _manageSession.setToSecureStorage(cFacilityNameKey, selectedFacility);
  }

  void rememberSelectedFacility() {
    lastSelectedFacility = selectedFacility;
  }

  String? restoreRememberedFacility() {
    return lastSelectedFacility;
  }

  Future<List<Map<String, String>>> getFacilityNames2() async {
    List<Map<String, String>> facilitiesNameList = [];

    List<String>? query = [
      Query.notEqual(
          "facility_name", [""]) // empty string brings back all facilities
    ];

    models.DocumentList facilitiesDocumentList =
        await _manageSession.queryDocument(kFacilityCollection, query);

    for (int theIndex = 0;
        theIndex < facilitiesDocumentList.total;
        theIndex++) {
      models.Document theFacility = facilitiesDocumentList.documents[theIndex];

      Map<String, String> facilityData = {
        'facility_name': theFacility.data['facility_name'].toString(),
        'facility_fk': theFacility.$id,
      };

      facilitiesNameList.add(facilityData);
    }

    return facilitiesNameList;
  }

  Future<String?> convertFacilityFkToFacilityName(String facilityFk) async {
    List<Map<String, String>> facilitiesList = await getFacilityNames2();
    for (int theIndex = 0; theIndex < facilitiesList.length; theIndex++) {
      if (facilitiesList[theIndex]['facility_fk'] == facilityFk) {
        return facilitiesList[theIndex]['facility_name'];
      }
    }
    return ""; // should we return empty string or no associated facility
  }

  String? returnSelectedFacility() {
    return selectedFacility;
  }

  bool isAFacilitySelectedAndOnIos() {
    return (returnSelectedFacility() != null) &
        (defaultTargetPlatform == TargetPlatform.iOS);
  }

  bool isAFacilitySelected() {
    return returnSelectedFacility() != null;
  }

  bool pretendFacilityIsAlwaysSelected() {
    return returnSelectedFacility() ==
        null; // if a facility is not selected, return true
  }

  bool pretendFacilityIsIrrelevant() {
    return true; // if a facility is not selected, return true
  }

  void addRack(int absolutePosition, String relativePosition) {
    Rack aRack = Rack(absolutePosition, relativePosition);
    rackList.add(aRack);
  }

  void clearRacks() {
    rackList.clear();
  }

  void deleteRack(int index) {
    rackList.removeAt(index);
  }

  bool? isEntranceAtBottom() {
    return entranceBottom;
  }

  void setEntranceBottom(bool? isEntranceAtBottom) {
    entranceBottom = isEntranceAtBottom;
    notifyListeners();
  }

  // we use the editable version of the list here
  String relativePositionOfRackWithThisAbsolutePosition(int absolutePosition) {
    for (int theIndex = 0; theIndex < rackList.length; theIndex++) {
      if (rackList[theIndex].absolutePosition == absolutePosition) {
        return rackList[theIndex].relativePosition;
      }
    }
    return "";
  }

  int indexOfRackWithThisAbsolutePosition(int absolutePosition) {
    for (int theIndex = 0; theIndex < rackList.length; theIndex++) {
      if (rackList[theIndex].absolutePosition == absolutePosition) {
        return theIndex;
      }
    }
    return -1;
  }

  // this code was using the internal document id and
  // and now I changed it to using the passed one instead
  Future<models.DocumentList> returnAssociatedRackList(
      String inDocumentId) async {
    List<String>? rackQuery = [
      Query.equal("facility_fk",
          inDocumentId), // I just changed the code to use the passed ID.
    ];
    return await _manageSession.queryDocument(cRackCollection, rackQuery);
  }

  Future<int?> returnRacksAbsolutePosition(String inRackFk) async {
    List<String>? rackQuery = [
      Query.equal("\$id", inRackFk),
    ];

    models.DocumentList theRackList =
        await _manageSession.queryDocument(cRackCollection, rackQuery);

    models.Document theRack = theRackList.documents[0];

    int absolutePosition = theRack.data["absolute_position"];

    return absolutePosition; // possible bug here, doesn't want await
  }

  Future<String> returnRacksRelativePosition(String inRackFk) async {
    List<String>? rackQuery = [
      Query.equal("\$id", inRackFk),
    ];

    models.DocumentList theRackList =
        await _manageSession.queryDocument(cRackCollection, rackQuery);

    models.Document theRack = theRackList.documents[0];

    String relativePosition = theRack.data["relative_position"];

    return relativePosition;
  }

  Future<String?> returnSpecificRack(int absolutePosition) async {
    List<String>? rackQuery = [
      Query.equal("facility_fk", documentId),
      Query.equal("absolute_position", absolutePosition),
    ];

    models.DocumentList? theRackList =
        await _manageSession.queryDocument(cRackCollection, rackQuery);

    // BUGfixed put in check for when no selected rack is queried about
    if (theRackList.documents.isEmpty) {
      return null;
    }
    models.Document theRack = theRackList.documents[0];
    return theRack.$id;
  }

  Future<void> getFacilityInfo(String? theFacilityFk) async {
    if (theFacilityFk != null) {
      // if we are null, then we are in the new facility page

      models.Document theFacility =
          await _manageSession.getDocument(kFacilityCollection, theFacilityFk);

      documentId = theFacility.$id; // this is the same as the theFacilityFk
      facilityName = theFacility.data['facility_name'];
      facilityBuilding = theFacility.data['facility_building'];
      facilityRoom = theFacility.data['facility_room'];
      gridHeight = theFacility.data['grid_height'];
      gridWidth = theFacility.data['grid_width'];
      maxShelves = theFacility.data['max_shelves'];
      maxTanks = theFacility.data['max_tanks'];
      entranceBottom = theFacility.data['entrance_at_bottom'];

      models.DocumentList theRackList =
          await returnAssociatedRackList(documentId);

      clearRacks(); // be sure we have no lingering racks

      for (int theIndex = 0; theIndex < theRackList.total; theIndex++) {
        models.Document theRack = theRackList.documents[theIndex];

        addRack(theRack.data['absolute_position'],
            theRack.data['relative_position']);
      }
    } else {
      facilityName = null;
      documentId = "";
      facilityBuilding = "";
      facilityRoom = "";
      maxShelves = 0;
      maxTanks = 0;
      gridHeight = 0;
      gridWidth = 0;
      entranceBottom = null;
      clearRacks();
    }
  }

  //save facility is only for new facilities; this also saves the racks for this facility
  Future<void> saveFacility() async {
    // need to update any existing facility

    Map<String, dynamic> theFacilityMap = {
      'facility_name': facilityName,
      'facility_building': facilityBuilding,
      'facility_room': facilityRoom,
      'grid_height': gridHeight,
      'grid_width': gridWidth,
      'max_shelves': maxShelves,
      'max_tanks': maxTanks,
      'entrance_at_bottom': entranceBottom,
    };

    models.Document theFacility;
    // we assigned document_id if there is one in this istheFacilitySaved function
    if (documentId == "") {
      // this is a new facility; give it a new id
      theFacility = await _manageSession.createDocument(
          // we have to await to get the new facility id
          theFacilityMap,
          kFacilityCollection); // how does document_id get updated? we haven't selected this facility yet; it gets assigned when the user picks it
    } else {
      theFacility = await _manageSession.updateDocument(
          // since we are using facility id, we need to wait
          theFacilityMap,
          kFacilityCollection,
          documentId);
    }

    // save off each rack associated with this facility
    for (int theIndex = 0; theIndex < rackList.length; theIndex++) {
      Map<String, dynamic> theRackMap = {
        'relative_position': rackList[theIndex].relativePosition,
        'absolute_position': rackList[theIndex].absolutePosition,
        'facility_fk': theFacility.$id,
      };

      List<String>? rackQuery = [
        Query.equal(
            "facility_fk",
            theFacility
                .$id), // we need the facility id; it could be a new facility with a new id
        Query.equal("absolute_position", rackList[theIndex].absolutePosition),
      ];

      models.DocumentList theRackList =
          await _manageSession.queryDocument(cRackCollection, rackQuery);

      if (theRackList.total > 0) {
        // racks are already existing
        await _manageSession.updateDocument(
            theRackMap, cRackCollection, theRackList.documents[0].$id);
      } else {
        await _manageSession.createDocument(theRackMap,
            cRackCollection); // if this fails, we created on an existing rack in error
      }
    }
  }
}
