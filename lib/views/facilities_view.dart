import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/facilities_viewmodel.dart';
import 'facility_grid.dart';
import 'utility.dart';
import '../views/consts.dart';

class FacilitiesView extends StatefulWidget {
  const FacilitiesView({
    super.key,
  });

  @override
  State<FacilitiesView> createState() =>
      _FacilitiesController();
}

class _FacilitiesController
    extends State<FacilitiesView> {
  TextEditingController controllerForFacilityName = TextEditingController();
  TextEditingController controllerForFacilityBuilding = TextEditingController();
  TextEditingController controllerForFacilityRoom = TextEditingController();

  TextEditingController controllerForMaxShelves = TextEditingController();
  TextEditingController controllerForMaxTanks = TextEditingController();

  TextEditingController controllerForGridWidth = TextEditingController();
  TextEditingController controllerForGridHeight = TextEditingController();

  bool gridLocked = false;

  @override
  initState() {
    FacilityViewModel model =
        Provider.of<FacilityViewModel>(context, listen: false);
    if (model.facilityName != null) {
      // if it is not null, we are editing an existing facility
      controllerForFacilityName.text = model.facilityName!;
      controllerForFacilityBuilding.text = model.facilityBuilding;
      controllerForFacilityRoom.text = model.facilityRoom;
      controllerForGridWidth.text = model.gridWidth.toString();
      controllerForGridHeight.text = model.gridHeight.toString();
      controllerForMaxShelves.text = model.maxShelves.toString();
      controllerForMaxTanks.text = model.maxTanks.toString();

      gridLocked = true; // once the facility is created, some options can't be changed.
    }
    super.initState();
  }

  // basic gist of the problem is that we have a facility loaded somehow and we are reading its values
  // when opening new facility, we need to have a clear function that clears all values of the currently selected facility
  // and then we can safely play with any values
  // void clearCurrentFacilityForNewFacilityEdit()
  // what happens when user cancels? we need to reload selected facility: no, only when clicking facility button
  // plain facility button needs to load selectedfacility's values (since after clicking new facility, items will have been cleared
  // what reads the facilitygrid layout in the rack's page

  @override
  void dispose() {
    // Dispose of the TextEditingController instances
    controllerForFacilityName.dispose();
    controllerForFacilityBuilding.dispose();
    controllerForFacilityRoom.dispose();
    controllerForMaxShelves.dispose();
    controllerForMaxTanks.dispose();
    controllerForGridWidth.dispose();
    controllerForGridHeight.dispose();

    super.dispose();
  }

  TextInputType? returnTextInputType(FacilityStringsEnum facilitystringValue) {
    TextInputType? theType = TextInputType.text;
    switch (facilitystringValue) {
      case FacilityStringsEnum.maxShelves:
      case FacilityStringsEnum.maxTanks:
      case FacilityStringsEnum.gridHeight:
      case FacilityStringsEnum.gridWidth:
        theType = const TextInputType.numberWithOptions(decimal: false);
        break;
      default:
        break;
    }
    return theType;
  }

  bool returnGridLocked(FacilityStringsEnum facilitystringValue) {
    switch (facilitystringValue) {
      case FacilityStringsEnum.facilityName:
      case FacilityStringsEnum.facilitySite:
      case FacilityStringsEnum.facilityBuilding:
      case FacilityStringsEnum.facilityRoom:
        return true;
      case FacilityStringsEnum.maxShelves:
      case FacilityStringsEnum.maxTanks:
      case FacilityStringsEnum.gridHeight:
      case FacilityStringsEnum.gridWidth:
        return !gridLocked;
    }
  }

  Widget buildInnerLabel(
      String labelText,
      TextEditingController textController,
      FacilityViewModel model,
      FacilityStringsEnum facilitystringValue, double width) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 40,
      ),
      child: Row(
        children: [
          Text(
            labelText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 20,
            ),
            width: width,
            child: TextField(
                keyboardType: returnTextInputType(facilitystringValue),
                controller: textController,
                enabled: returnGridLocked(facilitystringValue),
                onChanged: (value) {
                  switch (facilitystringValue) {
                    case FacilityStringsEnum.facilityName:
                      model.facilityName = textController.text;
                      break;
                    case FacilityStringsEnum.facilitySite:
                      model.facilityName = textController.text;
                      break;
                    case FacilityStringsEnum.facilityBuilding:
                      model.facilityBuilding = textController.text;
                      break;
                    case FacilityStringsEnum.facilityRoom:
                      model.facilityRoom = textController.text;
                      break;
                    case FacilityStringsEnum.maxShelves:
                      model.maxShelves = int.parse(textController.text);
                      break;
                    case FacilityStringsEnum.maxTanks:
                      model.maxTanks = int.parse(textController.text);
                      break;
                    case FacilityStringsEnum.gridHeight:
                      if (textController.text != "") {
                        setState(() {
                          model.gridHeight = int.parse(textController.text);
                        });
                      }
                      break;
                    case FacilityStringsEnum.gridWidth:
                      // also have to block non-numeric characters
                      if (textController.text != "") {
                        setState(() {
                          model.gridWidth = int.parse(textController.text);
                        });
                      }
                      break;
                  }
                }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    FacilityViewModel model =
        Provider.of<FacilityViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: Column(
                children: [
                  buildOuterLabelHeadlineSmall(context, "Facility Identity"),
                  Row(
                    children: [
                      buildInnerLabel(
                          "Facility Name", controllerForFacilityName, model,
                          FacilityStringsEnum.facilityName, kFullWidth),
                      buildInnerLabel(
                          "Building", controllerForFacilityBuilding, model,
                          FacilityStringsEnum.facilityBuilding, kFullWidth),
                    ],
                  ),
                  buildInnerLabel("Room", controllerForFacilityRoom, model,
                      FacilityStringsEnum.facilityRoom, kHalfWidth),
                  buildOuterLabelHeadlineSmall(context, "Racks"),
                  Row(
                    children: [
                      buildInnerLabel(
                          "Max shelves per rack", controllerForMaxShelves,
                          model, FacilityStringsEnum.maxShelves, kNumberWidth),
                      buildInnerLabel(
                          "Max tanks per shelf", controllerForMaxTanks,
                          model, FacilityStringsEnum.maxTanks, kNumberWidth),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      buildInnerLabel(
                          "Max grid width", controllerForGridWidth, model,
                          FacilityStringsEnum.gridWidth, kNumberWidth),
                      buildInnerLabel(
                          "Max grid height", controllerForGridHeight, model,
                          FacilityStringsEnum.gridHeight, kNumberWidth),
                      ElevatedButton(
                        onPressed: gridLocked
                            ? null
                            : () async {
                          bool confirmed = await confirmActionSpecifiedInMessage(
                              context, 'Lock in this grid pattern?');
                          setState(() {
                            gridLocked = confirmed;
                          });
                        },
                        child: const Text("Lock in Grid"),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: kIndentWidth),
                    child: buildOuterLabel(context, "Assign Racks (top view)"),
                  ),
                  SizedBox(
                    width: kGridSize,
                    child: (model.gridHeight == 0) || (model.gridWidth == 0)
                        ? Container()
                        : FacilityGrid(tankMode: cFacilityEditableGrid),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: kIndentWidth),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // BUGBroken, we have a problem selected facility is set, but model info is set to whatever
                              // was set here; we need to re-read facility values
                            },
                            child: const Text("Cancel"),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 100,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: kIndentWidth),
                          child: ElevatedButton(
                            onPressed: () {
                              // we may be saving for the first time or for the 50th;
                              // for subsequent saves, we have the document_id and we use that to determine how this function saves
                              model.saveFacility().then((_) {
                                Navigator.of(context).pop();
                                // BUGBroken evaluate to decided just error or Appwrite extension
                              }).catchError((error) {
                                myPrint(error.response);
                              });
                            },
                            child: const Text("Submit"),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
