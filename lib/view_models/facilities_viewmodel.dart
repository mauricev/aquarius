import 'package:flutter/material.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../views/consts.dart';
import '../views/utility.dart';
import '../models/rack_model.dart';

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

  FacilityViewModel(this._manageSession);

  String returnFacilityId() {
    return documentId;
  }

  void addRack(int absolutePosition, String relativePosition) {
    myPrint(
        "adding the rack $relativePosition at position $absolutePosition");
    Rack aRack = Rack(absolutePosition, relativePosition);
    rackList.add(aRack);
  }

  void clearRacks() {
    myPrint("clearing racks");
    rackList.clear();
  }

  void deleteRack(int index) {
    myPrint("deleting rack at index $index");
    rackList.removeAt(index);
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
      Query.equal("facility_fk", inDocumentId), // I just changed the code to use the passed ID.
    ];
    return await _manageSession.queryDocument(cRackCollection, rackQuery);
  }

  Future<int?> returnRacksAbsolutePosition(String inRackFk) async {

    List<String>? rackQuery = [
      Query.equal("\$id", inRackFk),
    ];

    myPrint("IN returnRacksAbsolutePosition, $inRackFk");
    models.DocumentList theRackList = await _manageSession.queryDocument(
        cRackCollection, rackQuery);
    myPrint("theRackList is ${theRackList.documents[0]}");

    models.Document theRack = theRackList.documents[0];
    myPrint("rack document id is ${theRack.$id}");
    myPrint("theRack is ${theRack.data}");
    int absolutePosition = theRack.data["absolute_position"];
    myPrint("rack absolutePosition is $absolutePosition");

    return absolutePosition; // possible bug here, doesn't want await
  }

  Future<String> returnRacksRelativePosition(String inRackFk) async {

    List<String>? rackQuery = [
      Query.equal("\$id", inRackFk),
    ];

    myPrint("IN returnRacksRelativePosition, $inRackFk");
    models.DocumentList theRackList = await _manageSession.queryDocument(
        cRackCollection, rackQuery);
    myPrint("theRackList is ${theRackList.documents[0]}");

    models.Document theRack = theRackList.documents[0];
    myPrint("rack document id is ${theRack.$id}");
    myPrint("theRack is ${theRack.data}");
    String relativePosition = theRack.data["relative_position"];
    myPrint("rack position is $relativePosition");

    return relativePosition; // possible bug here, doesn't want await
  }

  Future<String?> returnSpecificRack(int absolutePosition) async {

    List<String>? rackQuery = [
      Query.equal("facility_fk", documentId),
      Query.equal("absolute_position", absolutePosition),
    ];

    myPrint("facility_fk is $documentId and abs pos is $absolutePosition");

    models.DocumentList theRackList = await _manageSession.queryDocument(
        cRackCollection, rackQuery);

    models.Document theRack = theRackList.documents[0];

    return theRack.$id;
  }

  Future<void> getFacilityInfo(String? theFacilityFk) async {
    if (theFacilityFk != null) {
      // if we are null, then we are in the new facility page

      models.Document theFacility = await _manageSession.getDocument(
          kFacilityCollection, theFacilityFk);

      documentId = theFacility.$id;
      facilityName = theFacility.data['facility_name'];
      facilityBuilding = theFacility.data['facility_building'];
      facilityRoom = theFacility.data['facility_room'];
      gridHeight = theFacility.data['grid_height'];
      gridWidth = theFacility.data['grid_width'];
      maxShelves = theFacility.data['max_shelves'];
      maxTanks = theFacility.data['max_tanks'];

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
      rackList.clear();
    }
  }

  //save facility is only for new facilities
  Future<void> saveFacility() async {
    // need to update any existing facility

    Map<String, dynamic> theFacilityMap = {
      'facility_name': facilityName,
      'facility_building': facilityBuilding,
      'facility_room': facilityRoom,
      'grid_height': gridHeight,
      'grid_width': gridWidth,
      'max_shelves': maxShelves,
      'max_tanks' : maxTanks,
    };

    models.Document theFacility;
    // we assigned document_id if there is one in this istheFacilitySaved function
    if (documentId == "") {
      // this is a new facility; give it a new id
      theFacility = await _manageSession.createDocument(  // we have to await to get the new facility id
          theFacilityMap, kFacilityCollection); // how does document_id get updated? elsewhere apparently
    } else {
      theFacility = await _manageSession.updateDocument( // since we are using facility id, we need to wait
          theFacilityMap, kFacilityCollection, documentId);
      myPrint("is facility id right? facility is ${theFacility.$id} and saved value is $documentId");
    }

    for (int theIndex = 0; theIndex < rackList.length; theIndex++) {

      Map<String, dynamic> theRackMap = {
        'relative_position': rackList[theIndex].relativePosition,
        'absolute_position': rackList[theIndex].absolutePosition,
        'facility_fk': theFacility.$id,
      };

      List<String>? rackQuery = [
        Query.equal("facility_fk", theFacility.$id), //we need the facility id; it could be a new facility with a new id
        Query.equal("absolute_position", rackList[theIndex].absolutePosition),
      ];

      myPrint("the facility being saved is ${theFacility.$id}");

      models.DocumentList theRackList = await _manageSession.queryDocument(cRackCollection, rackQuery);

      if (theRackList.total > 0) { // racks are already existing
        myPrint("we found an existing rack, ${theRackList.documents[0].$id}");
        await _manageSession.updateDocument(
        theRackMap, cRackCollection, theRackList.documents[0].$id);
      } else {
        myPrint('we are saving a new rack, ${rackList[theIndex].relativePosition}'); // how did this rack get created? we gave it a name.
        await _manageSession.createDocument(theRackMap, cRackCollection); // if this fails, we created on an existing rack in error
      }
     }
  }
}
