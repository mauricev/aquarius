import 'package:flutter/material.dart';
import 'package:aquarium_manager/model/sessionKey.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:aquarium_manager/views/consts.dart';

class Rack {
  int absolutePosition = 0;
  String relativePosition = "";
  int facility_fk = 0;

  Rack(this.absolutePosition, this.relativePosition);
}

class MyAquariumManagerFacilityModel with ChangeNotifier {
  final ManageSession _manageSession;
  List<Rack> rackList = <Rack>[];

  String? facilityName;
  String document_id = "";
  String facilitySite = "";
  String facilityBuilding = "";
  String facilityRoom = "";
  int maxShelves = 0;
  int maxTanks = 0;
  int gridHeight = 0;
  int gridWidth = 0;

  MyAquariumManagerFacilityModel(this._manageSession);

  void addRack(int absolutePosition, String relativePosition) {
    print(
        "adding the rack ${relativePosition} at position ${absolutePosition}");
    Rack aRack = Rack(absolutePosition, relativePosition);
    rackList.add(aRack);
  }

  void clearRacks() {
    print("clearing racks");
    rackList.clear();
  }

  void deleteRack(int index) {
    print("deleting rack at index ${index}");
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

  Future<models.DocumentList> returnAssociatedRackList(
      String document_Id) async {

    List<String>? rackQuery = [
      Query.equal("facility_fk", document_id),
    ];
    return await _manageSession.queryDocument(cRackCollection, rackQuery);
  }

  Future<int?> returnRacksAbsolutePosition(String inRack_Fk) async {

    List<String>? rackQuery = [
      Query.equal("\$id", inRack_Fk),
    ];

    print("IN returnRacksAbsolutePosition, ${inRack_Fk}");
    models.DocumentList theRackList = await _manageSession.queryDocument(
        cRackCollection, rackQuery);
    print("theRackList is ${theRackList.documents[0]}");

    models.Document theRack = theRackList.documents[0];
    print("rack document id is ${theRack.$id}");
    print("theRack is ${theRack.data}");
    int absolutePosition = theRack.data["absolute_position"];
    print("rack absolutePosition is ${absolutePosition}");

    return absolutePosition; // possible bug here, doesn't want await
  }

  Future<String?> returnSpecificRack(int absolutePosition) async {

    List<String>? rackQuery = [
      Query.equal("facility_fk", document_id),
      Query.equal("absolute_position", absolutePosition),
    ];

    print("facility_fk is ${document_id} and abs pos is ${absolutePosition}");

    models.DocumentList theRackList = await _manageSession.queryDocument(
        cRackCollection, rackQuery);

    models.Document theRack = theRackList.documents[0];

    return theRack.$id;
  }

  Future<void> getFacilityInfo(String? theFacilityName) async {
    if (theFacilityName != null) {
      // if we are null, then we are in the new facility page
      print("we are entering an existing facility, ${theFacilityName}");
      List<String>? facilityQuery = [
        Query.equal("facility_name", theFacilityName),
      ];

      models.DocumentList theFacilityList = await _manageSession.queryDocument(
          kFacilityCollection, facilityQuery);
      models.Document theFacility = theFacilityList.documents[0];

      document_id = theFacility.$id;
      facilityName = theFacility.data['facility_name'];
      facilityBuilding = theFacility.data['facility_building'];
      facilityRoom = theFacility.data['facility_room'];
      gridHeight = theFacility.data['grid_height'];
      gridWidth = theFacility.data['grid_width'];
      maxShelves = theFacility.data['max_shelves'];
      maxTanks = theFacility.data['max_tanks'];

      models.DocumentList theRackList =
          await returnAssociatedRackList(document_id);

      clearRacks(); // be sure we have no lingering racks

      for (int theIndex = 0; theIndex < theRackList.total; theIndex++) {
        models.Document theRack = theRackList.documents[theIndex];

        addRack(theRack.data['absolute_position'],
            theRack.data['relative_position']);
      }

    } else {

      facilityName = null;
      document_id = "";
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
    if (document_id == "") {
      // this is a new facility; give it a new id
      theFacility = await _manageSession.createDocument(  // we have to await to get the new facility id
          theFacilityMap, kFacilityCollection); // how does document_id get updated? elsewhere apparently
    } else {
      theFacility = await _manageSession.updateDocument( // since we are using facility id, we need to wait
          theFacilityMap, kFacilityCollection, document_id);
      print("is facility id right? facility is ${theFacility.$id} and saved value is ${document_id}");
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

      print("the facility being saved is ${theFacility.$id}");

      models.DocumentList theRackList = await _manageSession.queryDocument(cRackCollection, rackQuery);

      if (theRackList.total > 0) { // racks are already existing
        print("we found an existing rack, ${theRackList.documents[0].$id}");
        await _manageSession.updateDocument(
        theRackMap, cRackCollection, theRackList.documents[0].$id);
      } else {
        print('we are saving a new rack, ${rackList[theIndex].relativePosition}'); // how did this rack get created? we gave it a name.
        await _manageSession.createDocument(theRackMap, cRackCollection); // if this fails, we created on an existing rack in error
      }
     }
  }
}
