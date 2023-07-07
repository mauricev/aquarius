import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:aquarium_manager/model/sessionKey.dart';
import 'package:appwrite/models.dart' as models;
import 'aquarium_manager_facilities_model.dart';
import 'aquarium_manager_notes_model.dart';
import 'package:aquarium_manager/views/consts.dart';
import 'package:aquarium_manager/views/utility.dart';


class Tank {
  String? documentId;
  final String facilityFk;
  String rackFk;
  int absolutePosition;
  String? tankLine;
  int? birthDate;
  bool? screenPositive;
  int? numberOfFish;
  bool? smallTank;
  int? generation;
  final ManageSession manageSession;
  late final Notes notes;

  Tank({
    this.documentId,
    required this.facilityFk,
    required this.rackFk,
    required this.absolutePosition,
    this.tankLine,
    int? birthDate,
    this.screenPositive,
    this.numberOfFish,
    this.smallTank,
    this.generation,
    required this.manageSession,
  }) : birthDate = birthDate ?? returnTimeNow() {
    notes = createNotes();
    notes.loadNotes();
  }

  Notes createNotes() {
    return Notes(parentTank: this, manageSession: manageSession);
  }

  void parkIt() {
    absolutePosition = cParkedRackAbsPosition;
    rackFk = cParkedRackFkAddress;
  }

  void updateTankDocumentId (String tankFk) {
    documentId = tankFk;
  }

  void setScreenPositive (bool newScreenPositiveValue) {
    screenPositive = newScreenPositiveValue;
  }

  void setSmallTank (bool newSmallTankValue) {
    smallTank = newSmallTankValue;
  }

  bool? getSmallTank() {
    return smallTank;
  }

  bool? getScreenPositive() {
    return screenPositive;
  }

  int? getBirthDate() {
    myPrint("what is the birthdate, ${birthDate}");
    return birthDate;
  }

  void setBirthDate(int newBirthDateValue) {
    birthDate = newBirthDateValue;
  }

  int? getNumberOfFish() {
    return numberOfFish;
  }

}

// does it pay to make a superclass of this and the facilities model
// no, it does not
class MyAquariumManagerTanksModel with ChangeNotifier {
  final ManageSession _manageSession;

  List<Tank> tankList = <Tank>[];

