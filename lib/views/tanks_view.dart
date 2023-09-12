import 'package:aquarium_manager/view_models/search_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/facilities_viewmodel.dart';
import '../view_models/tanks_viewmodel.dart';
import 'utility.dart';
import 'facility_grid.dart';
import 'package:aquarium_manager/views/consts.dart';
import 'package:aquarium_manager/views/tanks_view_parkedtank.dart';
import 'package:aquarium_manager/views/tanks_view_rackgrid.dart';
import 'package:aquarium_manager/views/tanks_view_notes.dart';
import 'package:aquarium_manager/models/tank_model.dart';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

import 'package:flutter_zebra_sdk/flutter_zebra_sdk.dart';

//import 'package:easy_autocomplete/easy_autocomplete.dart';
//import 'package:elastic_autocomplete/elastic_autocomplete.dart';
//import 'package:simple_autocomplete_formfield/simple_autocomplete_formfield.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class TankView extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const TankView({Key? key, required this.arguments})
      : super(key: key);

  @override
  TankViewState createState() =>
      TankViewState();
}

class TankViewState extends State<TankView> {
  String? incomingRackFk;
  int? incomingTankPosition;

  TextEditingController controllerForTankLine = TextEditingController();
  TextEditingController controllerForBirthDate = TextEditingController();
  TextEditingController controllerForScreenPositive = TextEditingController();

  TextEditingController controllerForNumberOfFish = TextEditingController();

  TextEditingController controllerForGeneration = TextEditingController();

  void _prepareRacksAndTanksForCaller() async {
    TanksViewModel tankModel =
        Provider.of<TanksViewModel>(context, listen: false);

    FacilityViewModel facilityModel =
        Provider.of<FacilityViewModel>(context, listen: false);

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

//   Widget returnAutoCompleteForTankLine(BuildContext context, MyAquariumManagerTanksModel tanksModel, TextEditingController textController, Tank? currentTank) {
//     myPrint("in returnAutoCompleteForTankLine");
//     return Autocomplete<String>(
//       //initialValue: TextEditingValue(text: initialText),
//       optionsBuilder: (TextEditingValue textEditingValue) {
//         myPrint("in optionsbuilder");
//         if (textEditingValue.text == '') {
//           myPrint("in optionsbuilder, emptyee");
//           return const Iterable<String>.empty();
//         }
//         myPrint("do we have tanklines, ${tanksModel.returnListOfTankLines()}");
//         return tanksModel.returnListOfTankLines().where((String option) {
//           return option.contains(textEditingValue.text.toLowerCase());
//         });
//       },
//         fieldViewBuilder: (BuildContext context, TextEditingController textEditingController,
//             FocusNode focusNode,
//             VoidCallback onFieldSubmitted) {
//           myPrint("in fieldViewBuilder");
//           return TextField(
//             controller: textController,
//             focusNode: focusNode,
//             onChanged: (String value) {
// myPrint("do we come here?");
//             },
//           );
//         }
//     );
//   }

  Widget returnAutoCompleteForTankLine(
      BuildContext context,
      TanksViewModel tanksModel,
      TextEditingController textController,
      Tank? currentTank) {
    return TypeAheadField<String>(
      //getImmediateSuggestions:false,
      hideOnEmpty: true,
      hideOnLoading: true,
      autoFlipDirection: true,

      textFieldConfiguration: TextFieldConfiguration(
          controller: textController,
          // style: DefaultTextStyle.of(context)
          //     .style
          //     .copyWith(fontStyle: FontStyle.italic),
          // decoration: InputDecoration(
          //     border: OutlineInputBorder(),
          //     ),
          onChanged: (value) {
            FacilityViewModel facilityModel =
                Provider.of<FacilityViewModel>(context,
                    listen: false);

            currentTank?.tankLine = textController.text;

            tanksModel.saveExistingTank(facilityModel.returnFacilityId(),
                (currentTank?.absolutePosition)!);
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
      // itemSeparatorBuilder: (context, index) {
      //   return Divider();
      // },
      onSuggestionSelected: (String suggestion) {
        setState(() {
          FacilityViewModel facilityModel =
              Provider.of<FacilityViewModel>(context,
                  listen: false);

          currentTank?.tankLine = suggestion;

          tanksModel.saveExistingTank(facilityModel.returnFacilityId(),
              (currentTank?.absolutePosition)!);
        });
      },
      // suggestionsBoxDecoration: SuggestionsBoxDecoration(
      //   borderRadius: BorderRadius.circular(10.0),
      //   elevation: 8.0,
      //   color: Theme.of(context).cardColor,
      //),
    );
  }

  Widget buildInnerLabel(String labelText, TextEditingController textController,
      TanksViewModel tanksModel, TankStringsEnum tanksStringsValue,
      [double? width]) {
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
        textController.text = currentTank?.getNumberOfFish().toString() ?? "";
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
                      FacilityViewModel facilityModel =
                          Provider.of<FacilityViewModel>(context,
                              listen: false);

                      switch (tanksStringsValue) {
                        case TankStringsEnum.tankLine:

                          currentTank?.tankLine = textController.text;
                          break;
                        case TankStringsEnum.numberOfFish:
                          if (textController.text != "") {
                            currentTank?.numberOfFish =
                                int.parse(textController.text);
                          }
                          break;
                        case TankStringsEnum.generation:
                          if (textController.text != "") {
                            currentTank?.generation =
                                int.parse(textController.text);
                          }
                          break;
                      }

                      tanksModel.saveExistingTank(
                          facilityModel.returnFacilityId(),
                          (currentTank?.absolutePosition)!);
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
        updateValue?.call(picked.millisecondsSinceEpoch);

        FacilityViewModel facilityModel =
            Provider.of<FacilityViewModel>(context, listen: false);

        tankModel.saveExistingTank(
            facilityModel.returnFacilityId(), (currentTank?.absolutePosition)!);
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
    FacilityViewModel facilityModel =
        Provider.of<FacilityViewModel>(context, listen: false);

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
                  updateValue?.call(newValue ?? false);
                  tankModel.saveExistingTank(facilityModel.returnFacilityId(),
                      (currentTank.absolutePosition));
                });
              },
        controlAffinity:
            ListTileControlAffinity.leading, //  <-- leading Checkbox
      ),
    );
  }

  Widget buildParkedTank(BuildContext context) {
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
        (currentTank?.getSmallTank() ?? false) ? "small tank" : "fat tank";

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
    TanksViewModel tankModel =
        Provider.of<TanksViewModel>(context);

    // we want a real physical tank here
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
                            currentTank.parkIt();
                            FacilityViewModel facilityModel =
                                Provider.of<FacilityViewModel>(
                                    context,
                                    listen: false);
                            tankModel.saveExistingTank(
                                facilityModel.returnFacilityId(),
                                cParkedRackAbsPosition);
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
