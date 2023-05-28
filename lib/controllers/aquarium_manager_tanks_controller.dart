import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/aquarium_manager_facilities_model.dart';
import '../model/aquarium_manager_notes_model.dart';
import '../model/aquarium_manager_tanks_model.dart';
import '../views/utility.dart';
import '../views/facility_grid.dart';

import 'package:flutter_zebra_sdk/flutter_zebra_sdk.dart';

enum tankStringsEnum { tankLine, numberOfFish, generation }

const int kStandardTextWidth = 75;

const cParkedAbsolutePosition = -2;

const kEmptyTankIndex = -1;

class TankCell extends StatefulWidget {
  final int absolutePosition; // this can’t be altered
  double height;
  double width;
  String? tankLine;
  int? dateOfBirth;
  bool? screenPositive;
  int? numberOfFish;
  bool? smallTank;
  int? generation;

  TankCell({
    Key? key,
    this.absolutePosition =
        0, // index starts at 1, so 0 means it’s not yet assigned, which is never the case
    this.height = 0,
    this.width = 0,
    this.tankLine,
    this.dateOfBirth,
    this.screenPositive,
    this.numberOfFish,
    this.smallTank,
    this.generation,
  }) : super(key: key);
  @override
  State<TankCell> createState() => _TankCellState();
}

class _TankCellState extends State<TankCell> {
  @override
  initState() {
    super.initState();
  }

  void CreateTank() {
    MyAquariumManagerFacilityModel facilityModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context, listen: false);

    tankModel.addNewEmptyTank(
        facilityModel.document_id,
        widget
            .absolutePosition); // we call setstate because this function updates the current tank with a new position
    // we need to force select this tank; otherwise, there is no current tank
    tankModel.selectThisTankCell(widget.absolutePosition); // bug fixed here
  }

  void AssignParkedTankItsNewHome(
      Tank? parkedTank, MyAquariumManagerTanksModel tankModel) {
    parkedTank?.absolutePosition = widget.absolutePosition;
    parkedTank?.rackFk = tankModel.rack_documentId;
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context);

    int rackID = tankModel.whichRackCellIsSelected();

    int tankID =
        tankModel.tankIdWithThisAbsolutePosition(widget.absolutePosition);

    return DragTarget(
      builder: (BuildContext context, List<dynamic> candidateData,
          List<dynamic> rejectedData) {
        return InkWell(
          onTap: (rackID == -2)
              ? null
              : () {
                  // make sure we have a selected rack
                  print("we clicked a tank cell");
                  if (tankID != kEmptyTankIndex) {
                    // we only want to select actual tanks at the moment
                    print("we clicked an a real tank cell");
                    tankModel.selectThisTankCell(widget.absolutePosition);
                  }
                },
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              border: Border.all(),
              color: (rackID == -2) // no rack is selected
                  ? Colors.transparent
                  : (tankID !=
                          kEmptyTankIndex) // if we are in tankmode (not editable) and there is no text, we get grayed out
                      ? (tankModel.returnIsThisTankSelected(
                              widget.absolutePosition))
                          ? Colors.lightGreen[800]
                          : Colors.grey // this grid cell has a tank
                      : Colors
                          .transparent, // this grid cell does not have a tank, but we need a third state here
            ),
            child: (rackID == -2) // no rack is selected
                ? Container(
                    child: Text(
                    "no rack selected",
                    style: Theme.of(context).textTheme.bodySmall,
                  ))
                : (tankID == kEmptyTankIndex)
                    ? FractionallySizedBox(
                        widthFactor: 0.9, // Takes 90% of the container's width
                        heightFactor:
                            0.3, // Takes 30% of the container's height
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero, // remove any padding
                          ),
                          onPressed: () {
                            // call facilities model to get facility_fk
                            // call function to return the rack_fk from the selected rack
                            // when we call selectthisrack, why don't we store the rack_fk

                            setState(() {
                              CreateTank();
                            });
                          },
                          child: const Text(
                            "Create Tank",
                            style: TextStyle(
                              fontSize: 7,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      )
                    : Text("${widget.absolutePosition}"),
          ),
        );
      },
      onWillAccept: (data) {
        print("shouldn't we be coming here");
        return true;
      },
      onAccept: (data) {
        //we have to guard against a race condition
        setState(() {
          Tank? parkedTank = data as Tank;

          MyAquariumManagerFacilityModel facilityModel =
              Provider.of<MyAquariumManagerFacilityModel>(context,
                  listen: false);

          MyAquariumManagerTanksModel tankModel =
              Provider.of<MyAquariumManagerTanksModel>(context, listen: false);

          int tankID = tankModel.tankIdWithThisAbsolutePosition(widget
              .absolutePosition); // this represents the new, not parked tank
          if (tankID == kEmptyTankIndex) {
            // there is no tank at this position
            // the user dragged over an empty tank
            // our parked tank needs two new pieces of info
            // a new abs position and the rack_fk
            // do we have a copy of the parked tank or the actual parked tank?
            AssignParkedTankItsNewHome(parkedTank, tankModel);
            // the tank has not been saved with this new info
            tankModel.saveExistingTank(
                facilityModel.document_id, widget.absolutePosition);
          } else {
            // here we are swapping tank positions
            Tank? destinationTank = tankModel
                .returnTankWithThisAbsolutePosition(widget.absolutePosition);

            destinationTank?.rackFk = "0";
            destinationTank?.absolutePosition = cParkedAbsolutePosition;

            AssignParkedTankItsNewHome(parkedTank, tankModel);
            tankModel.saveExistingTank(
                facilityModel.document_id, widget.absolutePosition);
            tankModel.saveExistingTank(
                facilityModel.document_id, cParkedAbsolutePosition);
          }
          tankModel.selectThisTankCell(widget.absolutePosition);
        });
      },
    );
  }
}

