import 'package:aquarius/view_models/tankitems_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utility.dart';
import '../views/consts.dart';
import '../views/typography.dart';
import 'package:flutter/services.dart';
import 'package:appwrite/appwrite.dart';

class TanksItemView extends StatefulWidget {
  final TankItemType whichTankItemType;

  const TanksItemView({super.key, required this.whichTankItemType});

  @override
  State<TanksItemView> createState() => _TanksItemViewState();
}

class _TanksItemViewState extends State<TanksItemView> {
  final ScrollController _scrollController = ScrollController();
  String createItemLabel = cCreateTankLines;
  String createNewItemLabel = cCreateNewTankLines;
  String newItemLabel = cNewTankLine;
  String editItemsLabel = cEditTankLines;
  String editItemLabel = cEditTankLine;
  String modifyItemLabel = cModifyTankLine;
  String deleteItemsLabel = cDeleteTankLines;
  String deleteItemLabel = cDeleteTankLine;
  String inUseItemLabel = cTankLineInUse;
  String cantBeBlankLabel = cTankLineCantBeBlank;
  String existingItemLabel = cTankLineExisting;

  int? modeSelection = cEditTankMode;

  @override
  void initState() {
    if (widget.whichTankItemType == TankItemType.eGenoType) {
      createItemLabel = cCreateGenoTypes;
      createNewItemLabel = cCreateNewGenoTypes;
      newItemLabel = cNewGenotype;
      editItemsLabel = cEditGenotypes;
      editItemLabel = cEditGenotype;
      modifyItemLabel = cModifyGenotype;
      deleteItemsLabel = cDeleteGenotypes;
      deleteItemLabel = cDeleteGenotype;
      inUseItemLabel = cGenoTypeInUse;
      cantBeBlankLabel = cGenoTypeCantBeBlank;
      existingItemLabel = cGenoTypeExisting;
    }
    super.initState();
  }

