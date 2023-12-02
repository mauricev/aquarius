import 'package:aquarius/view_models/tanklines_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utility.dart';
import '../views/consts.dart';
import '../views/typography.dart';
import 'package:flutter/services.dart';

class TankslineView extends StatelessWidget {
  const TankslineView({super.key});

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
                    maxLength: 60,
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
                  child: const Text('OK'),
                  onPressed: (tankLineStatus !=
                          TankLineStatusEnum.eTankLineReadyToEdit)
                      ? null
                      : () {
                          Navigator.of(context).pop(cTankLineDialogOKed);
                        },
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
            .saveTankLine(controllerForTankLine.text, index)
            .then((value) {})
            .catchError((error) {
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
      child: Text("Create New Tankline…"),
    );
  }

  Widget searchedItem(context, String tankLine, int index) {
    return GestureDetector(
      onTap: () {
        //BUGfixed, had new tank constant
        editTankLine(context, cTankLineToBeEdited,
            tankLine: tankLine, index: index);
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
          buildOuterLabelHeadlineSmall(context, "Tanklines (tap to edit)"),
          SizedBox(
            height: MediaQuery.of(context).size.height * 7 / 12,
            width: MediaQuery.of(context).size.width * 5 / 6,
            child: ListView.builder(
              itemCount: tanksLineViewModel.tankLinesList.length,
              itemBuilder: (BuildContext context, int index) {
                return searchedItem(context,
                    tanksLineViewModel.tankLinesList[index].tankline, index);
              },
            ),
          ),
          buildOuterLabelHeadlineSmall(context, "Create Tanklines"),
          createNewTankLineBtn(context),
        ],
      ),
    );
  }
}
