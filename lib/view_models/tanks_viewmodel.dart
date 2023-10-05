import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;
import 'facilities_viewmodel.dart';
import '../views/consts.dart';
import '../views/utility.dart';
import '../models/tank_model.dart';


class TanksViewModel with ChangeNotifier {
  final ManageSession _manageSession;

  List<Tank> tankList = <Tank>[];

  int selectedRack = -2; // this is a rack cell, not a tank cell
  int selectedTankCell = kEmptyTankIndex;
  String rackDocumentid = "";

  void callNotifyListeners() {
    notifyListeners();
  }

  void addTankFromDatabase(
      String documentId,
      String facilityFk,
      String rackFk,
      int absolutePosition,
      String? tankLine,
      int birthDate,
      bool? screenPositive,
      int? numberOfFish,
      int? fatTankPosition,
      int? generation) {
    Tank aTank = Tank(
        documentId: documentId,
        facilityFk: facilityFk,
        rackFk: rackFk,
        absolutePosition: absolutePosition,
        tankLine: tankLine,
        birthDate: birthDate,
        screenPositive: screenPositive,
        numberOfFish: numberOfFish,
        fatTankPosition: fatTankPosition,
        generation: generation,
        manageSession: _manageSession);
    tankList.add(aTank);
  }

  /*
   is a tank ever created in the cParkedRackAbsPosition position? I don’t think so
   if it is, what happens to fatTankPosition?
   */
  void addNewEmptyTank(String facilityFk, int absolutePosition, int? fatTankPosition) async {
    Tank aTank = Tank(
        documentId:
            null, // the tank entry is new, so it doesn’t have a document ID yet
        facilityFk: facilityFk,
        rackFk: (absolutePosition == cParkedRackAbsPosition)
            ? "0"
            : rackDocumentid, // saved from when we switch racks; we always get it from the database
        absolutePosition: absolutePosition,
        tankLine: "",
        birthDate: returnTimeNow() - kStartingDOBOffset,
        screenPositive: true,
        numberOfFish: 1,
        fatTankPosition: fatTankPosition, // value will be decided based whether user has chosen a fat tank; we will need abs position of next tank
        generation: 1,
        manageSession: _manageSession);
    tankList.add(aTank);

    // we don't add the virtual portion of a fat tank to the database
    // we know there is a fat tank because the parent tank will have a value in fatTankPosition
    // I am thinking that the virtual pair of a fat tank doesn't even need to know its parent
    // this part of a fat tank simply exists in the tank list and nowhere else
    // it just sits a placeholder to be selected
    // I am now wondering can we even get away with not having it in the tank list at all?
    //

      // now add this to the database
      String tankId = await saveNewTank(facilityFk,
          absolutePosition); // problem; how does the document id in the tank get updated

      Tank? theTankJustCreated =
      returnPhysicalTankWithThisAbsolutePosition(absolutePosition);

      theTankJustCreated?.updateTankDocumentId(tankId); // when we add an empty tank, after it’s created we get its id and immediately assign it its notes class.
      // this means in all instances, the notes have a tank id associated with them.
      // at this point, there are no notes, so they don’t individually need this tank_fk.
      // when we click the Notes button and then add a note, we will use the the savenewnote command. "Old" notes don’t exist yet.
  }

  // problem creating tank from the above is that it is saving the rack and we a dedicated function for this
  // we could

  void clearTanks() {
    tankList
        .clear(); // does not matter because we have the parked rack already saved, so it just gets read back in
  }

  void deleteTank(int index) {
    tankList.removeAt(index);
  }

  TanksViewModel(this._manageSession);

  Future<models.DocumentList> returnAssociatedTankList(
      String facilityId, String rackId) async {
    List<String>? tankQuery = [
      Query.equal("facility_fk", facilityId),
      Query.equal("rack_fk", [
        rackId,
        cParkedRackFkAddress
      ]), // potential solution make this an or search and just pass in this or 0, so get both
      Query.limit(
          5000), // BUG fixed, internal default appwrite limit is 25 items returned
    ];
    return await _manageSession.queryDocument(cTankCollection, tankQuery);
  }

  Map<String, dynamic> prepareTankMap(
      String facilityFk, int absolutePosition) {
    Tank? theTank = returnPhysicalTankWithThisAbsolutePosition(absolutePosition);

    Map<String, dynamic> theTankMap = {
      'facility_fk': facilityFk,
      'rack_fk': (absolutePosition == cParkedRackAbsPosition)
          ? "0"
          : rackDocumentid, // it’s going to save the wrong rack; we special case code this, if abs pos is 2, we put zero here
      'absolute_position': absolutePosition,
      'tank_line': theTank?.tankLine,
      'date_of_birth': theTank?.getBirthDate(),
      'screen_positive': theTank?.getScreenPositive(),
      'number_of_fish': theTank?.getNumberOfFish(),
      'fat_tank_position': theTank?.fatTankPosition,
      'generation': theTank?.generation,
    };
    return theTankMap;
  }

