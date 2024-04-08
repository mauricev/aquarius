import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;
import '../views/consts.dart';
import '../models/tankline_model.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import '../models/tank_model.dart';

class TanksLineViewModel with ChangeNotifier {
  final ManageSession _manageSession;
  List<TankLine> tankLinesList = <TankLine>[];

  TanksLineViewModel(this._manageSession);

  void callNotifyListeners() {
    notifyListeners();
  }

  // we could preflight the list; in the command below, we could

  void addTankLineFromDatabase(
      String documentId, bool tankLineInUse,
      String tankLine) {
    TankLine aTankLine = TankLine(
        documentId: documentId,
        tankLineInUse: tankLineInUse,
        tankLine: tankLine);

    tankLinesList.add(aTankLine);
  }

  void sortTankLines() {
    tankLinesList.sort((a, b) => a.tankLine.toLowerCase().compareTo(b.tankLine.toLowerCase()));
  }

  Future<void> deleteTankLine(int index) async {
    await _manageSession.deleteDocument(cTankLinesCollection, tankLinesList[index].documentId!);
    // BUGFixed 2024-03-06
    // must update the list itself
    tankLinesList.removeAt(index);
  }

  Future<void> saveTankLine(String tankLineToSave, index) async {

    Map<String, dynamic> theTankLineMap = {
      'tank_line': tankLineToSave,
    };

    if (index == cNewTankline) {
      // after saving, we read in the document id and record it in the tankline object so we can know which document it is for future editing
      models.Document theTankLineDocument = await _manageSession.createDocument(theTankLineMap, cTankLinesCollection);

      addTankLineFromDatabase(theTankLineDocument.$id, cTankLineNotInUse, tankLineToSave); // this tankline is new and won't be in use
      sortTankLines();
    } else {

      //BUGfixed, was passing tankline and not document id
      await _manageSession.updateDocument(
          theTankLineMap, cTankLinesCollection, tankLinesList[index].documentId!);

      //BUGfixed, we weren’t updating the list itself
      tankLinesList[index].tankLine = tankLineToSave;
      // do not sort because if the edited tankline ends up in a different position, it will appear to disappear from the list and confuse the user
    }
  }

  Future<bool> isThisTankLineUsedByAnyTank(String tankLineDocmentId) async {
    // here we need to search across all tanks for this tanklinedocumentid
    List<String>? tankLineQuery = [
      Query.equal("tank_line", tankLineDocmentId),
      Query.limit(
          5000), // BUGfixed, internal default appwrite limit is 25 items returned
    ];
    models.DocumentList theDocumentList = await _manageSession.queryDocument(cTankCollection, tankLineQuery);
    return (theDocumentList.total > 0);
  }

  // if we are editing a tankline and rename it such that it matches another tankline, we have a conflict
  // this method tells us this
  // it is NOT telling us whether the tankline is being used by any tanks
  bool isThisTankLineInUse(String editedTankLine, index) {
    // strip trailing space character and then do the comparison
    editedTankLine = editedTankLine.trimRight();

    if (index != cNewTankline) {
      List<String> tankLinesTempList = <String>[];
      for (int theIndex = 0; theIndex < tankLinesList.length; theIndex++) {
        // don’t test against the selected index; it will always match
        if (index != theIndex) {
          tankLinesTempList.add(tankLinesList[theIndex].tankLine);
        }
      }
      return tankLinesTempList.contains(editedTankLine);
    } else {
      // we are testing against the tankline string inside the tankline class here
      return tankLinesList.any((tankLine) => tankLine.tankLine.toLowerCase() == editedTankLine.toLowerCase());
    }
  }

  // new tanks will have "" as tankLineFk
  ValueItem returnTankLineFromDocId(String tankLineFk) {
    String? matchingTankLine = "";
    for (TankLine tankLine in tankLinesList) {
      if (tankLine.documentId?.contains(tankLineFk) == true) {
        matchingTankLine = tankLine.tankLine;
        break;
      }
    }
    return ValueItem(label: matchingTankLine!, value: tankLineFk);
  }

  List<ValueItem> returnTankLinesFromTank(Tank theTank) {
    List<ValueItem> parentTankLines = <ValueItem>[];

    String? findTankLineDocumentId(String parentTankLine) {
      for (TankLine tankLine in tankLinesList) {
        if (tankLine.tankLine.contains(parentTankLine)) {
          return tankLine.documentId;
        }
      }
      return null;
    }
    if ((theTank.parentFemale != null ) && (findTankLineDocumentId(theTank.parentFemale!)) != null) {
      String? tankLineFk = findTankLineDocumentId(theTank.parentFemale!);

      parentTankLines.add(ValueItem(label: theTank.parentFemale!, value: tankLineFk));
    }
    if ((theTank.parentMale != null ) && (findTankLineDocumentId(theTank.parentMale!)) != null) {
      String? tankLineFk = findTankLineDocumentId(theTank.parentMale!);

      parentTankLines.add(ValueItem(label: theTank.parentMale!, value: tankLineFk));
    }
    return parentTankLines;
  }

  void clearTankLines() {
    tankLinesList.clear();
  }

  Future<models.DocumentList> returnTankLines() async {
    List<String>? tankLinesQuery = [
      Query.limit(5000),
    ];
    return await _manageSession.queryDocument(
        cTankLinesCollection, tankLinesQuery);
  }

  Future<void> buildTankLinesList() async {
    models.DocumentList theTankLinesList = await returnTankLines();

    clearTankLines();

    for (int theIndex = 0; theIndex < theTankLinesList.total; theIndex++) {
      models.Document theTankLine = theTankLinesList.documents[theIndex];

      bool isTankLineInUse = await isThisTankLineUsedByAnyTank(theTankLine.$id);
      addTankLineFromDatabase(theTankLine
          .$id, isTankLineInUse, theTankLine.data['tank_line']);
    }
    sortTankLines();
  }

  List<ValueItem> convertTankLinesToValueItems() {
    List<ValueItem> tankLineListAsValueItemList = <ValueItem>[];

    // new tanks get assigned this value
    tankLineListAsValueItemList.add(const ValueItem(label: cTankLineLabelNotYetAssigned, value: cTankLineLabelNotYetAssigned));

    for (int theIndex = 0; theIndex < tankLinesList.length; theIndex++) {
      tankLineListAsValueItemList.add(ValueItem(label: tankLinesList[theIndex].tankLine, value: tankLinesList[theIndex].documentId));
    }
    return tankLineListAsValueItemList;
  }
}
