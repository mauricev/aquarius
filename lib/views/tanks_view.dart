import '../view_models/search_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/facilities_viewmodel.dart';
import '../view_models/tanks_viewmodel.dart';
import 'utility.dart';
import 'facility_grid.dart';
import '../views/consts.dart';
import '../views/tanks_view_parkedtank.dart';
import '../views/tanks_view_rackgrid.dart';
import '../views/tanks_view_notes.dart';
import '../models/tank_model.dart';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

// for local, comment out
import 'package:flutter_zebra_sdk/flutter_zebra_sdk.dart';

import 'package:flutter_typeahead/flutter_typeahead.dart';

class TankView extends StatefulWidget {
  final String? incomingRackFk;
  final int? incomingTankPosition;
  final TanksViewModel tankViewModelNoContext;

  const TankView({
    Key? key,
    this.incomingRackFk,
    this.incomingTankPosition,
    required this.tankViewModelNoContext,
  }) : super(key: key);

  @override
  TankViewState createState() =>
      TankViewState();
}

class TankViewState extends State<TankView> {

  TextEditingController controllerForTankLine = TextEditingController();
  TextEditingController controllerForBirthDate = TextEditingController();
  TextEditingController controllerForScreenPositive = TextEditingController();

  TextEditingController controllerForNumberOfFish = TextEditingController();

  TextEditingController controllerForGeneration = TextEditingController();

  Tank? returnCurrentPhysicalTank() {
    /*TanksViewModel tankModel =
    Provider.of<TanksViewModel>(context, listen: false);*/

    return widget.tankViewModelNoContext.returnCurrentPhysicalTank();
  }

  void _updateTankLineController() {
    Tank? currentTank = returnCurrentPhysicalTank();

    if (controllerForTankLine.text != currentTank?.tankLine) {
      controllerForTankLine.text = currentTank?.tankLine ?? '';
    }
  }

  void _updateNumberOfFishController() {
    Tank? currentTank = returnCurrentPhysicalTank();

    if (controllerForNumberOfFish.text != currentTank?.numberOfFish.toString()) {
      controllerForNumberOfFish.text = currentTank?.numberOfFish.toString() ?? '1';
    }
  }

  void _updateFishGenerationController() {
    Tank? currentTank = returnCurrentPhysicalTank();

    if (controllerForGeneration.text != currentTank?.generation.toString()) {
      controllerForGeneration.text = currentTank?.generation.toString() ?? '';
    }
  }

  // we should work on trying to avoid async in this function
  // if we can do that, then the question is whether buildcontext will disconnect still
  // returnRacksAbsolutePosition
  // selectThisRackByAbsolutePosition

  void _prepareRacksAndTanksForCaller() async {
    /*TanksViewModel tankModel =
        Provider.of<TanksViewModel>(context, listen: false);*/

    FacilityViewModel facilityModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    widget.tankViewModelNoContext.addListener(_updateTankLineController);
    widget.tankViewModelNoContext.addListener(_updateNumberOfFishController);
    widget.tankViewModelNoContext.addListener(_updateFishGenerationController);

    if (widget.incomingRackFk != null && widget.incomingTankPosition != null) {
      if (widget.incomingRackFk! != "0") {
        // parked cells don't have racks associated with them; rack is just 0 as a string.

        int? theRackAbsolutePosition =
            await facilityModel.returnRacksAbsolutePosition(widget.incomingRackFk!); // looks like we can just read this from the loaded racks

        await widget.tankViewModelNoContext.selectThisRackByAbsolutePosition(
            cFacilityClickableGrid, facilityModel, theRackAbsolutePosition!, cNoNotify);
      }
      // fixed bug, we do have to call notifylisteners after all
      widget.tankViewModelNoContext.selectThisTankCellConvertsVirtual(widget.incomingTankPosition!,cNotify);
    }
  }

  @override
  void initState() {
    super.initState();

/*    incomingRackFk = widget.arguments['incomingRack_Fk'];
    incomingTankPosition = widget.arguments['incomingTankPosition'];
    tankViewModelNoListen = widget.arguments['incomingTankViewModel'];
    facilityViewModelNoListen = widget.arguments['incomingFacilityViewModel'];*/

    _prepareRacksAndTanksForCaller();
  }

