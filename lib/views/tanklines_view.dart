import 'package:aquarius/view_models/tanklines_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utility.dart';
import '../views/consts.dart';
import '../views/typography.dart';
import 'package:flutter/services.dart';
import 'package:appwrite/appwrite.dart';

class TanksLineView extends StatefulWidget {
  const TanksLineView({super.key});

  @override
  State<TanksLineView> createState() => _TanksLineViewState();
}

class _TanksLineViewState extends State<TanksLineView> {
  final ScrollController _scrollController = ScrollController();

  int? modeSelection = cEditTankMode;

  Widget tankLineEditDeleteMode(String modeLabel, int radioBtnValue) {
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

  void deleteTankLine(BuildContext context,
      {String tankLine = "", int index = cInvalidTankLine}) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Delete Tankline'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(tankLine),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        cTankLineDialogCancelled); // no change, nothing to save
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(cTankLineDialogOKed);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ).then((tankLineDialogStatus) {
      if (tankLineDialogStatus == cTankLineDialogOKed) {
        TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

        tanksLineViewModel
            .deleteTankLine(index)
            .then((value) {
              myPrint("are listeners being called");
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

  void editTankLine(BuildContext context, bool isCreateTankLineToBeCreated,
      {String tankLine = "", int index = cNewTankline}) {
    TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    TextEditingController controllerForTankLine = TextEditingController();
    controllerForTankLine.text = tankLine;

    TankLineStatusEnum tankLineStatus = TankLineStatusEnum.eTankLineReadyToEdit;
    if (index == cNewTankline) {
      tankLineStatus = TankLineStatusEnum.eTankLineBlank;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: isCreateTankLineToBeCreated
                  ? const Text('New Tankline')
                  : const Text('Edit Tankline'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    autofocus: true,
                    maxLength: cTankLineMaxLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    style: Theme.of(context).textTheme.bodyMedium,
                    keyboardType: TextInputType.text,
                    controller: controllerForTankLine,
                    onChanged: (value) {
                      setState(() {
                        if (value == "") {
                          tankLineStatus = TankLineStatusEnum.eTankLineBlank;
                        } else {
                          tanksLineViewModel.isThisTankLineInUse(value, index)
                              ? tankLineStatus =
                                  TankLineStatusEnum.eTankLineInUse
                              : tankLineStatus =
                                  TankLineStatusEnum.eTankLineReadyToEdit;
                        }
                      });
                    },
                  ),
                  (tankLineStatus == TankLineStatusEnum.eTankLineReadyToEdit)
                      ? const Text("")
                      : (tankLineStatus == TankLineStatusEnum.eTankLineBlank)
                          ? const Text("Tankline can’t be blank")
                          : const Text("That’s an existing tankline"),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        cTankLineDialogCancelled); // no change, nothing to save
                  },
                ),
                TextButton(
                  onPressed: (tankLineStatus !=
                          TankLineStatusEnum.eTankLineReadyToEdit)
                      ? null
                      : () {
                          Navigator.of(context).pop(cTankLineDialogOKed);
                        },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    ).then((tankLineDialogStatus) {
      if (tankLineDialogStatus == cTankLineDialogOKed) {
        TanksLineViewModel tanksLineViewModel =
            Provider.of<TanksLineViewModel>(context, listen: false);

        // we compared a trim right version of the text above; we save it that way too.
        // BUGbroken should we test for appwrite exception instead?
        tanksLineViewModel
            .saveTankLine(controllerForTankLine.text.trimRight(), index)
            .then((value) {
          tanksLineViewModel.callNotifyListeners();
        }).catchError((error) {
          _showErrorDialog(context, error);
        });
      }
    });
  }

  Widget createNewTankLineBtn(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        editTankLine(
          context,
          cTankLineToBeCreated,
        );
      },
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(
          const Size(200, 50),
        ),
      ),
      child: const Text("Create New Tankline…"),
    );
  }

  void tankInUseDialog(String tankLine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('This TankLine is in Use'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(tankLine),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(cTankLineDialogOKed);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
    );
  }

  Widget searchedItem(context, String tankLine, bool tankLineInUse, int index) {
    return GestureDetector(
      onTap: () {
        if (modeSelection == cEditTankMode) {
          //BUGfixed, had the new tank constant
          editTankLine(context, cTankLineToBeEdited,
              tankLine: tankLine, index: index);
        } else {
          // do not delete tanklines in use
          // we can simply put a dialog that says it’s in use
          // can we create a dialog that lists the tanks that are using this tankline?
          // or is this too complicated?
          // for now, we will just put a dialog that say it's in use
          tankLineInUse ? tankInUseDialog(tankLine) : deleteTankLine(context,tankLine: tankLine, index: index);
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
                    tankLine,
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
    TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: Column(
        children: [
          buildOuterLabelHeadlineSmall(context, "Tanklines (tap to modify)"),
          Row(
            children: [
              tankLineEditDeleteMode("Edit TankLines", cEditTankMode),
              tankLineEditDeleteMode("Delete TankLines", cDeleteTankMode),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 8 / 12,
            width: MediaQuery.of(context).size.width * 5 / 6,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true, // we want the user to always see the scrollbar, so wrap listview in a scrollbar and set this to true
              thickness: 20,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: tanksLineViewModel.tankLinesList.length,
                itemBuilder: (BuildContext context, int index) {
                  return searchedItem(context,
                      tanksLineViewModel.tankLinesList[index].tankLine, tanksLineViewModel.tankLinesList[index].tankLineInUse, index);
                },
              ),
            ),
          ),
          buildOuterLabelHeadlineSmall(context, "Create Tanklines"),
          createNewTankLineBtn(context),
        ],
      ),
    );
  }
}
