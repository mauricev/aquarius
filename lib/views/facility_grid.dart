import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/aquarium_manager_facilities_model.dart';
import '../model/aquarium_manager_tanks_model.dart';

enum facilityStringsEnum {
  facilityName,
  facilitySite,
  facilityBuilding,
  facilityRoom,
  maxShelves,
  maxTanks,
  gridHeight,
  gridWidth
}

// for facilities, the grid itself should always remain editable
// the tank screen displays the grid, but is selectable and only for text with racks
const cFacilityEditableGrid = false; // tankMode is false
const cFacilityClickableGrid = true; // tankMode is true; we are on the tank page

class FacilityGridCell extends StatefulWidget {
  final int absolutePosition; // this can’t be altered
  double height;
  double width;
  String relativePosition;
  bool? tankMode;

  FacilityGridCell(
      {Key? key,
        this.absolutePosition =
        0, // index starts at 1, so 0 means it’s not yet assigned, which is never the case
        this.height = 0,
        this.width = 0,
        this.relativePosition = "",
        this.tankMode})
      : super(key: key);
  @override
  State<FacilityGridCell> createState() => _FacilityGridCellState();
}

class _FacilityGridCellState extends State<FacilityGridCell> {
  @override
  initState() {
    super.initState();
  }

  Color ReturnGridCellColor (bool isInFacility, int index, bool isRackCellSelected ) {
    Color returnColor  = Colors.transparent;
    switch(isInFacility) {
      case true:
        returnColor = Colors.transparent;
        break;
      case false:
        if (isRackCellSelected) {
          returnColor = Colors.white;
        }
        if (index == -1) { // this means there is no text in the current cell
          returnColor = Colors.grey;
        }
        break;
    }
    return returnColor;
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerFacilityModel facilityModel =
    Provider.of<MyAquariumManagerFacilityModel>(context);

    MyAquariumManagerTanksModel tankModel =
    Provider.of<MyAquariumManagerTanksModel>(context);

    int index =
    facilityModel.indexOfRackWithThisAbsolutePosition(widget.absolutePosition);
    String relativePositionText = "";
    if (index != -1) {
      relativePositionText = widget.relativePosition;
    }

    TextEditingController controllerForRelativePosition =
    TextEditingController(text: relativePositionText);

    return InkWell(
      onTap:
      (widget.tankMode! && (index == -1)) ? null : () {
        print("we are selecting a new rack");
        // POSSIBLE BUG; this is now async
        tankModel.selectThisRackByAbsolutePosition(widget.tankMode, facilityModel,widget.absolutePosition);
      },
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          border: Border.all(),
            color: ReturnGridCellColor(!widget.tankMode!,index, tankModel.isThisRackCellSelected( widget.absolutePosition)),
        ),
        child: TextField(
          controller: controllerForRelativePosition,
          enabled: !widget.tankMode!, // if tankMode is true, disable editing
          onChanged: (value) {

            int index = facilityModel.indexOfRackWithThisAbsolutePosition(
                widget.absolutePosition);

            if (controllerForRelativePosition.text == "") {
              if (index != -1) {
                facilityModel.deleteRack(index);
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

                facilityModel.addRack(widget.absolutePosition,
                    controllerForRelativePosition.text);
              }
            }
          },
        ),
      ),
    );
  }
}

class FacilityGrid extends StatefulWidget {
  FacilityGrid({Key? key, this.tankMode}) : super(key: key);

  List<Row> gridDown = <Row>[];
  bool? tankMode;

  @override
  State<FacilityGrid> createState() => _FacilityGridState();
}

// we draw based gridwidth and gridheight

class _FacilityGridState extends State<FacilityGrid> {
  final int kGridSize = 200;

  List<Widget> buildGridAcross(int absolutePosition,
      MyAquariumManagerFacilityModel model, bool tankMode) {
    List<Widget> gridAcross = <FacilityGridCell>[];

    double height = kGridSize / model.gridHeight;
    double width = kGridSize / model.gridWidth;

    int offset = 0;
    for (int theIndex = 1; theIndex <= model.gridWidth; theIndex++) {
      absolutePosition =
          absolutePosition + offset; //absolutePosition is never 0;
      if(offset == 0) {
        offset = offset + 1;
      }

      String relativePosition =
      model.relativePositionOfRackWithThisAbsolutePosition(
          absolutePosition);

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

  List<Widget> buildGridDown(
      MyAquariumManagerFacilityModel model, bool readOnly) {
    widget.gridDown
        .clear(); // we clear because this is a global variable, so we want to add starting fresh each time

    int offset = 0;
    for (int theIndex = 1; theIndex <= model.gridHeight; theIndex++) {
      widget.gridDown.add(Row(
        children: buildGridAcross(theIndex + offset, model, readOnly),
      ));
      offset = offset + (model.gridWidth - 1); // we are offsetting the index for each row
    }
    return widget.gridDown;
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerFacilityModel model =
    Provider.of<MyAquariumManagerFacilityModel>(context);

    return Center(
      child: Column(
        children: buildGridDown(model, widget.tankMode!),
      ),
    );
  }
}