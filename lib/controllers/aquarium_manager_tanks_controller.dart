import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/aquarium_manager_facilities_model.dart';
import '../model/aquarium_manager_tanks_model.dart';
import '../views/utility.dart';
import '../views/facility_grid.dart';
import 'package:aquarium_manager/views/consts.dart';
import 'package:aquarium_manager/controllers/aquarium_manager_tanks_controller_parkedtank.dart';
import 'package:aquarium_manager/controllers/aquarium_manager_tanks_controller_rackgrid.dart';
import 'package:aquarium_manager/controllers/aquarium_manager_tanks_controller_notes.dart';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

import 'package:flutter_zebra_sdk/flutter_zebra_sdk.dart';

class MyAquariumManagerTankController extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const MyAquariumManagerTankController({Key? key, required this.arguments})
      : super(key: key);

  @override
  MyAquariumManagerTankControllerState createState() =>
      MyAquariumManagerTankControllerState();
}

class MyAquariumManagerTankControllerState
    extends State<MyAquariumManagerTankController> {
  String? incomingRackFk;
  int? incomingTankPosition;

  TextEditingController controllerForTankLine = TextEditingController();
  TextEditingController controllerForBirthDate = TextEditingController();
  TextEditingController controllerForScreenPositive = TextEditingController();

  TextEditingController controllerForNumberOfFish = TextEditingController();

  TextEditingController controllerForGeneration = TextEditingController();

  void _prepareRacksAndTanksForCaller() async {
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context, listen: false);

    MyAquariumManagerFacilityModel facilityModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

    if (incomingRackFk != null && incomingTankPosition != null) {
      if (incomingRackFk! != "0") {
        // parked cells don't have racks associated with them; rack is just 0 as a string.

        int? theRackAbsolutePosition =
            await facilityModel.returnRacksAbsolutePosition(incomingRackFk!);

        await tankModel.selectThisRackByAbsolutePosition(
            cFacilityClickableGrid, facilityModel, theRackAbsolutePosition!);
      }

      tankModel.selectThisTankCellWithoutListener(incomingTankPosition!);
    }
  }

  @override
  void initState() {
    super.initState();

    incomingRackFk = widget.arguments['incomingRack_Fk'];
    incomingTankPosition = widget.arguments['incomingTankPosition'];

    // Call your methods using the BuildContext:
    _prepareRacksAndTanksForCaller();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuild the widget tree
    setState(() {});
  }

  void notesDialog(BuildContext context, MyAquariumManagerTanksModel tanksModel,
      Tank currentTank) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return NotesDialogBody(
            tanksModel: tanksModel, currentTank: currentTank);
      },
    );
  }

  TextInputType? returnTextInputType(TankStringsEnum tankStringsValue) {
    TextInputType? theType = TextInputType.text;
    switch (tankStringsValue) {
      case TankStringsEnum.numberOfFish:
      case TankStringsEnum.generation:
        theType = const TextInputType.numberWithOptions(decimal: false);
        break;
      default:
        break;
    }
    return theType;
  }

  Widget buildInnerLabel(
  String labelText,
      TextEditingController textController,
      MyAquariumManagerTanksModel tanksModel,
      TankStringsEnum tanksStringsValue,[double? width]) {
    // we don't yet know if this edits the original tank in the model list or not
    // but second what happens if the current tank is not a tank at all.
    // do we need a button inside the tank cell to create a tank
    // we could embed a button create tank. once created, the tank will be added
    // to the list of tanks even though has no info and this current tank command below
    // will actually do something

    // so we have two pressing questions will this info save into the actual tank
    Tank? currentTank = tanksModel.returnCurrentPhysicalTank();
    switch (tanksStringsValue) {
      case TankStringsEnum.tankLine:
        textController.text = currentTank?.tankLine ?? "";
        break;
      case TankStringsEnum.generation:
        textController.text = currentTank?.generation.toString() ?? "";
        break;
      case TankStringsEnum.numberOfFish:
        textController.text = currentTank?.numberOfFish.toString() ?? "";
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 40,
      ),
      child: Row(
        children: [
          Text(
            labelText,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 20,
            ),
            width: (width == null) ? kStandardTextWidthDouble : width,
            child: TextField(
                enabled: (currentTank != null),
                style: Theme.of(context).textTheme.bodySmall,
                keyboardType: returnTextInputType(tanksStringsValue),
                controller: textController,
                onChanged: (value) {
                  MyAquariumManagerFacilityModel facilityModel =
                      Provider.of<MyAquariumManagerFacilityModel>(context,
                          listen: false);

                  switch (tanksStringsValue) {
                    case TankStringsEnum.tankLine:
                      currentTank?.tankLine = textController.text;
                      break;
                    case TankStringsEnum.numberOfFish:
                      if(textController.text != "") {
                        currentTank?.numberOfFish =
                            int.parse(textController.text);
                      }
                      break;
                    case TankStringsEnum.generation:
                      if(textController.text != "") {
                        currentTank?.generation =
                            int.parse(textController.text);
                      }
                      break;
                  }

                  tanksModel.saveExistingTank(facilityModel.documentId,
                      (currentTank?.absolutePosition)!);
                }),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context,
      MyAquariumManagerTanksModel tankModel,
      Tank? currentTank,
      int? Function()? retrieveValue,
      void Function(int newValue)? updateValue) async {
    DateTime selectedDate =
        convertMillisecondsToDateTime(retrieveValue?.call() ?? 0);

    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(kStartingYear, kStartingMonth),
        lastDate: DateTime(kEndingYear));
    if (picked != null && picked != selectedDate) {
      setState(() {
        updateValue?.call(picked.millisecondsSinceEpoch);

        MyAquariumManagerFacilityModel facilityModel =
            Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

        tankModel.saveExistingTank(
            facilityModel.documentId, (currentTank?.absolutePosition)!);
      });
    }
  }

  Widget drawDateOfBirth(
      MyAquariumManagerTanksModel tankModel,
      Tank? currentTank,
      int? Function()? retrieveValue,
      void Function(int newValue)? updateValue) {
    return Row(
      children: [
        const Text("Birthdate"),
        const SizedBox(
          height: kIndentWidth,
        ),
        TextButton(
          onPressed: (currentTank == null) ? null : () => _selectDate(
              context, tankModel, currentTank, retrieveValue, updateValue),
          child: Text(buildDateOfBirth(retrieveValue)),
        ),
      ],
    );
  }

  Widget buildCheckBox(
      MyAquariumManagerTanksModel tankModel,
      Tank? currentTank,
      String labelText,
      bool? Function()? retrieveValue,
      void Function(bool newValue)? updateValue) {
    MyAquariumManagerFacilityModel facilityModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        title: Text(
          labelText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: retrieveValue?.call() ?? false,
        onChanged: (currentTank == null) ? null : (newValue) {
          setState(() {
            updateValue?.call(newValue ?? false);
            tankModel.saveExistingTank(
                facilityModel.documentId, (currentTank.absolutePosition));
          });
        },
        controlAffinity:
            ListTileControlAffinity.leading, //  <-- leading Checkbox
      ),
    );
  }

  Widget buildParkedTank(BuildContext context) {
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context);

    if (tankModel.isThereAParkedTank()) {
      Tank? tank = tankModel.returnParkedTankedInfo();

      MyAquariumManagerFacilityModel facilityModel =
          Provider.of<MyAquariumManagerFacilityModel>(context);

      double height = returnHeight(facilityModel);
      double width = returnWidth(facilityModel);

      return ParkedTank(
        height: height,
        width: width,
        tankLine: tank?.tankLine,
        dateOfBirth: tank?.birthDate,
        screenPositive: tank?.screenPositive,
        numberOfFish: tank?.numberOfFish,
        fatTankPosition: tank?.fatTankPosition,
        generation: tank?.generation,
      );
    }
    return Container();
  }

  void printTank(Tank? currentTank) async {
    String tankLineString = currentTank?.tankLine ?? '';
    String screenPositiveString = (currentTank?.getScreenPositive() ?? false)
        ? "screen positive"
        : "screen negative";

    // will need to fix; if getsmalltank != x then small tank is true
    String smallTankString =
        (currentTank?.getSmallTank() ?? false) ? "small tank" : "big tank";
    String numberOfFishString = currentTank?.numberOfFish.toString() ?? "";
    String generationString = currentTank?.generation.toString() ?? "";
    String dateOfBirthString = buildDateOfBirth(currentTank?.getBirthDate);
    String rackFkString = currentTank?.rackFk ?? "";
    String absolutePositionString =
        currentTank?.absolutePosition.toString() ?? "";

    MyAquariumManagerFacilityModel facilityModel =
    Provider.of<MyAquariumManagerFacilityModel>(
        context,
        listen: false);
    String rack = await facilityModel.returnRacksRelativePosition(rackFkString);

    // multiline string requires three quotes
    String zplCode = """
^XA
^FO275,30^A0N,25^FD$tankLineString^FS
^FO275,65^A0N,30^FDDOB:$dateOfBirthString^FS
^FO275,100^A0N,30^FDCount:$numberOfFishString^FS
^FO275,135^A0N,30^FD$smallTankString^FS
^FO275,170^A0N,30^FD$screenPositiveString^FS
^FO275,205^A0N,30^FDGen:F$generationString^FS
^FO275,240^A0N,20^FDRack, $rack; Tank, $absolutePositionString^FS
^FO20,20^BQN,2,8^FH^FDMA:$rackFkString;$absolutePositionString^FS 
^XZ
""";
    final rep = ZebraSdk.printZPLOverTCPIP('10.49.98.105', data: zplCode);
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context);

    // we want a real physical tank here
    Tank? currentTank = tankModel.returnCurrentPhysicalTank();
    myPrint("is currentTank null, $currentTank");

    return Scaffold(
        appBar: AppBar(
        title: const Text(kProgramName),
        ),
      body: ListView( // needed for scrolling the keyboard
          children: [
            buildOuterLabel(context, "Select Rack (top view)"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: FacilityGrid(tankMode: cFacilityClickableGrid),
                ),
              ],
            ),
            buildOuterLabel(context, "Select Tank (facing view)"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RackGrid(),
                buildParkedTank(context),
              ],
            ),
            buildOuterLabel(context, "Tank Info"),
            Row(
              children: [
                buildInnerLabel("Tank Line", controllerForTankLine, tankModel,
                    TankStringsEnum.tankLine, 300),
                drawDateOfBirth(tankModel, currentTank, currentTank?.getBirthDate,
                    currentTank?.setBirthDate),
                buildCheckBox(
                    tankModel,
                    currentTank,
                    "Screen Positive",
                    currentTank?.getScreenPositive,
                    currentTank?.setScreenPositive),
              ],
            ),
            Row(
              children: [
                buildInnerLabel("Number of Fish", controllerForNumberOfFish,
                    tankModel, TankStringsEnum.numberOfFish),

                buildInnerLabel("Generation", controllerForGeneration, tankModel,
                    TankStringsEnum.generation),
              ],
            ),
            Row(
              children: [
                ((currentTank?.absolutePosition == cParkedRackAbsPosition) ||
                        (currentTank == null) ||
                        tankModel.isThereAParkedTank())
                    ? Container()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // remove any padding
                        ),
                        onPressed: () {
                          setState(() {
                            currentTank.parkIt();
                            MyAquariumManagerFacilityModel facilityModel =
                                Provider.of<MyAquariumManagerFacilityModel>(
                                    context,
                                    listen: false);
                            tankModel.saveExistingTank(facilityModel.documentId,
                                cParkedRackAbsPosition);
                          });
                        },
                        child: const Text("Park it"),
                      ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 30,
                  ),
                  child: TextButton(
                    onPressed: (currentTank == null)
                        ? null
                        : () {
                            currentTank.notes.loadNotes().then((_) {
                              notesDialog(context, tankModel, currentTank);
                            }).catchError((error) {});
                          },
                    child: const Text("Notes…"), // this is the button text
                  ),
                ),
                SizedBox(
                  width: 550, //space for the note
                  child: Text(currentTank?.notes.returnCurrentNoteText() ??
                      "No current note"),
                ),
                ElevatedButton(
                    onPressed: (currentTank == null) || (defaultTargetPlatform != TargetPlatform.iOS)
                        ? null
                        : () {
                            printTank(currentTank);
                          },
                    child: const Text("Print")),
              ],
            ),
          ],
        ),
    );
  }
}