  int selectedRack = -2; // this is a rack cell, not a tank cell
  int selectedTankCell = -1;
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
      bool? smallTank,
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
        smallTank: smallTank,
        generation: generation,
        manageSession: _manageSession);
    tankList.add(aTank);
  }

  void addNewEmptyTank(String facilityFk, int absolutePosition) async {
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
        smallTank: true,
        generation: 1,
        manageSession: _manageSession);
    tankList.add(aTank);
    // now add this to the database
    String tankId = await saveNewTank(facilityFk,
        absolutePosition); // problem; how does the document id in the tank get updated


    Tank? theTankJustCreated =
        tankInfoWithThisAbsolutePosition(absolutePosition);

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

  MyAquariumManagerTanksModel(this._manageSession);

  Future<models.DocumentList> returnAssociatedTankList(
      String facilityId, String rackId) async {
    List<String>? tankQuery = [
      Query.equal("facility_fk", facilityId),
      Query.equal("rack_fk", [
        rackId,
        cParkedRackFkAddress
      ]), // potential solution make this an or search and just pass in this or 0, so get both
    ];
    return await _manageSession.queryDocument(cTankCollection, tankQuery);
  }

  Map<String, dynamic> prepareTankMap(
      String facilityFk, int absolutePosition) {
    Tank? theTank = tankInfoWithThisAbsolutePosition(absolutePosition);

    Map<String, dynamic> theTankMap = {
      'facility_fk': facilityFk,
      'rack_fk': (absolutePosition == cParkedRackAbsPosition)
          ? "0"
          : rackDocumentid, // it’s going to save the wrong rack; we special case code this, if abs pos is 2, we put zero here
      'absolute_position': absolutePosition,
      'tank_line': theTank?.tankLine,
      'date_of_birth': theTank?.birthDate,
      'screen_positive': theTank?.screenPositive,
      'number_of_fish': theTank?.numberOfFish,
      'small_tank': theTank?.smallTank,
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
  void saveExistingTank(String facilityFk, int absolutePosition) async {
    Tank? theTank = tankInfoWithThisAbsolutePosition(absolutePosition);
    Map<String, dynamic> theTankMap =
        prepareTankMap(facilityFk, absolutePosition);
    _manageSession.updateDocument(theTankMap, cTankCollection,
        (theTank?.documentId)!); // tank’s document ID must be correct!
  }

  void euthanizeTank(int absolutePosition) async {
    //models.Document theTankDocument = await PrepareTankDocument(absolutePosition);
    Tank? theTank = tankInfoWithThisAbsolutePosition(absolutePosition);
    _manageSession.deleteDocument(cTankCollection, (theTank?.documentId)!);
    int tankIndex = tankIdWithThisAbsolutePosition(absolutePosition);
    deleteTank(tankIndex);
  }

  // void copyParkedTankToNewTankAndDeleteParkedTank(int absolutePosition) {
  //   Tank? theParkedTank =
  //       tankInfoWithThisAbsolutePosition(cParkedRackAbsPosition);
  //   Tank? theDestinationTank =
  //       tankInfoWithThisAbsolutePosition(absolutePosition);
  //   theDestinationTank?.tankLine = theParkedTank?.tankLine;
  //   theDestinationTank?.rackFk = (theParkedTank?.rackFk)!;
  //   theDestinationTank?.birthDate = theParkedTank?.birthDate ?? 0; // in case parked tank is null, apparently we need to do this
  //   theDestinationTank?.screenPositive = theParkedTank?.screenPositive;
  //   theDestinationTank?.numberOfFish = theParkedTank?.numberOfFish;
  //   theDestinationTank?.smallTank = theParkedTank?.smallTank;
  //   theDestinationTank?.generation = theParkedTank?.generation;
  //   saveExistingTank((theDestinationTank?.facilityFk)!,
  //       (theDestinationTank?.absolutePosition)!);
  //   euthanizeTank(cParkedRackAbsPosition);
  // }

  Future<void> loadTanksForThisRack(MyAquariumManagerFacilityModel facilityModel, String theRackId) async {

    models.DocumentList theTankList = await returnAssociatedTankList(
        facilityModel.documentId, theRackId);

    // all tanks must save with a rack_fk; this is for other methods here
    rackDocumentid = theRackId;

    clearTanks(); // we do want the parked rack deleted because it will get re-added, but how? its rack id is “wrong’

    for (int theIndex = 0; theIndex < theTankList.total; theIndex++) {
      models.Document theTank = theTankList.documents[theIndex];
      addTankFromDatabase(
          theTank.$id, // this is the document ID that uniquely indentifies this record
          facilityModel.documentId,
          theTank.data['rack_fk'],
          theTank.data['absolute_position'],
          theTank.data['tank_line'],
          theTank.data['date_of_birth'],
          theTank.data['screen_positive'],
          theTank.data['number_of_fish'],
          theTank.data['small_tank'],
          theTank.data['generation']);
    }
  }

  Future<void> selectThisRackByAbsolutePosition(bool? readInTanks,
      MyAquariumManagerFacilityModel facilityModel, int selectThisRack) async {
    selectedRack = selectThisRack;
    myPrint("the selected rack cell is ${selectedRack} must be followed loading tanks");
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

  void selectThisTankCell(int selectThisTankCell) {
    selectedTankCell = selectThisTankCell;
    notifyListeners();
  }

  // for when we are called by the search/barcode
  void selectThisTankCellWithoutListener(int selectThisTankCell) {
    selectedTankCell = selectThisTankCell;
  }

  bool returnIsThisTankSelected(int absolutePosition) {
    return (selectedTankCell == absolutePosition);
  }

  bool isThisRackCellSelected(int whichCell) {
    return (whichCell == selectedRack);
  }

  int whichRackCellIsSelected() {
    return selectedRack;
  }

  // we use the editable version of the list here
  // can accept -2, the parked tank position
  Tank? tankInfoWithThisAbsolutePosition(int absolutePosition) {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == absolutePosition) {
        return tankList[theIndex];
      }
    }
    return null;
  }

  // can accept -2, the parked tank position
  // is this giving me a reference or a copy?
  // when we tap a tank cell, we call SelectThisTankCell above and that updates the current tank cell variable
  // it calls notifylisteners which should theoretically trigger the controller to call this function which updates
  Tank? returnCurrentTank() {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == selectedTankCell) {
        return tankList[theIndex];
      }
    }
    return null;
  }

  Tank? returnTankWithThisAbsolutePosition(int absolutePosition) {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == absolutePosition) {
        return tankList[theIndex];
      }
    }
    return null;
  }

  // can accept -2, which is the parked tank
  int tankIdWithThisAbsolutePosition(int absolutePosition) {
    for (int theIndex = 0; theIndex < tankList.length; theIndex++) {
      if (tankList[theIndex].absolutePosition == absolutePosition) {
        return theIndex;
      }
    }
    return -1; // this tell us that this tank position is empty.
  }
}