class ParkedTank extends StatefulWidget {
  double height;
  double width;
  String? tankLine;
  int? dateOfBirth;
  bool? screenPositive;
  int? numberOfFish;
  bool? smallTank;
  int? generation;

  ParkedTank({
    Key? key,
    this.height = 0,
    this.width = 0,
    this.tankLine,
    this.dateOfBirth,
    this.screenPositive,
    this.numberOfFish,
    this.smallTank,
    this.generation,
  }) : super(key: key);

  @override
  State<ParkedTank> createState() => _ParkedTankState();
}

class _ParkedTankState extends State<ParkedTank> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context);

    int tankID =
        tankModel.tankIdWithThisAbsolutePosition(cParkedAbsolutePosition);

    Tank? thisTank =
        tankModel.returnTankWithThisAbsolutePosition(cParkedAbsolutePosition);
    // i think we can pass the tank to the receiver
    // how do we swap tanks
    // we need a second temporary rack
    // change rack id of receiver to 0 and abs position to -3
    // then change parked rack’s fk to this rack and position to is new position
    // then go back and change

    return Draggable(
      feedback: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          border: Border.all(),
          color: Colors.red,
        ),
      ),
      data: thisTank, // we pass this tank to the draggable target
      child: InkWell(
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            border: Border.all(),
            // we should test tankid here and if it's not in the list, then we should draw transparent; otherwise it should be gray
            color: (tankID !=
                    kEmptyTankIndex) // if we are in tankmode (not editable) and there is no text, we get grayed out
                ? (tankModel.returnIsThisTankSelected(cParkedAbsolutePosition))
                    ? Colors.lightGreen[800]
                    : Colors.grey // this grid cell has a tank
                : Colors
                    .transparent, // this grid cell does not have a tank, but we need a third state here
          ),
          child: Text("${cParkedAbsolutePosition}"),
        ),
        onTap: () {
          if (tankID != kEmptyTankIndex) {
            // we only want to select actual tanks at the moment
            tankModel.selectThisTankCell(cParkedAbsolutePosition);
          }
        },
      ),
    );
  }
}

class RackGrid extends StatefulWidget {
  RackGrid({
    Key? key,
  }) : super(key: key);

  List<Row> gridDown = <Row>[];

  @override
  State<RackGrid> createState() => _RackGridState();
}

// problem to solve how to do we get which rack we have selected
// the tank model has which cell is selected, but we still need to know what this value
// is. how can I know which rack it is?