  // this will be called after add tank when the user clicks the create button
  // this will work for parked because we just pass -2 as abs position
  Future<String> saveNewTank(String facilityFk, int absolutePosition) async {
    Map<String, dynamic> theTankMap =
        prepareTankMap(facilityFk, absolutePosition);
    models.Document theTankDocument =
        await _manageSession.createDocument(theTankMap, cTankCollection);
    return theTankDocument.$id;
  }

  // this will be called every time during the onchanged event
  Future<void> saveExistingTank(String facilityFk, int absolutePosition) async {
    Tank? theTank = returnPhysicalTankWithThisAbsolutePosition(absolutePosition);
    Map<String, dynamic> theTankMap =
        prepareTankMap(facilityFk, absolutePosition);
    _manageSession.updateDocument(theTankMap, cTankCollection,
        (theTank?.documentId)!); // tank’s document ID must be correct!
  }

  void euthanizeTank(int absolutePosition) async {
    Tank? theTank = returnPhysicalTankWithThisAbsolutePosition(absolutePosition);

    int tankIndex = tankIdWithThisAbsolutePositionOnlyPhysical(absolutePosition);
    deleteTank(tankIndex);

    await _manageSession.deleteDocument(cTankCollection, (theTank?.documentId)!); // await to ensure notifylisteners occurs after deletetank

    selectThisTankCellConvertsVirtual(kEmptyTankIndex); // the currently selected tank has been deleted
    // what happens when deleting a parked tank. there simply is no longer a parked tank??
   // notifyListeners();  called above
  }

  Future<void> loadTanksForThisRack(FacilityViewModel facilityModel, String theRackId) async {

    models.DocumentList theTankList = await returnAssociatedTankList(
        facilityModel.returnFacilityId(), theRackId);

    // all tanks must save with a rack_fk; this is for other methods here
    rackDocumentid = theRackId;

    clearTanks(); // we do want the parked rack deleted because it will get re-added, but how? its rack id is “wrong’

    for (int theIndex = 0; theIndex < theTankList.total; theIndex++) {
      models.Document theTank = theTankList.documents[theIndex];

      /*
      how about we don't save the virtual tank
      when we read a tank we read the fat tank position and if it's non-null,
      we add a virtual tank, right here in this loop
      // this way when park a tank, we just remove that tank from the list and don't worry about the database
      when we drag a tank from the parked position, we create a new virtual tank in the spot next to wherre the tank is going
      what happens if we drag a fat tank over two small tanks, we reject this move
      // small tank can drag over another small tank
      a fat tank can drag over another fat tank because all we have to is alter the fat tank position of the incoming fat tank
      and the virtual tank of the next position over; it's a straight swap; the virtual tank never “moves”
       */
      addTankFromDatabase(
          theTank.$id, // this is the document ID that uniquely indentifies this record
          facilityModel.returnFacilityId(),
          theTank.data['rack_fk'],
          theTank.data['absolute_position'],
          theTank.data['tank_line'],
          theTank.data['date_of_birth'],
          theTank.data['screen_positive'],
          theTank.data['number_of_fish'],
          theTank.data['fat_tank_position'],
          theTank.data['generation']);
    }
  }

  Future<void> selectThisRackByAbsolutePosition(bool? readInTanks,
      FacilityViewModel facilityModel, int selectThisRack) async {
    selectedRack = selectThisRack;
    myPrint("the selected rack cell is $selectedRack must be followed loading tanks");
    // the code here will query the rack via the absolute position and facility_fk from the facility mode
    // need to pass facility model and boolean for reading this stuff
    if (readInTanks!) {
      String? theRackId = await facilityModel.returnSpecificRack(selectedRack);
      if (theRackId != null) {

        await loadTanksForThisRack(facilityModel,theRackId);  // BUG there is no await here, so notifylisteners may execute before this returns
      }
    }
    notifyListeners();
  }

