import 'package:flutter/material.dart';
import 'package:aquarium_manager/model/session_key.dart';
import 'aquarium_manager_tanks_model.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/appwrite.dart';
import 'package:aquarium_manager/views/consts.dart';

class MyAquariumManagerSearchModel with ChangeNotifier {
  final ManageSession
      _manageSession; // we need this because manage tanks, which in turn uses Notes, which needs the session variable to save to disk
  String facilityFk = "";

  List<Tank> tankListFull = <Tank>[];
  List<Tank> tankListSearched = <Tank>[];

  MyAquariumManagerSearchModel(this._manageSession);

  void setFacilityId(String facilityFk) {
    this.facilityFk = facilityFk;
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
    tankListFull.add(aTank);
  }

  void clearTanksFullList() {
    tankListFull
        .clear();
  }

  void clearTanksSearchedList() {
    tankListSearched
        .clear();
  }

  Future<models.DocumentList> returnAllTheTanks() async {

    List<String>? tankQuery = [
      Query.equal("facility_fk", facilityFk),
    ];
    return await _manageSession.queryDocument(cTankCollection, tankQuery);
  }

  Future<void> prepareFullTankList() async {
    models.DocumentList theTankList = await returnAllTheTanks();

    clearTanksFullList();

    for (int theIndex = 0; theIndex < theTankList.total; theIndex++) {
      models.Document theTank = theTankList.documents[theIndex];

      addTankFromDatabase(
          theTank
              .$id, // this is the document ID that uniquely identifies this record
          facilityFk,
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

  void prepareSearchTankList(String tankLineTextToSearchFor) {
    tankListSearched.clear();
    if (tankLineTextToSearchFor == "") {
      for (int theIndex = 0; theIndex < tankListFull.length; theIndex++) {
        tankListSearched.add(tankListFull[theIndex]);
      }
    } else {
      for (int theIndex = 0; theIndex < tankListFull.length; theIndex++) {
        if (tankListFull[theIndex].tankLine != null) {
          if (tankListFull[theIndex].tankLine!.toLowerCase().contains(
              tankLineTextToSearchFor.toLowerCase())) {
            tankListSearched.add(tankListFull[theIndex]);
          }
        }
      }
    }
    // sort based on birthdate
    tankListSearched.sort((a, b) {
      if (a.birthDate == null && b.birthDate == null) {
        return 0; // Both dates are null, they are equal
      }
      if (a.birthDate == null) {
        return 1; // a is after b because a is null and b is not
      }
      if (b.birthDate == null) {
        return -1; // a is before b because a is not null and b is
      }
      return a.birthDate!.compareTo(b.birthDate!); // Now we are sure that neither date is null
    });
    notifyListeners();
  }

  Future<void> buildInitialSearchList(String facilityFk) async {
    setFacilityId(facilityFk);
    await prepareFullTankList(); // we do get the full tank list from the database and the database should always be up to date.
    prepareSearchTankList("");
  }
}
