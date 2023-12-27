import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;
import '../views/consts.dart';
import '../models/tankline_model.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

class TanksLineViewModel with ChangeNotifier {
  final ManageSession _manageSession;
  List<TankLine> tankLinesList = <TankLine>[];

  TanksLineViewModel(this._manageSession);

  void callNotifyListeners() {
    notifyListeners();
  }

  void addTankLineFromDatabase(
      String documentId,
      String tankline) {
    TankLine aTankLine = TankLine(
        documentId: documentId,
        tankline: tankline);

    tankLinesList.add(aTankLine);

  }

  void sortTankLines() {
    tankLinesList.sort((a, b) => a.tankline.toLowerCase().compareTo(b.tankline.toLowerCase()));
  }

  Future<void> saveTankLine(String tankLineToSave, index) async {

    Map<String, dynamic> theTankLineMap = {
      'tank_line': tankLineToSave,
    };

    if (index == cNewTankline) {
      // after saving, we read in the document id and record it in the tankline object so we can know which document it is for future editing
      models.Document theTankLineDocument = await _manageSession.createDocument(theTankLineMap, cTankLinesCollection);

      addTankLineFromDatabase(theTankLineDocument.$id,tankLineToSave);
      sortTankLines();
    } else {

      //BUGfixed, was passing tankline and not document id
      await _manageSession.updateDocument(
          theTankLineMap, cTankLinesCollection, tankLinesList[index].documentId!);

      //BUGfixed, we weren’t updating the list itself
      tankLinesList[index].tankline = tankLineToSave;
      // do not sort because if the edited tankline ends up in a different position, it will appear to disappear from the list and confuse the user
    }
  }

  bool isThisTankLineInUse(String editedTankLine, index) {

    // strip trailing space character and then do the comparison
    editedTankLine = editedTankLine.trimRight();

    if (index != cNewTankline) {
      List<String> tankLinesTempList = <String>[];
      for (int theIndex = 0; theIndex < tankLinesList.length; theIndex++) {
        // don’t test against the selected index; it will always match
        if (index != theIndex) {
          tankLinesTempList.add(tankLinesList[theIndex].tankline);
        }
      }
      return tankLinesTempList.contains(editedTankLine);
    } else {
      // we are testing against the embedded the tankline string inside the tankline class here
      return tankLinesList.any((tankLine) => tankLine.tankline.toLowerCase() == editedTankLine.toLowerCase());
    }
  }

  // new tanks will have "" as tankLineFk
  ValueItem returnTankLineFromDocId(String tankLineFk) {
    String? matchingTankLine = "";
    for (TankLine tankLine in tankLinesList) {
      if (tankLine.documentId?.contains(tankLineFk) == true) {
        matchingTankLine = tankLine.tankline;
        break;
      }
    }
    return ValueItem(label: matchingTankLine!, value: tankLineFk);
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
      addTankLineFromDatabase(theTankLine
          .$id, theTankLine.data['tank_line']);
    }
    sortTankLines();
  }

  List<ValueItem> convertTankLinesToValueItems() {
    List<ValueItem> tankLineListAsValueItemList = <ValueItem>[];

    // new tanks get assigned this value
    // problem is that we do have a real tank line with this value: removed it
    tankLineListAsValueItemList.add(const ValueItem(label: cTankLineLabelNotYetAssigned, value: ""));

    for (int theIndex = 0; theIndex < tankLinesList.length; theIndex++) {
      tankLineListAsValueItemList.add(ValueItem(label: tankLinesList[theIndex].tankline, value: tankLinesList[theIndex].documentId));
    }
    return tankLineListAsValueItemList;
  }

}
