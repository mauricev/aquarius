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
  String facilityId =
      "not yet set, tank"; // we can set it to not yet set; that will tell us if we are not setting it

  void setFacilityId(String incomingFacilityId) {
    facilityId = incomingFacilityId;
  }

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
  void addNewEmptyTank(int absolutePosition, int? fatTankPosition) async {
    Tank aTank = Tank(
        documentId:
            null, // the tank entry is new, so it doesn’t have a document ID yet
        facilityFk: facilityId,
        rackFk: (absolutePosition == cParkedRackAbsPosition)
            ? "0"
            : rackDocumentid, // saved from when we switch racks; we always get it from the database
        absolutePosition: absolutePosition,
        tankLine: "",
        birthDate:
            returnTimeNow(), // BUGfixed removed 2 year offset per Jaslin’s request
        screenPositive: true,
        numberOfFish: 1,
        fatTankPosition:
            fatTankPosition, // value will be decided based whether user has chosen a fat tank; we will need abs position of next tank
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
    myPrint("saveNewTank, facility is $facilityId");
    // now add this to the database
    String tankId = await saveNewTank(absolutePosition);

    Tank? theTankJustCreated =
        returnPhysicalTankWithThisAbsolutePosition(absolutePosition);

    theTankJustCreated?.updateTankDocumentId(
        tankId); // when we add an empty tank, after it’s created we get its id and immediately assign it its notes class.

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

  Map<String, dynamic> prepareTankMap(int absolutePosition) {
    Tank? theTank =
        returnPhysicalTankWithThisAbsolutePosition(absolutePosition);

    myPrint("prepareTankMap, facility $facilityId, tank ${theTank?.tankLine}");

    Map<String, dynamic> theTankMap = {
      'facility_fk': facilityId,
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
  Future<String> saveNewTank(int absolutePosition) async {
    Map<String, dynamic> theTankMap = prepareTankMap(absolutePosition);
    // can we put an alert if the facility is an empty string?
    models.Document theTankDocument =
        await _manageSession.createDocument(theTankMap, cTankCollection);
    return theTankDocument.$id;
  }

  // this will be called every time during the onchanged event
  Future<void> saveExistingTank(int absolutePosition) async {
    try {
      Tank? theTank =
          returnPhysicalTankWithThisAbsolutePosition(absolutePosition);
      Map<String, dynamic> theTankMap = prepareTankMap(absolutePosition);

      myPrint(
          "saveExistingTank, facility $facilityId, tank ${theTank?.tankLine}");

      await _manageSession.updateDocument(
          theTankMap, cTankCollection, (theTank?.documentId)!);
    } catch (e) {
      print("Error in saveExistingTank: $e");
      rethrow;
    }
  }

  void euthanizeTank(int absolutePosition) async {
    Tank? theTank =
        returnPhysicalTankWithThisAbsolutePosition(absolutePosition);

    int tankIndex =
        tankIdWithThisAbsolutePositionOnlyPhysical(absolutePosition);
    deleteTank(tankIndex);

    await _manageSession.deleteDocument(
        cTankCollection,
        (theTank
            ?.documentId)!); // await to ensure notifylisteners occurs after deletetank

    selectThisTankCellConvertsVirtual(kEmptyTankIndex,
        cNotify); // the currently selected tank has been deleted
    // what happens when deleting a parked tank. there simply is no longer a parked tank??
    // notifyListeners();  called above
  }

  Future<void> loadTanksForThisRack(
      FacilityViewModel facilityModel, String theRackId) async {
    models.DocumentList theTankList =
        await returnAssociatedTankList(facilityId, theRackId);

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
          theTank
              .$id, // this is the document ID that uniquely identifies this record
          facilityId,
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

  Future<void> selectThisRackByAbsolutePosition(
      bool? readInTanks,
      FacilityViewModel facilityModel,
      int selectThisRack,
      bool withNotifyListeners) async {
    selectedRack = selectThisRack;
    myPrint(
        "the selected rack cell is $selectedRack must be followed loading tanks");
    // the code here will query the rack via the absolute position and facility_fk from the facility mode
    // need to pass facility model and boolean for reading this stuff
    if (readInTanks!) {
      String? theRackId = await facilityModel.returnSpecificRack(selectedRack);
      if (theRackId != null) {
        await loadTanksForThisRack(facilityModel,
            theRackId); // BUG there is no await here, so notifylisteners may execute before this returns
      }
    }
    if (withNotifyListeners) {
      notifyListeners();
    }
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
    int tankId =
        tankIdWithThisAbsolutePositionIncludesVirtual(selectThisTankCell);
    if (tankId == kEmptyTankIndex) {
      return kEmptyTankIndex;
    } else {
      return tankList[tankId].absolutePosition;
    }
  }

  // selectedTankCell should always contain a physical tank
  void selectThisTankCellConvertsVirtual(
      int selectThisTankCell, bool withNotify) {
    if (selectThisTankCell != cParkedAbsolutePosition) {
      selectedTankCell =
          convertVirtualTankPositionToPhysical(selectThisTankCell);
    } else {
      // parked always selects a physical tank
      selectedTankCell = selectThisTankCell;
    }
    if (withNotify == cNotify) {
      notifyListeners();
    }
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
    return (absolutePosition == cParkedAbsolutePosition);
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
          tankID = tankIdWithThisAbsolutePositionOnlyPhysical(
              tankList[theIndex].absolutePosition);
        }
      }
    }
    return tankID; // if there is no tank, we return kEmptyTankIndex
  }

  void parkedADraggedTank(Tank parkedTank, int thisPosition) {
    // if this destination widget is a virtual tank, make the swap with the prior position numerically
    if (isThisTankVirtual(thisPosition)) {
      thisPosition = thisPosition - 1;
    }

    // this will be physical
    int tankID = tankIdWithThisAbsolutePositionOnlyPhysical(
        thisPosition); // this represents the new, not parked tank
    if (tankID == kEmptyTankIndex) {
      // there is no tank at this position
      // the user dragged over an empty tank
      // our parked tank needs two new pieces of info
      // a new abs position and the rack_fk
      // do we have a copy of the parked tank or the actual parked tank?

      parkedTank.assignTankNewLocation(rackDocumentid, thisPosition);

      // the tank has not been saved with this new info
      // this will be physical
      saveExistingTank(thisPosition);
    } else {
      // here we are swapping tank positions
      // this will be physical

      // business logic 11, everything below should be distilled down to one method in tankModel

      Tank? destinationTank =
          returnPhysicalTankWithThisAbsolutePosition(thisPosition);

      // BUG if this tank is fat, then its fat position needs a special value, perhaps 0, so it doesn’t select anything
      destinationTank?.parkIt();

      // BUG if this tank is fat, then its fat position needs to be updated
      parkedTank.assignTankNewLocation(rackDocumentid, thisPosition);
      // this will be physical
      saveExistingTank(thisPosition);
      // this will be physical
      saveExistingTank(cParkedAbsolutePosition);
    }
    // below we are passing a physical tank position
    // so selectThisTankCell should never come to the virtual tank code

    selectThisTankCellConvertsVirtual(
        thisPosition, cNotify); // do we need notify here?
  }
}
