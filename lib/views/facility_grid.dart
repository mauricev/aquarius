import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/facilities_viewmodel.dart';
import '../view_models/tanks_viewmodel.dart';
import '../views/consts.dart';

enum FacilityStringsEnum {
  facilityName,
  facilitySite,
  facilityBuilding,
  facilityRoom,
  maxShelves,
  maxTanks,
  gridHeight,
  gridWidth
}

class FacilityGridCell extends StatelessWidget {
  final int absolutePosition; // this can’t be altered
  final double height;
  final double width;
  final String rackName;
  final FacilityEditState tankMode;

  const FacilityGridCell(
      {super.key,
      this.absolutePosition =
          0, // index starts at 1, so 0 means it’s not yet assigned, which is never the case
      this.height = 0,
      this.width = 0,
      this.rackName = "",
      required this.tankMode});

  Color returnGridCellColor(
      FacilityEditState isInFacility, int index, bool isRackCellSelected) {
    Color returnColor = Colors.transparent;
    switch ((isInFacility == FacilityEditState.editable)) {
      case true:
        returnColor = Colors.transparent;
        break;
      case false:
        if (isRackCellSelected) {
          returnColor = Colors.white;
        }
        if (index == -1) {
          // this means there is no text in the current cell
          returnColor = Colors.grey;
        }
        break;
    }
    return returnColor;
  }

  @override
  Widget build(BuildContext context) {
    FacilityViewModel facilityModel = Provider.of<FacilityViewModel>(context);

    TanksViewModel tankViewModel;
    if(tankMode == FacilityEditState.readonlyMainScreen) {
      tankViewModel = Provider.of<TanksLiveViewModel>(context);
    } else {
      tankViewModel = Provider.of<TanksSelectViewModel>(context);
    }

    int index =
        facilityModel.indexOfRackWithThisAbsolutePosition(absolutePosition);
    String relativePositionText = "";
    if (index != -1) {
      relativePositionText = rackName;
    }

    TextEditingController controllerForRelativePosition =
        TextEditingController(text: relativePositionText);

    return InkWell(
      onTap: ((tankMode == FacilityEditState.editable) && (index == -1))
          ? null
          : () {
              // BUGfixed; this is now async
        tankViewModel.selectThisRackByAbsolutePosition(
                  tankMode, facilityModel, absolutePosition, cNotify);
            },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          border: Border.all(),
          color: returnGridCellColor(tankMode, index,
              tankViewModel.isThisRackCellSelected(absolutePosition)),
        ),
        child: TextField(
          controller: controllerForRelativePosition,
          enabled: tankMode == FacilityEditState.editable,
          // BUGFixed made this facility grid smaller and font size too
          // 2024-05-10
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black,
              ),
          onChanged: (value) {
            int index = facilityModel
                .indexOfRackWithThisAbsolutePosition(absolutePosition);

            if (controllerForRelativePosition.text == "") {
              if (index != -1) {
                // BUGBroken should not delete a rack just because it has no text
                // we need a checkbox in each rack to decide what is a rack and what is corridor

                facilityModel.deleteRack(index); // i think this means if a user deletes the text of a rack, the rack goes away and this probably isn't a good idea.
              }
            } else {
              // we contain some text

              if (index != -1) {
                // 2
                // what if the user is deleting a relative position
                // if it’s in the list, we remove it

                facilityModel.rackList[index].relativePosition =
                    controllerForRelativePosition.text;
              } else {
                // this rack wasn't in the list
                // 3
                // if it’s not in the list, we add it and give its relative position

                facilityModel.addRack(
                    absolutePosition, controllerForRelativePosition.text);
              }
            }
          },
        ),
      ),
    );
  }
}

class FacilityGrid extends StatelessWidget {
  FacilityGrid({super.key, required this.tankMode});

  final FacilityEditState tankMode;
  final List<Row> gridDown = <Row>[];

  List<Widget> buildGridAcross(int absolutePosition,
      FacilityViewModel facilityViewModel, FacilityEditState tankMode) {
    List<Widget> gridAcross = <FacilityGridCell>[];

    double height = kGridHSize / facilityViewModel.gridHeight;
    double width = kGridWSize / facilityViewModel.gridWidth;

    int offset = 0;
    for (int theIndex = 1;
        theIndex <= facilityViewModel.gridWidth;
        theIndex++) {
      absolutePosition =
          absolutePosition + offset; //absolutePosition is never 0;
      if (offset == 0) {
        offset = offset + 1;
      }

      String relativePosition = facilityViewModel
          .relativePositionOfRackWithThisAbsolutePosition(absolutePosition);

      gridAcross.add(FacilityGridCell(
          absolutePosition: absolutePosition, // this is fine
          height: height,
          width: width,
          rackName: relativePosition,
          tankMode:
              tankMode)); // this MUST pass the actual values; it can’t just reset these to nothing
    }
    return gridAcross;
  }

  Row entranceRadioButton(
      int radioBtnValue, FacilityViewModel facilityViewModel, FacilityEditState facilityEditState) {
    int? entranceSelection;

    if ((facilityViewModel.isEntranceAtBottom() == true) &&
        (radioBtnValue == cBottomEntrance)) {
      entranceSelection = cBottomEntrance;
    }
    if ((facilityViewModel.isEntranceAtBottom() == false) &&
        (radioBtnValue == cTopEntrance)) {
      entranceSelection = cTopEntrance;
    }

    return Row(
      children: [
        Container(
          width: kGridWSize,
          child: (facilityEditState == FacilityEditState.editable)
              ? RadioListTile<int>(
                  title: const Text('Pick me if this side is the entrance',
                      style: TextStyle(
                        fontSize: 9.0,
                      )),
                  value:
                      radioBtnValue, // this tells us which of the radio buttons we are addressing
                  // below gives the value of the radio buttons as a group
                  groupValue: entranceSelection,
                  onChanged: (value) {
                    entranceSelection = value;
                    facilityViewModel
                        .setEntranceBottom((entranceSelection == null)
                            ? null
                            : (entranceSelection == cBottomEntrance)
                                ? true
                                : false);
                  },
                  contentPadding: const EdgeInsets.all(0),
                )
              : Center(
                child: Text((entranceSelection == null)
                    ? ""
                    : ((entranceSelection == cBottomEntrance) &&
                            (radioBtnValue == cBottomEntrance))
                        ? "This side is the entrance"
                        : ((entranceSelection == cTopEntrance) &&
                (radioBtnValue == cTopEntrance))
                ? "This side is the entrance"
                : "should never appear"),
              ),
        ),
      ],
    );
  }

  List<Widget> buildGridDown(
      FacilityViewModel facilityViewModel, FacilityEditState facilityEditState) {

    gridDown
        .clear(); // we clear because this is a global variable, so we want to add starting fresh each time

    gridDown
        .add(entranceRadioButton(cTopEntrance, facilityViewModel, facilityEditState));

    int offset = 0;
    for (int theIndex = 1;
        theIndex <= facilityViewModel.gridHeight;
        theIndex++) {
      gridDown.add(Row(
        children:
            buildGridAcross(theIndex + offset, facilityViewModel, facilityEditState),
      ));
      offset = offset +
          (facilityViewModel.gridWidth -
              1); // we are offsetting the index for each row
    }

    gridDown
        .add(entranceRadioButton(cBottomEntrance, facilityViewModel, facilityEditState));

    return gridDown;
  }

  @override
  Widget build(BuildContext context) {
    FacilityViewModel facilityViewModel =
        Provider.of<FacilityViewModel>(context);

    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buildGridDown(facilityViewModel, tankMode),
      ),
    );
  }
}
