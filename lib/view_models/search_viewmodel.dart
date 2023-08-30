import 'package:flutter/material.dart';
import 'package:aquarium_manager/view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/appwrite.dart';
import 'package:aquarium_manager/views/consts.dart';
import 'package:aquarium_manager/models/tank_model.dart';

class SearchViewModel with ChangeNotifier {
  final ManageSession
      _manageSession; // we need this because manage tanks, which in turn uses Notes, which needs the session variable to save to disk
  String facilityFk = "";

  List<Tank> tankListFull = <Tank>[];
  List<Tank> tankListSearched = <Tank>[];

  SearchViewModel(this._manageSession);

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
    tankListFull.clear();
  }

  void clearTanksSearchedList() {
    tankListSearched.clear();
  }

  Future<models.DocumentList> returnAllTheTanks() async {
    List<String>? tankQuery = [
      Query.equal("facility_fk", facilityFk),
      Query.limit(
          5000), // BUG fixed, internal default appwrite limit is 25 items returned
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

  int? computeBreedingDate(int? birthDate) {
    // we will take the birthdate and add to it 6 months
    // if we want to change 6 months to some other value, we will probably
    // need a new database collection of one record and a new model to manage this value
    // along with an interface
    return (birthDate! + kCrossBreedTime);
  }

  void prepareSearchTankList(String tankLineTextToSearchFor, bool searchType) {
    tankListSearched.clear();
    if (tankLineTextToSearchFor == "") {
      for (int theIndex = 0; theIndex < tankListFull.length; theIndex++) {
        tankListSearched.add(tankListFull[theIndex]);
      }
    } else {
      for (int theIndex = 0; theIndex < tankListFull.length; theIndex++) {
        if (tankListFull[theIndex].tankLine != null) {
          if (tankListFull[theIndex]
              .tankLine!
              .toLowerCase()
              .contains(tankLineTextToSearchFor.toLowerCase())) {
            tankListSearched.add(tankListFull[theIndex]);
          }
        }
      }
    }

    void sortByProperty<T>(
        List<T> list, Comparable? Function(T) getProperty) {
      list.sort((a, b) {
        final aProp = getProperty(a);
        final bProp = getProperty(b);

        if (aProp == null && bProp == null) {
          return 0;
        }
        if (aProp == null) {
          return 1;
        }
        if (bProp == null) {
          return -1;
        }
        return aProp.compareTo(bProp);
      });
    }

    if (searchType == kPlainSearch) {
      sortByProperty(tankListSearched, (tank) => tank.tankLine);
    } else {
      sortByProperty(tankListSearched, (tank) => tank.getBirthDate());
    }
    notifyListeners();
  }

  // we exclude exact matches so the dropdown doesn’t automatically come down on the mere loading of the tank cell
  // bug, we are searching only the tanks in this particular rack, not in all racks
  Set<String> returnListOfTankLines(String excludeThisString) {

    Set<String> tankLineList = {};

    for (int theIndex = 0; theIndex < tankListFull.length; theIndex++) {
      String? tankLine = tankListFull[theIndex].tankLine;
      if (tankLine != null && tankLine != excludeThisString) {
        tankLineList.add(tankLine);
      }
    }
    return tankLineList;
  }

  Future<void> prepareFullTankListForFacility(String facilityFk) async {
    setFacilityId(facilityFk);
    await prepareFullTankList(); // we do get the full tank list from the database and the database should always be up to date.
  }

  Future<void> buildInitialSearchList(String facilityFk) async {
    await prepareFullTankListForFacility(facilityFk); // we do get the full tank list from the database and the database should always be up to date.
    prepareSearchTankList("",kPlainSearch);
  }

}
