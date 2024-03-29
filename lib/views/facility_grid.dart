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

const cTopEntrance = 1;
const cBottomEntrance = 2;

// for facilities, the grid itself should always remain editable
// the tank screen displays the grid, but is selectable and only for text with racks
const cFacilityEditableGrid = false; // tankMode is false
const cFacilityClickableGrid =
    true; // tankMode is true; we are on the tank page

class FacilityGridCell extends StatelessWidget {
  final int absolutePosition; // this can’t be altered
  final double height;
  final double width;
  final String relativePosition;
  final bool? tankMode;

  const FacilityGridCell(
      {super.key,
      this.absolutePosition =
          0, // index starts at 1, so 0 means it’s not yet assigned, which is never the case
      this.height = 0,
      this.width = 0,
      this.relativePosition = "",
      this.tankMode});

  Color returnGridCellColor(
      bool isInFacility, int index, bool isRackCellSelected) {
    Color returnColor = Colors.transparent;
    switch (isInFacility) {
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

    TanksViewModel tankModel = Provider.of<TanksViewModel>(context);

    int index =
        facilityModel.indexOfRackWithThisAbsolutePosition(absolutePosition);
    String relativePositionText = "";
    if (index != -1) {
      relativePositionText = relativePosition;
    }

    TextEditingController controllerForRelativePosition =
        TextEditingController(text: relativePositionText);

    return InkWell(
      onTap: (tankMode! && (index == -1))
          ? null
          : () {
              // BUGfixed; this is now async
              tankModel.selectThisRackByAbsolutePosition(
                  tankMode, facilityModel, absolutePosition, cNotify);
            },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          border: Border.all(),
          color: returnGridCellColor(!tankMode!, index,
              tankModel.isThisRackCellSelected(absolutePosition)),
        ),
        child: TextField(
          controller: controllerForRelativePosition,
          enabled: !tankMode!, // if tankMode is true, disable editing
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
  FacilityGrid({super.key, this.tankMode});

  final bool? tankMode;
  final List<Row> gridDown = <Row>[];

  List<Widget> buildGridAcross(int absolutePosition,
      FacilityViewModel facilityViewModel, bool tankMode) {
    List<Widget> gridAcross = <FacilityGridCell>[];

    double height = kGridSize / facilityViewModel.gridHeight;
    double width = kGridSize / facilityViewModel.gridWidth;

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
          relativePosition: relativePosition,
          tankMode:
              tankMode)); // this MUST pass the actual values; it can’t just reset these to nothing
    }
    return gridAcross;
  }

  Row entranceRadioButton(
      int radioBtnValue, FacilityViewModel facilityViewModel, bool readOnly) {
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
          width: kGridSize,
          child: (!readOnly == cFacilityClickableGrid)
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
      FacilityViewModel facilityViewModel, bool readOnly) {

    gridDown
        .clear(); // we clear because this is a global variable, so we want to add starting fresh each time

    gridDown
        .add(entranceRadioButton(cTopEntrance, facilityViewModel, readOnly));

    int offset = 0;
    for (int theIndex = 1;
        theIndex <= facilityViewModel.gridHeight;
        theIndex++) {
      gridDown.add(Row(
        children:
            buildGridAcross(theIndex + offset, facilityViewModel, readOnly),
      ));
      offset = offset +
          (facilityViewModel.gridWidth -
              1); // we are offsetting the index for each row
    }

    gridDown
        .add(entranceRadioButton(cBottomEntrance, facilityViewModel, readOnly));

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
        children: buildGridDown(facilityViewModel, tankMode!),
      ),
    );
  }
}