// we have the absolute position, but not the facility_fk, but we can extract this from the facilitymodel

class _RackGridState extends State<RackGrid> {
  List<Widget> BuildGridAcross(
      int absolutePosition,
      MyAquariumManagerFacilityModel facilityModel,
      MyAquariumManagerTanksModel tanksModel) {
    List<Widget> gridAcross = <TankCell>[];

    double height = ReturnHeight(facilityModel);
    double width = ReturnWidth(facilityModel);

    int offset = 0;
    for (int theIndex = 1; theIndex <= facilityModel.maxTanks; theIndex++) {
      absolutePosition =
          absolutePosition + offset; //absolutePosition is never 0;
      if (offset == 0) {
        offset = offset + 1;
      }
      Tank? tank =
          tanksModel.tankInfoWithThisAbsolutePosition(absolutePosition);

      gridAcross.add(TankCell(
        absolutePosition: absolutePosition,
        height: height,
        width: width,
        tankLine: tank?.tankLine,
        dateOfBirth: tank?.birthDate,
        screenPositive: tank?.screenPositive,
        numberOfFish: tank?.numberOfFish,
        smallTank: tank?.smallTank,
        generation: tank?.generation,
      ));
    }
    return gridAcross;
  }

  // we might want to build designations into the tanks A-6, B-3, etc
  // since we start with index 1, are we leaving out tanks in position zero?
  // no because we are looping through the grid space, not the tanklist
  // for grid cell, we ask if there is a tank for that absolute position
  // if there is, we draw it; if not, we skip to the next one.

  List<Widget> BuildGridDown(MyAquariumManagerFacilityModel facilityModel,
      MyAquariumManagerTanksModel tanksModel) {
    widget.gridDown
        .clear(); // we clear because this is a global variable, so we want to add starting fresh each time

    int offset = 0;
    for (int theIndex = 1; theIndex <= facilityModel.maxShelves; theIndex++) {
      widget.gridDown.add(Row(
        children: BuildGridAcross(theIndex + offset, facilityModel, tanksModel),
      ));
      offset = offset +
          (facilityModel.maxTanks -
              1); // we are offsetting the index for each row by the amount of tanks minus 1
    }
    return widget.gridDown;
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerFacilityModel facilityModel =
        Provider.of<MyAquariumManagerFacilityModel>(context);

    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context);

    return Center(
      child: Column(
        children: BuildGridDown(facilityModel, tankModel),
      ),
    );
  }
}

class NotesDialogBody extends StatefulWidget {
  final Tank currentTank;
  final MyAquariumManagerTanksModel tanksModel;

  const NotesDialogBody(
      {Key? key, required this.tanksModel, required this.currentTank})
      : super(key: key);

  @override
  _NotesDialogBodyState createState() => _NotesDialogBodyState();
}

class _NotesDialogBodyState extends State<NotesDialogBody> {
  Widget notesItem(BuildContext context, Notes notes, int index) {
    TextEditingController controllerForNotesItem = TextEditingController();

    controllerForNotesItem.text = notes?.returnIndexedNoteText(index) ?? "";

    print("i am in notes item for index, ${index}");
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                enabled: (index == 0)
                    ? true
                    : false, //only the current (first) note field is editable
                readOnly: (index == 0) ? false : true,
                controller: controllerForNotesItem,
                onChanged: (value) {
                  notes?.updateNoteText(value);
                  widget.tanksModel
                      .callNotifyListeners(); // we need to update the notes display in the parent folder
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              child: Text(notes?.returnIndexedNoteDate(index) ?? ""),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              child: Text("Add New Note"),
              onPressed: () {
                setState(() {
                  widget.currentTank.notes
                      .addNote(); // also saves the empty note; by this time, we know the tank_fk.
                });
              },
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.currentTank.notes.notesList.length,
            itemBuilder: (BuildContext context, int index) {
              print("notes are ${widget.currentTank.notes}");

              return notesItem(context, widget.currentTank.notes, index);
            },
          ),
        ),
      ],
    );
  }
}

class MyAquariumManagerTankController extends StatefulWidget {
  final Map<String, dynamic> arguments;