  bool isThereAParkedTank() {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == cParkedRackAbsPosition) {
        return true;
      }
    }
    return false;
  }

  Tank? returnParkedTankedInfo() {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == cParkedRackAbsPosition) {
        return tankList[theIndex];
      }
    }
    return null;
  }

 int returnParkedTankedIndex() {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == cParkedRackAbsPosition) {
        return theIndex;
      }
    }
    return -1;
  }

  // one thing to be concerned about occurs when we park a fat tank
  // what do we do with its absolutePosition because the tank is really parked
  // we could delete the tank pair and then recreate when we drag it to its new home
  // if we assign it the parked tank position, the method above could conceivably return
  // the virtual part of a tank
  // if we look at fattankposition and it has a value, it's part of fat tank pair
  // but which part the real part of the virtual part?

  // what if we don't save the virtual tank;
  // it won't be in the list of tanks and it will the rack
  // when we park a tank,

  int convertVirtualTankPositionToPhysical(int selectThisTankCell) {
    int tankId = tankIdWithThisAbsolutePositionIncludesVirtual(selectThisTankCell);
    if (tankId == kEmptyTankIndex) {
      return kEmptyTankIndex;
    } else {
      return tankList[tankId].absolutePosition;
    }
  }

  // selectedTankCell should always contain a physical tank
  void selectThisTankCellConvertsVirtual(int selectThisTankCell) {
    if (selectThisTankCell != cParkedAbsolutePosition) {
      selectedTankCell = convertVirtualTankPositionToPhysical(selectThisTankCell);
    } else {
      // parked always selects a physical tank
      selectedTankCell = selectThisTankCell;
    }
    notifyListeners();
  }

  // for when we are called by the search/barcode
  // the barcode of a fat tank is its parent tank. Because of that, we don’t have to worry
  // about selecting a virtual unselectable tank pair
  void selectThisTankCellWithoutListener(int selectThisTankCell) {
    selectedTankCell = selectThisTankCell;
  }

  // this will need to take virtual into account
  // first check if (selectedTankCell == absolutePosition) and if true
  // return true
  // otherwise, iterate through tanks and if fattankposition matches absolutePosition
  // also return true
  bool returnIsThisTankSelectedWithVirtual(int absolutePosition) {
    if (absolutePosition != cParkedAbsolutePosition) {
      absolutePosition = convertVirtualTankPositionToPhysical(absolutePosition);
      return (selectedTankCell == absolutePosition);
    } else {
      // parked always selects a physical tank
      return (selectedTankCell == absolutePosition);
    }
  }

  bool isThisTankParked(int absolutePosition) {
    return(absolutePosition == cParkedAbsolutePosition);
  }

  bool isThisTankVirtual(int absolutePosition) {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].fatTankPosition == absolutePosition) {
        return true;
      }
    }
    return false;
  }

  bool isThisRackCellSelected(int whichCell) {
    return (whichCell == selectedRack);
  }

  int whichRackCellIsSelected() {
    return selectedRack;
  }

  bool isThisTankPhysicalAndFat(int absolutePosition) {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == absolutePosition) {
        return (tankList[theIndex].fatTankPosition != null);
      }
    }
    return false;
  }

  // can accept -2, the parked tank position
  // is this giving me a reference or a copy?
  // when we tap a tank cell, we call SelectThisTankCell above and that updates the current tank cell variable
  // it calls notifylisteners which should theoretically trigger the controller to call this function which updates
  // selectedTankCell always contains a physical tank, so we only search physical tanks
  Tank? returnCurrentPhysicalTank() {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == selectedTankCell) {
        return tankList[theIndex];
      }
    }
    return null;
  }

  // for now, this function will ignore virtual tanks
  Tank? returnPhysicalTankWithThisAbsolutePosition(int absolutePosition) {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == absolutePosition) {
        return tankList[theIndex];
      }
    }
    return null;
  }

  // can accept -2, which is the parked tank
  // when we call this, we want a physical tank in return
  int tankIdWithThisAbsolutePositionOnlyPhysical(int absolutePosition) {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == absolutePosition) {
        return theIndex;
      }
    }
    return kEmptyTankIndex; // this tell us that this tank position is empty or virtual.
  }

  // we are called here to know whether a given tank cell contains a tank in any way shape or form
  // but it always returns a physical tank
  int tankIdWithThisAbsolutePositionIncludesVirtual(int absolutePosition) {
    int tankID = tankIdWithThisAbsolutePositionOnlyPhysical(absolutePosition);
    if (tankID == kEmptyTankIndex) {
      for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
        if (tankList[theIndex].fatTankPosition == absolutePosition) {
          tankID = tankIdWithThisAbsolutePositionOnlyPhysical(tankList[theIndex].absolutePosition);
        }
      }
    }
    return tankID; // if there is no tank, we return kEmptyTankIndex
  }
}
