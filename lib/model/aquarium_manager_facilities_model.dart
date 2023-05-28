import 'package:flutter/material.dart';

import 'package:aquarium_manager/model/sessionKey.dart';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

const String cFacilityCollection = '63eefc630814627ea850';
const String cRackCollection = '63f97b76c200d9237cea';
const String cTankCollection = '6408223c577dec6908e7';
const String cNotesCollection = '64239dc4f03b6125e61d';

class Rack {
  int absolutePosition = 0;
  String relativePosition = "";
  int facility_fk = 0;

  Rack(this.absolutePosition, this.relativePosition);
}

class MyAquariumManagerFacilityModel with ChangeNotifier {
  final ManageSession _manageSession;
  List<Rack> rackList = <Rack>[];

  String? facilityName = null;
  String document_id = "";
  String facilitySite = "";
  String facilityBuilding = "";
  String facilityRoom = "";
  int maxShelves = 0;
  int maxTanks = 0;
  int gridHeight = 0;
  int gridWidth = 0;

  MyAquariumManagerFacilityModel(this._manageSession) {
  }

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

  Future<models.DocumentList> isFacilityAlreadySaved() async {
    List<String>? query = [
      Query.equal("facility_name", facilityName),
    ];
    print("about to query facility list for this specific facility name");
    return await _manageSession.queryDocument(cFacilityCollection, query);
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

    return await absolutePosition;
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
          cFacilityCollection, facilityQuery);
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
  Future<List<dynamic>> saveFacility() async {
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
    List<Future> theFutureList = [];
    models.Document theFacility;
    // we assigned document_id if there is one in this istheFacilitySaved function
    if (document_id == "") {
      // this is a new facility; give it a new id
      theFacility = await _manageSession.createDocument(
          theFacilityMap, cFacilityCollection);
    } else {
      theFacility = await _manageSession.updateDocument(
          theFacilityMap, cFacilityCollection, document_id);

      // query all the associated racks and delete them all by putting this in the future list
      models.DocumentList theRackList =
          await returnAssociatedRackList(document_id);
      for (int theIndex = 0; theIndex < theRackList.total; theIndex++) {
        await _manageSession.deleteDocument(
            cRackCollection, theRackList.documents[theIndex].$id);
      }
    }
    // if there had been any saved racks, we have deleted them. Now we’re re-adding them.
    for (int theIndex = 0; theIndex < rackList.length; theIndex++) {
      Map<String, dynamic> theRackMap = {
        'relative_position': rackList[theIndex].relativePosition,
        'absolute_position': rackList[theIndex].absolutePosition,
        'facility_fk': theFacility.$id,
      };

      theFutureList.add(Future.delayed(const Duration(milliseconds: 1000), () {
        _manageSession.createDocument(theRackMap, cRackCollection);
      }));
    }
    return Future.wait(theFutureList);
  }
}
