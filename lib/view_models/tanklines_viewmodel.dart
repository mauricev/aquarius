import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;
import '../views/consts.dart';
import '../models/tankline_model.dart';

class TanksLineViewModel with ChangeNotifier {
  final ManageSession _manageSession;
  List<TankLine> tankLinesList = <TankLine>[];

  TanksLineViewModel(this._manageSession);

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
      'tankline': tankLineToSave,
    };

    if (index == cNewTankline) {
      // after saving, we read in the document id and record it in the tankline object so we can know which document it is for future editing
      _manageSession.createDocument(theTankLineMap, cTankLinesCollection).then((value) {

        models.Document theTankLineDocument = value;
        print("addTankLineFromDatabase");
        addTankLineFromDatabase(theTankLineDocument.$id,tankLineToSave);
        sortTankLines();
      });
    } else {

      //BUGfixed, was passing tankline and not document id
      _manageSession.updateDocument(
          theTankLineMap, cTankLinesCollection, tankLinesList[index].documentId!);

      //BUGfixed, we never update the list
      tankLinesList[index].tankline = tankLineToSave;
      // do not sort because if the edited tankline ends up in a different position, it will appear to disappear fron the list and confuse the user
    }
  }

  bool isThisTankLineInUse(String editedTankLine, index) {
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
          .$id, theTankLine.data['tankline']);
    }
    sortTankLines();
  }
}