  MyAquariumManagerTankController({Key? key, required this.arguments})
      : super(key: key);

  @override
  _MyAquariumManagerTankControllerState createState() =>
      _MyAquariumManagerTankControllerState();
}

class _MyAquariumManagerTankControllerState
    extends State<MyAquariumManagerTankController> {
  String? incomingRack_Fk;
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

    if (incomingRack_Fk != null && incomingTankPosition != null) {
      if (incomingRack_Fk! != "0") {
        // parked cells don't have racks associated with them; rack is just 0 as a string.

        int? theRackAbsolutePosition =
            await facilityModel.returnRacksAbsolutePosition(incomingRack_Fk!);

        await tankModel.selectThisRackByAbsolutePosition(
            cFacilityClickableGrid, facilityModel, theRackAbsolutePosition!);
      }

      tankModel.selectThisTankCellWithoutListener(incomingTankPosition!);
    }
  }

  @override
  void initState() {
    super.initState();

    incomingRack_Fk = widget.arguments['incomingRack_Fk'];
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

  TextInputType? returnTextInputType(tankStringsEnum tankStringsValue) {
    TextInputType? theType = TextInputType.text;
    switch (tankStringsValue) {
      case tankStringsEnum.numberOfFish:
      case tankStringsEnum.generation:
        theType = TextInputType.numberWithOptions(decimal: false);
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
      tankStringsEnum tanksStringsValue,[double? width]) {
    // we don't yet know if this edits the original tank in the model list or not
    // but second what happens if the current tank is not a tank at all.
    // do we need a button inside the tank cell to create a tank
    // we could embed a button create tank. once created, the tank will be added
    // to the list of tanks even though has no info and this current tank command below
    // will actually do something

    // so we have two pressing questions will this info save into the actual tank
    Tank? currentTank = tanksModel.returnCurrentTank();
    switch (tanksStringsValue) {
      case tankStringsEnum.tankLine:
        textController.text = currentTank?.tankLine ?? "";
        break;
      case tankStringsEnum.generation:
        textController.text = currentTank?.generation.toString() ?? "";
        break;
      case tankStringsEnum.numberOfFish:
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
            width: (width == null) ? 75 : width,
            child: TextField(
                style: Theme.of(context).textTheme.bodySmall,
                keyboardType: returnTextInputType(tanksStringsValue),
                controller: textController,
                onChanged: (value) {
                  MyAquariumManagerFacilityModel facilityModel =
                      Provider.of<MyAquariumManagerFacilityModel>(context,
                          listen: false);

                  switch (tanksStringsValue) {
                    case tankStringsEnum.tankLine:
                      currentTank?.tankLine = textController.text;
                      break;
                    case tankStringsEnum.numberOfFish:
                      currentTank?.numberOfFish =
                          int.parse(textController.text);
                      break;
                    case tankStringsEnum.generation:
                      currentTank?.generation = int.parse(textController.text);
                      break;
                  }

                  tanksModel.saveExistingTank(facilityModel.document_id,
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
      int? retrieveValue()?,
      void updateValue(int newValue)?) async {
    DateTime selectedDate =
        ConvertMillisecondsToDateTime(retrieveValue?.call() ?? 0);

    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1969, 1),
        lastDate: DateTime(2024));
    if (picked != null && picked != selectedDate) {
      setState(() {
        updateValue?.call(picked.millisecondsSinceEpoch ?? 0);

        MyAquariumManagerFacilityModel facilityModel =
            Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

        tankModel.saveExistingTank(
            facilityModel.document_id, (currentTank?.absolutePosition)!);
      });
    }
  }

  Widget drawDateOfBirth(
      MyAquariumManagerTanksModel tankModel,
      Tank? currentTank,
      int? retrieveValue()?,
      void updateValue(int newValue)?) {
    return Row(
      children: [
        Text("Birthdate"),
        const SizedBox(
          height: 20.0,
        ),
        TextButton(
          onPressed: () => _selectDate(
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
      bool? retrieveValue()?,
      void updateValue(bool newValue)?) {
    MyAquariumManagerFacilityModel facilityModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

    if (currentTank == null) return Container();

    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        title: Text(
          labelText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: retrieveValue?.call() ?? false,
        onChanged: (newValue) {
          setState(() {
            updateValue?.call(newValue ?? false);
            tankModel.saveExistingTank(
                facilityModel.document_id, (currentTank?.absolutePosition)!);
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

      double height = ReturnHeight(facilityModel);
      double width = ReturnWidth(facilityModel);

      return ParkedTank(
        height: height,
        width: width,
        tankLine: tank?.tankLine,
        dateOfBirth: tank?.birthDate,
        screenPositive: tank?.screenPositive,
        numberOfFish: tank?.numberOfFish,
        smallTank: tank?.smallTank,
        generation: tank?.generation,
      );
    }
    return Container();
  }

  void PrintTank(Tank? currentTank) {
    String tankLineString = currentTank?.tankLine ?? '';
    String screenPositiveString = (currentTank?.getScreenPositive() ?? false)
        ? "screen positive"
        : "screen negative";
    String smallTankString =
        (currentTank?.getSmallTank() ?? false) ? "small tank" : "big tank";
    String numberOfFishString = currentTank?.numberOfFish.toString() ?? "";
    String generationString = currentTank?.generation.toString() ?? "";
    String dateOfBirthString = buildDateOfBirth(currentTank?.getBirthDate);
    String rackFkString = currentTank?.rackFk.toString() ?? "";
    String absolutePositionString =
        currentTank?.absolutePosition.toString() ?? "";

    // multiline string requires three quotes
    String zplCode = """
^XA
^FO275,30^A0N,25^FD${tankLineString}^FS
^FO275,65^A0N,30^FDDOB:${dateOfBirthString}^FS
^FO275,100^A0N,30^FDCount:${numberOfFishString}^FS
^FO275,135^A0N,30^FD${smallTankString}^FS
^FO275,170^A0N,30^FD${screenPositiveString}^FS
^FO275,205^A0N,30^FDGen:F${generationString}^FS
^FO20,20^BQN,2,8^FH^FDMA:${rackFkString};${absolutePositionString}^FS 
^XZ
""";
    final rep = ZebraSdk.printZPLOverTCPIP('192.168.1.163', data: zplCode);
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context);

    Tank? currentTank = tankModel.returnCurrentTank();

    return Scaffold(
      appBar: AppBar(
        title: Text(kProgramName),
      ),
      body: Column(
        children: [
          BuildOuterLabel(context, "Select Rack (top view)"),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: FacilityGrid(tankMode: cFacilityClickableGrid),
              ),
            ],
          ),
          BuildOuterLabel(context, "Select Tank (facing view)"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RackGrid(),
              buildParkedTank(context),
            ],
          ),
          BuildOuterLabel(context, "Tank Info"),
          Row(
            children: [
              // we nee a width parameter
              buildInnerLabel("Tank Line", controllerForTankLine, tankModel,
                  tankStringsEnum.tankLine, 300),
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
                  tankModel, tankStringsEnum.numberOfFish),
              buildCheckBox(tankModel, currentTank, "Small Tank",
                  currentTank?.getSmallTank, currentTank?.setSmallTank),
              buildInnerLabel("Generation", controllerForGeneration, tankModel,
                  tankStringsEnum.generation),
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
                          tankModel.saveExistingTank(facilityModel.document_id,
                              cParkedRackAbsPosition);
                        });
                      },
                      child: Text("Park it"),
                    ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 30,
                ),
                child: TextButton(
                  onPressed: (currentTank == null)
                      ? null
                      : () {
                          currentTank?.notes.loadNotes().then((_) {
                            notesDialog(context, tankModel, currentTank);
                          }).catchError((error) {});
                        },
                  child: Text("Notes…"), // this is the button text
                ),
              ),
              SizedBox(
                width: 565, //space for the note
                child: Text(currentTank?.notes?.returnCurrentNoteText() ??
                    "No current note"),
              ),
              ElevatedButton(
                  onPressed: (currentTank == null)
                      ? null
                      : () {
                          PrintTank(currentTank);
                        },
                  child: Text("Print")),
            ],
          ),
        ],
      ),
    );
  }
}
