import 'package:flutter/material.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/appwrite.dart';
import '../views/consts.dart';
import '../models/tank_model.dart';
import '../view_models/tankitems_viewmodel.dart';
import 'tanks_viewmodel_common.dart';

class SearchViewModel with ChangeNotifier {
  final ManageSession
      _manageSession; // we need this because manage tanks, which in turn uses Notes, which needs the session variable to save to disk
  String? facilityFk = "not yet set, search";

  TanksLineViewModel? tanksLineViewModel;

  List<Tank> tankListFull = <Tank>[];
  List<Tank> tankListSearched = <Tank>[];

  Map<int,int> dobNumberOfFish = <int,int>{};
  int totalNumberOfFish = 0;
  double averageAgeOfFish = 0;

  SearchViewModel(this._manageSession);

  void setFacilityId(String? facilityFk) {
    this.facilityFk = facilityFk;
  }

  /*void addTankFromDatabase(
      String documentId,
      String? facilityFk,
      String rackFk,
      int absolutePosition,
      String tankLine,
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
        tankLineDocId: tankLine,
        birthDate: birthDate,
        screenPositive: screenPositive,
        numberOfFish: numberOfFish,
        fatTankPosition: fatTankPosition,
        generation: generation,
        manageSession: _manageSession);
    tankListFull.add(aTank);
  }*/

  void clearTanksFullList() {
    tankListFull.clear();
  }

  void clearTanksSearchedList() {
    tankListSearched.clear();
  }

  void clearDobNumberOfFishMap() {
    dobNumberOfFish.clear();
  }

  // parked tanks are not technically part of any facility, so they don’t show up in this search
  Future<models.DocumentList> returnAllTheTanks() async {
    List<String>? tankQuery = [
      Query.equal("facility_fk", facilityFk),
      Query.limit(
          5000), // BUGfixed, internal default appwrite limit is 25 items returned
    ];
    return await _manageSession.queryDocument(cTankCollection, tankQuery);
  }

  Future<void> prepareFullTankList() async {
    models.DocumentList theTankList = await returnAllTheTanks();

    clearTanksFullList();
    clearTanksSearchedList();
    clearDobNumberOfFishMap();

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
          theTank.data['generation'],
          theTank.data['genotype'],
        theTank.data['parent_female'],
        theTank.data['parent_male'],
          _manageSession,
          tankListFull
      );
    }
  }

  void sortByProperty<T>(List<T> list, Comparable? Function(T) getProperty) {
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

  // Prepare the dropdown
  List<ValueItem> returnTankLinesAsValueItems() {
    // we use a set to ensure duplicates don’t get added to the list.
    Set<ValueItem> uniqueTankLines = {};

    for (Tank tank in tankListFull) {
      if (tank.tankLineDocId.isNotEmpty) {
        ValueItem? tankLine = tanksLineViewModel?.returnTankItemFromDocId(tank.tankLineDocId);
        if (tankLine != null) {
          uniqueTankLines.add(tankLine);
        }
      }
    }
    List<ValueItem> selectableTankLineValueList = uniqueTankLines.toList();
    // BUGfixed wasn’t sorting according to lower case
    selectableTankLineValueList.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    return selectableTankLineValueList;
  }

  int? computeBreedingDate(int? birthDate) {
    // we will take the birthdate and add to it 6 months
    // if we want to change 6 months to some other value, we will probably
    // need a new database collection of one record and a new model to manage this value
    // along with an interface
    return (birthDate! + kCrossBreedTime);
  }

  int get getTotalNumberOfFish => totalNumberOfFish;

  double get getAverageAgeOfFish => averageAgeOfFish;

  void prepareNumberFishPerBirthDate(int? searchType) {
    if (searchType == cTankLineSearch) {

      // re-initialize variables
      dobNumberOfFish.clear();
      totalNumberOfFish = 0;
      int birthDateTally = 0;

      for (int theIndex = 0; theIndex < tankListSearched.length; theIndex++) {

        int? birthDate = tankListSearched[theIndex].birthDate;

        if(birthDate != null) {

          int numberOfFishAtThisBirthDate = tankListSearched[theIndex].numberOfFish!;
          birthDateTally += (birthDate * numberOfFishAtThisBirthDate);  // we need to tally the birthdate for *each* fish at this birthdate
          totalNumberOfFish += numberOfFishAtThisBirthDate;

          if(dobNumberOfFish.containsKey(birthDate)) {
            // we have this dob already, add the number of fish at theIndex;
            int numberOfFishAtStoredBirthDate = dobNumberOfFish[birthDate]!;
            dobNumberOfFish[birthDate] = numberOfFishAtStoredBirthDate + numberOfFishAtThisBirthDate; // dobNumberOfFish[birthDate] is the number of fish for the referenced birthdate
          } else {
            // if dob does not exist in the map, add it with the number of fish
            // simply referencing a new key adds it to the map
            dobNumberOfFish[birthDate] = numberOfFishAtThisBirthDate;
          }
        }
      }

      averageAgeOfFish = birthDateTally / totalNumberOfFish;
    }
  }

  // tankLineTextToSearchFor searches value (document id), not label (actual text)
  void prepareSearchTankList(String tankLineDocumentIdToSearchFor, int? searchType, bool withNotify) {

    tankListSearched.clear();

    if (searchType == cCrossBreedSearch) {
      // in cross-breed search, we search ALL tanklines
      for (int theIndex = 0; theIndex < tankListFull.length; theIndex++) {
        tankListSearched.add(tankListFull[theIndex]);
      }
    } else {
      // just in case tankLineDocumentIdToSearchFor == cTankLineValueNotYetAssigned, we still do the search
      //if (tankLineDocumentIdToSearchFor != cTankLineValueNotYetAssigned) {
        for (int theIndex = 0; theIndex < tankListFull.length; theIndex++) {
            if (tankListFull[theIndex]
                .tankLineDocId == tankLineDocumentIdToSearchFor) {
              tankListSearched.add(tankListFull[theIndex]);
            }
        }
      //}
    }

    // both are sorted according to dob, but they contain different things. cTankLineSearch contains a specific tankline; the other contains them all
    sortByProperty(tankListSearched, (tank) => tank.getBirthDate());

    prepareNumberFishPerBirthDate(searchType);

    if (withNotify == cNotify) {
      notifyListeners();
    }
  }

  // we save tanksLineViewModelModel to prepare the dropdown
  Future<void> buildInitialSearchList(TanksLineViewModel tanksLineViewModelParam) async {

    // we need access later on to the tanksLineViewModel to convert the tanklineFk’s to actual tanklines
    tanksLineViewModel = tanksLineViewModelParam;

    await prepareFullTankList(); // get the full tank list from the database and the database should always be up to date.
    prepareSearchTankList(cTankLineValueNotYetAssigned, cTankLineSearch,cNoNotify);
  }
}