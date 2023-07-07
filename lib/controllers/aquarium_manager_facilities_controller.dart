import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/aquarium_manager_facilities_model.dart';
import '../views/facility_grid.dart';
import '../views/utility.dart';
import 'package:aquarium_manager/views/consts.dart';

class MyAquariumManagerFacilitiesController extends StatefulWidget {
  const MyAquariumManagerFacilitiesController({
    Key? key,
  }) : super(key: key);

  @override
  State<MyAquariumManagerFacilitiesController> createState() =>
      _MyAquariumManagerFacilitiesController();
}

class _MyAquariumManagerFacilitiesController
    extends State<MyAquariumManagerFacilitiesController> {
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
    MyAquariumManagerFacilityModel model =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);
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

  Future<bool> confirmGridSetting(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmation'),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
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
      MyAquariumManagerFacilityModel model,
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
                        myPrint("gridheight is ${model.gridHeight}");
                      }
                      break;
                    case FacilityStringsEnum.gridWidth:
                      // also have to block non-numeric characters
                      if (textController.text != "") {
                        setState(() {
                          model.gridWidth = int.parse(textController.text);
                        });
                        myPrint("gridWidth is ${model.gridWidth}");
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
    MyAquariumManagerFacilityModel model =
        Provider.of<MyAquariumManagerFacilityModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: Column(
        children: [
          buildOuterLabelHeadlineSmall(context, "Facility Identity"),
          Row(
            children: [
              buildInnerLabel("Facility Name", controllerForFacilityName, model,
                  FacilityStringsEnum.facilityName,kFullWidth),
              buildInnerLabel("Building", controllerForFacilityBuilding, model,
                  FacilityStringsEnum.facilityBuilding,kFullWidth),
            ],
          ),
          buildInnerLabel("Room", controllerForFacilityRoom, model,
              FacilityStringsEnum.facilityRoom, kHalfWidth),
          buildOuterLabelHeadlineSmall(context, "Racks"),
          Row(
            children: [
              buildInnerLabel("Max shelves per rack", controllerForMaxShelves,
                  model, FacilityStringsEnum.maxShelves, kNumberWidth),
              buildInnerLabel("Max tanks per shelf", controllerForMaxTanks,
                  model, FacilityStringsEnum.maxTanks, kNumberWidth),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          Row(
            children: [
              buildInnerLabel("Max grid width", controllerForGridWidth, model,
                  FacilityStringsEnum.gridWidth, kNumberWidth),
              buildInnerLabel("Max grid height", controllerForGridHeight, model,
                  FacilityStringsEnum.gridHeight, kNumberWidth),
              ElevatedButton(
                onPressed: gridLocked
                    ? null
                    : () async {
                        bool confirmed = await confirmGridSetting(
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
            padding: const EdgeInsets.only(left:20.0),
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
                  padding: const EdgeInsets.only(left: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
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
                  padding: const EdgeInsets.only(right: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      myPrint("inside save button");
                      // we may be saving for the first time or for the 50th;
                      // for subsequent saves, we have the document_id and we use that to determine how this function saves
                        model.saveFacility().then((_) {
                          myPrint("facility and racks were saved");
                          Navigator.of(context).pop();
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
    );
  }
}