  // BUG we were missing the dispose call
  @override
  void dispose() {
    controllerForTankLine.dispose();
    controllerForBirthDate.dispose();
    controllerForScreenPositive.dispose();
    controllerForNumberOfFish.dispose();
    controllerForGeneration.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  void notesDialog(BuildContext context, TanksViewModel tanksModel,
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

  Widget returnAutoCompleteForTankLine(
      BuildContext context,
      TanksViewModel tanksModel,
      TextEditingController textController,
      Tank? currentTank) {
    return TypeAheadField<String>(
      hideOnEmpty: true,
      hideOnLoading: true,
      autoFlipDirection: true,

      textFieldConfiguration: TextFieldConfiguration(
          controller: textController,
          onChanged: (value) {
            // business logic 1
            currentTank?.tankLine = textController.text;

            tanksModel.saveExistingTank((currentTank?.absolutePosition)!).then((value) {
              tanksModel.callNotifyListeners();
            });
          }),
      minCharsForSuggestions: 0,
      suggestionsCallback: (String pattern) async {
        if (pattern != "") {
          FacilityViewModel facilityModel =
              Provider.of<FacilityViewModel>(context,
                  listen: false);

          SearchViewModel searchModel =
              Provider.of<SearchViewModel>(context, listen: false);

          searchModel
              .prepareFullTankListForFacility(facilityModel.returnFacilityId());

          return searchModel
              .returnListOfTankLines(pattern)
              .where((item) =>
                  item.toLowerCase().startsWith(pattern.toLowerCase()))
              .toList();
        } else {
          return [];
        }
      },
      itemBuilder: (context, String suggestion) {
        return ListTile(
          title: Text(suggestion),
        );
      },
      onSuggestionSelected: (String suggestion) {
        //setState(() {
          // business logic 2
          currentTank?.tankLine = suggestion;

          tanksModel.saveExistingTank((currentTank?.absolutePosition)!);
          // set state is no longer working here because we are using a listener for changes to the tankline
          tanksModel.callNotifyListeners();
       // });
      },
    );
  }

  Widget buildInnerLabel(String labelText, TextEditingController textController,
      TanksViewModel tanksModel, TankStringsEnum tanksStringsValue,
      [double? width]) {

    // business logic 3
    Tank? currentTank = tanksModel.returnCurrentPhysicalTank();

    return Padding(
      padding: const EdgeInsets.only(
        left: 40,
      ),
      child: Row(
        children: [
          Text(
            labelText,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 20,
            ),
            width: (width == null) ? kStandardTextWidthDouble : width,
            child: (tanksStringsValue == TankStringsEnum.tankLine) &&
                    (currentTank != null)
                ? returnAutoCompleteForTankLine(
                    context, tanksModel, textController, currentTank)
                : TextField(
                    enabled: (currentTank != null),
                    style: Theme.of(context).textTheme.bodyMedium,
                    keyboardType: returnTextInputType(tanksStringsValue),
                    controller: textController,
                    onChanged: (value) {
                      switch (tanksStringsValue) {
                        case TankStringsEnum.tankLine:
                          // nothing to do here because this is handled by returnAutoCompleteForTankLine above
                          break;
                        case TankStringsEnum.numberOfFish:
                          if (textController.text != "") {
                            // business logic 4
                            currentTank?.numberOfFish =
                                int.parse(textController.text);
                          }
                          break;
                        case TankStringsEnum.generation:
                          if (textController.text != "") {
                            // business logic 5
                            currentTank?.generation =
                                int.parse(textController.text);
                          }
                          break;
                      }
                      tanksModel.saveExistingTank((currentTank?.absolutePosition)!);
                    }),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context,
      TanksViewModel tankModel,
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
        // business logic 6
        updateValue?.call(picked.millisecondsSinceEpoch);

        tankModel.saveExistingTank((currentTank?.absolutePosition)!);
      });
    }
  }

  Widget drawDateOfBirth(
      TanksViewModel tankModel,
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
          onPressed: (currentTank == null)
              ? null
              : () => _selectDate(
                  context, tankModel, currentTank, retrieveValue, updateValue),
          child: Text(buildDateOfBirth(retrieveValue)),
        ),
      ],
    );
  }

  Widget buildCheckBox(
      TanksViewModel tankModel,
      Tank? currentTank,
      String labelText,
      bool? Function()? retrieveValue,
      void Function(bool newValue)? updateValue) {

    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        title: Text(
          labelText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: retrieveValue?.call() ?? false,
        onChanged: (currentTank == null)
            ? null
            : (newValue) {
                setState(() {
                  // business logic 7
                  updateValue?.call(newValue ?? false);
                  tankModel.saveExistingTank((currentTank.absolutePosition));
                });
              },
        controlAffinity:
            ListTileControlAffinity.leading, //  <-- leading Checkbox
      ),
    );
  }

  Widget buildParkedTank(BuildContext context) {
    // here we have listen on.
    TanksViewModel tankModel =
        Provider.of<TanksViewModel>(context);

    if (tankModel.isThereAParkedTank()) {
      Tank? tank = tankModel.returnParkedTankedInfo();

      FacilityViewModel facilityModel =
          Provider.of<FacilityViewModel>(context);

      double height = returnHeight(facilityModel);
      double width = returnWidth(facilityModel);

      if (tank?.getSmallTank() == false) {
        width = width * 2;
      }

      return ParkedTank(
        height: height,
        width: width,
        tankLine: tank?.tankLine,
        dateOfBirth: tank?.getBirthDate(),
        screenPositive: tank?.getScreenPositive(),
        numberOfFish: tank?.getNumberOfFish(),
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

    String smallTankString =
        (currentTank?.getSmallTank() ?? false) ? "$cThinTank tank" : "$cFatTank tank";

    String numberOfFishString = currentTank?.getNumberOfFish().toString() ?? "";
    String generationString = currentTank?.generation.toString() ?? "";
    String dateOfBirthString = buildDateOfBirth(currentTank?.getBirthDate);
    String rackFkString = currentTank?.rackFk ?? "";
    String absolutePositionString =
        currentTank?.absolutePosition.toString() ?? "";

    FacilityViewModel facilityModel =
        Provider.of<FacilityViewModel>(context, listen: false);
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
    // listen is on
    TanksViewModel tankModel =
        Provider.of<TanksViewModel>(context);

    // we want a real physical tank here
    // business logic 8
    Tank? currentTank = tankModel.returnCurrentPhysicalTank();

    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: ListView(
        // needed for scrolling the keyboard
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
                  : Padding(
                    padding: const EdgeInsets.only(left:40),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // remove any padding
                        ),
                        onPressed: () {
                          setState(() {
                            // business logic 9
                            currentTank.parkIt();
                            tankModel.saveExistingTank(cParkedRackAbsPosition);
                            // BUG was not selecting this parked tank
                            widget.tankViewModelNoContext.selectThisTankCellConvertsVirtual(cParkedRackAbsPosition,cNotify);
                          });
                        },
                        child: const Text("Park it"),
                      ),
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
                width: 390, //space for the note
                child: Text(currentTank?.notes.returnCurrentNoteText() ??
                    "No current note"),
              ),
              ElevatedButton(
                  onPressed: (currentTank == null) ||
                          (defaultTargetPlatform != TargetPlatform.iOS)
                      ? null
                      : () {
                          printTank(currentTank);
                        },
                  child: const Text("Print")),
            ],
          ),
          const SizedBox(
            height: 30, // separate delete button
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(
              left: 40),
                child: ElevatedButton(
                    onPressed: (currentTank == null)
                        ? null
                        : () async {
                      bool confirmed =
                      await confirmActionSpecifiedInMessage(
                          context, 'Delete the selected tank?');
                      if (confirmed) {
                        tankModel
                            .euthanizeTank(currentTank.absolutePosition);
                        // BUG is not selecting an empty tank
                        widget.tankViewModelNoContext.selectThisTankCellConvertsVirtual(kEmptyTankIndex,cNotify);
                      }
                    },
                    child: const Text("Delete Tank")),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
