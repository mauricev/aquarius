import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import '../view_models/session_key.dart';
import 'package:appwrite/models.dart' as models;
import '../views/consts.dart';
import '../models/tankitem_model.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

abstract class TankItemsViewModel with ChangeNotifier {
  final ManageSession manageSession;
  String tankItemAttribute = "assigned in subclass";
  String tankItemsCollection = "assigned in subclass";

  List<TankItem> tankItemsList = <TankItem>[];

  TankItemsViewModel({required this.manageSession});

  void callNotifyListeners() {
    notifyListeners();
  }

  // we could preflight the list; in the command below, we could

  void addTankItemFromDatabase(
      String documentId, bool tankLineInUse,
      String tankItemName) {
    TankItem aTankItem = TankItem(
        documentId: documentId,
        tankItemInUse: tankLineInUse,
        tankItemName: tankItemName);

    tankItemsList.add(aTankItem);
  }

  void sortTankItems() {
    tankItemsList.sort((a, b) => a.tankItemName.toLowerCase().compareTo(b.tankItemName.toLowerCase()));
  }

  List<ValueItem> returnTankItemListAsValueItemList() {

    List<ValueItem> valueItemList = <ValueItem>[];

    for (int theIndex = 0; theIndex < tankItemsList.length; theIndex++) {
      ValueItem valueItem = ValueItem(label: tankItemsList[theIndex].tankItemName,value: tankItemsList[theIndex].documentId);
      valueItemList.add(valueItem);
    }
    return valueItemList;
  }

  Future<void> deleteTankItem(int index) async {
    await manageSession.deleteDocument(tankItemsCollection, tankItemsList[index].documentId!);
    // BUGFixed 2024-03-06
    // must update the list itself
    tankItemsList.removeAt(index);
  }

  Future<void> saveTankItem(String tankItemToSave, index) async {

    Map<String, dynamic> theItemMap = {
      tankItemAttribute: tankItemToSave,
    };

    if (index == cNewTankItem) {
      // after saving, we read in the document id and record it in the tankline object so we can know which document it is for future editing
      models.Document theTankItemDocument = await manageSession.createDocument(theItemMap, tankItemsCollection);

      addTankItemFromDatabase(theTankItemDocument.$id, cTankItemNotInUse, tankItemToSave); // this tankline is new and won't be in use
      sortTankItems();
    } else {

      //BUGfixed, was passing tankline and not document id
      await manageSession.updateDocument(
          theItemMap, tankItemsCollection, tankItemsList[index].documentId!);

      //BUGfixed, we weren’t updating the list itself
      tankItemsList[index].tankItemName = tankItemToSave;
      // do not sort because if the edited tankline ends up in a different position, it will appear to disappear from the list and confuse the user
    }
  }

  Future<bool> isThisTankItemUsedByAnyTank(String tankItemDocmentId) async {
    // here we need to search across all tanks for this tanklinedocumentid
    List<String>? tankItemQuery = [
      Query.equal(tankItemAttribute, tankItemDocmentId),
      Query.limit(
          5000), // BUGfixed, internal default appwrite limit is 25 items returned
    ];
    models.DocumentList theDocumentList = await manageSession.queryDocument(cTankCollection, tankItemQuery);
    return (theDocumentList.total > 0);
  }

  // if we are editing a tankline and rename it such that it matches another tankline, we have a conflict
  // this method tells us this
  // it is NOT telling us whether the tankline is being used by any tanks
  bool isThisTankItemInUse(String editedTankItem, index) {
    // strip trailing space character and then do the comparison
    editedTankItem = editedTankItem.trimRight();

    if (index != cNewTankItem) {
      List<String> tankItemsTempList = <String>[];
      for (int theIndex = 0; theIndex < tankItemsList.length; theIndex++) {
        // don’t test against the selected index; it will always match
        if (index != theIndex) {
          tankItemsTempList.add(tankItemsList[theIndex].tankItemName);
        }
      }
      return tankItemsTempList.contains(editedTankItem);
    } else {
      // we are testing against the tankline string inside the tankline class here
      return tankItemsList.any((tankItem) => tankItem.tankItemName.toLowerCase() == editedTankItem.toLowerCase());
    }
  }

  // new tanks will have "" as tankLineFk
  ValueItem returnTankItemFromDocId(String? tankItemFk) {
    if (tankItemFk == null) {
      return const ValueItem(label: "", value: null);
    }
    String matchingTankItem = "";
    for (TankItem tankItem in tankItemsList) {
      if (tankItem.documentId == tankItemFk) {
        matchingTankItem = tankItem.tankItemName;
        break;
      }
    }
    return ValueItem(label: matchingTankItem, value: tankItemFk);
  }

  void clearTankItems() {
    tankItemsList.clear();
  }

  Future<models.DocumentList> returnTankItems() async {
    List<String>? tankItemsQuery = [
      Query.limit(5000),
    ];

    return await manageSession.queryDocument(
        tankItemsCollection, tankItemsQuery);
  }

  Future<void> buildTankItemsList() async {
    models.DocumentList theTankItemsList = await returnTankItems();

    clearTankItems();

    for (int theIndex = 0; theIndex < theTankItemsList.total; theIndex++) {
      models.Document theTankItem = theTankItemsList.documents[theIndex];

      bool isTankItemInUse = await isThisTankItemUsedByAnyTank(theTankItem.$id);

      addTankItemFromDatabase(theTankItem
          .$id, isTankItemInUse, theTankItem.data[tankItemAttribute]);
    }
    sortTankItems();
  }

  List<ValueItem> convertTankItemsToValueItems() {
    List<ValueItem> tankItemListAsValueItemList = <ValueItem>[];

    // new tanks get assigned this value
    tankItemListAsValueItemList.add(const ValueItem(label: cTankLineLabelNotYetAssigned, value: cTankLineLabelNotYetAssigned));

    for (int theIndex = 0; theIndex < tankItemsList.length; theIndex++) {
      tankItemListAsValueItemList.add(ValueItem(label: tankItemsList[theIndex].tankItemName, value: tankItemsList[theIndex].documentId));
    }
    return tankItemListAsValueItemList;
  }
}

class TanksLineViewModel extends TankItemsViewModel {
  TanksLineViewModel({required super.manageSession}) {
    tankItemAttribute = "tank_line";
    tankItemsCollection = cTankLinesCollection;
  }
}

class GenoTypeViewModel extends TankItemsViewModel {
  GenoTypeViewModel({required super.manageSession}) {
    tankItemAttribute = "genotype";
    tankItemsCollection = cGenoTypeCollection;
  }
}