  TankItemsViewModel returnViewModel(BuildContext context, bool listenState) {
    if (widget.whichTankItemType == TankItemType.eGenoType) {
      return Provider.of<GenoTypeViewModel>(context, listen: listenState);
    } else {
      return Provider.of<TanksLineViewModel>(context, listen: listenState);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget tankItemEditDeleteMode(String modeLabel, int radioBtnValue) {
    // const cEditTankMode = 1;
    // const cDeleteTankMode = 2;
    return Expanded(
      child: RadioListTile<int>(
        title: Text(
          modeLabel,
        ),
        value:
            radioBtnValue, // this tells us which of the radio buttons we are addressing,
        // below gives the value of the radio buttons as a group
        groupValue: modeSelection,
        onChanged: (value) {
          setState(() {
            modeSelection = value;
          });
        },
      ),
    );
  }

  void deleteTankItem(BuildContext context,
      {String tankItemName = "", int index = cInvalidTankItem}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(deleteItemLabel),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(tankItemName),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        cTankItemDialogCancelled); // no change, nothing to save
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(cTankItemDialogOKed);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ).then((tankItemDialogStatus) {
      if (tankItemDialogStatus == cTankItemDialogOKed) {
        TankItemsViewModel tanksLineViewModel = returnViewModel(context, false);

        tanksLineViewModel.deleteTankItem(index).then((value) {
          tanksLineViewModel.callNotifyListeners();
        }).catchError((error) {
          if (error is AppwriteException) {
            String? errorMessage = error.message;
            _showErrorDialog(context, errorMessage!);
          } else {
            _showErrorDialog(context, error);
          }
        });
      }
    });
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Updated Tank Info Failed to Save!'),
        content: Text(errorMessage),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  void editTankItem(BuildContext context, bool isCreateTankItemToBeCreated,
      {String tankItemName = "", int index = cNewTankItem}) {

    TankItemsViewModel tanksItemViewModel = returnViewModel(context, false);

    TextEditingController controllerForTankItem = TextEditingController();
    controllerForTankItem.text = tankItemName;

    TankItemStatusEnum tankItemStatus = TankItemStatusEnum.eTankItemReadyToEdit;
    if (index == cNewTankItem) {
      tankItemStatus = TankItemStatusEnum.eTankItemBlank;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: isCreateTankItemToBeCreated
                  ? Text(newItemLabel)
                  : Text(editItemLabel),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    autofocus: true,
                    maxLength: cTankItemMaxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    style: Theme.of(context).textTheme.bodyMedium,
                    keyboardType: TextInputType.text,
                    controller: controllerForTankItem,
                    onChanged: (value) {
                      setState(() {
                        if (value == "") {
                          tankItemStatus = TankItemStatusEnum.eTankItemBlank;
                        } else {
                          tanksItemViewModel.isThisTankItemInUse(value, index)
                              ? tankItemStatus =
                                  TankItemStatusEnum.eTankItemInUse
                              : tankItemStatus =
                                  TankItemStatusEnum.eTankItemReadyToEdit;
                        }
                      });
                    },
                  ),
                  (tankItemStatus == TankItemStatusEnum.eTankItemReadyToEdit)
                      ? const Text("")
                      : (tankItemStatus == TankItemStatusEnum.eTankItemBlank)
                          ? Text(cantBeBlankLabel)
                          : Text(existingItemLabel),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        cTankItemDialogCancelled); // no change, nothing to save
                  },
                ),
                TextButton(
                  onPressed: (tankItemStatus !=
                          TankItemStatusEnum.eTankItemReadyToEdit)
                      ? null
                      : () {
                          Navigator.of(context).pop(cTankItemDialogOKed);
                        },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ).then((tankItemDialogStatus) {
      if (tankItemDialogStatus == cTankItemDialogOKed) {
        TankItemsViewModel tanksItemViewModel = returnViewModel(context, false);

        // we compared a trim right version of the text above; we save it that way too.
        // BUGbroken should we test for appwrite exception instead?
        tanksItemViewModel
            .saveTankItem(controllerForTankItem.text.trimRight(), index)
            .then((value) {
          tanksItemViewModel.callNotifyListeners();
        }).catchError((error) {
          _showErrorDialog(context, error);
        });
      }
    });
  }

  Widget createNewTankItemBtn(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        editTankItem(
          context,
          cTankItemToBeCreated,
        );
      },
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(
          const Size(200, 50),
        ),
      ),
      child: Text(createNewItemLabel),
    );
  }

  void tankInUseDialog(String tankItemName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(inUseItemLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(tankItemName),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(cTankItemDialogOKed);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget searchedItem(context, String tankItemName, bool tankItemInUse, int index) {
    return GestureDetector(
      onTap: () {
        if (modeSelection == cEditTankMode) {
          //BUGfixed, had the new tank constant
          editTankItem(context, cTankItemToBeEdited,
              tankItemName: tankItemName, index: index);
        } else {
          // do not delete tanklines in use
          // we can simply put a dialog that says it’s in use
          // can we create a dialog that lists the tanks that are using this tankline?
          // or is this too complicated?
          // for now, we will just put a dialog that say it's in use
          tankItemInUse
              ? tankInUseDialog(tankItemName)
              : deleteTankItem(context, tankItemName: tankItemName, index: index);
        }
      },
      child: Container(
        color: (index % 2 == 0) ? blueShades[100] : blueShades[200],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Row(
                children: [
                  Text(
                    tankItemName,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TankItemsViewModel tanksItemViewModel = returnViewModel(context, true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: Column(
        children: [
          buildOuterLabelHeadlineSmall(context, modifyItemLabel),
          Row(
            children: [
              tankItemEditDeleteMode(editItemsLabel, cEditTankMode),
              tankItemEditDeleteMode(deleteItemsLabel, cDeleteTankMode),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 8 / 12,
            width: MediaQuery.of(context).size.width * 5 / 6,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility:
                  true, // we want the user to always see the scrollbar, so wrap listview in a scrollbar and set this to true
              thickness: 20,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: tanksItemViewModel.tankItemsList.length,
                itemBuilder: (BuildContext context, int index) {
                  return searchedItem(
                      context,
                      tanksItemViewModel.tankItemsList[index].tankItemName,
                      tanksItemViewModel.tankItemsList[index].tankItemInUse,
                      index);
                },
              ),
            ),
          ),
          buildOuterLabelHeadlineSmall(context, createItemLabel),
          createNewTankItemBtn(context),
        ],
      ),
    );
  }
}