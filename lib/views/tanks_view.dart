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
import '../view_models/tanklines_viewmodel.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

// for local, comment out
import 'package:flutter_zebra_sdk/flutter_zebra_sdk.dart';

class TankView extends StatefulWidget {
  final String? incomingRackFk;
  final int? incomingTankPosition;
  final TanksViewModel tankViewModelNoContext;
  final TanksLineViewModel tankLineViewModelNoContext;

  const TankView(
      {super.key,
      this.incomingRackFk,
      this.incomingTankPosition,
      required this.tankViewModelNoContext,
      required this.tankLineViewModelNoContext});

  @override
  TankViewState createState() => TankViewState();
}

class TankViewState extends State<TankView> {
  TextEditingController controllerForBirthDate = TextEditingController();
  TextEditingController controllerForScreenPositive = TextEditingController();

  TextEditingController controllerForNumberOfFish = TextEditingController();

  TextEditingController controllerForGeneration = TextEditingController();

  TextEditingController controllerForDocId = TextEditingController();

  ValueItem? selectedSingleItem;

  Tank? returnCurrentPhysicalTank() {
    return widget.tankViewModelNoContext.returnCurrentPhysicalTank();
  }

  void _updateDocId() {
    Tank? currentTank = returnCurrentPhysicalTank();

    if (controllerForDocId.text != currentTank?.documentId) {
      controllerForDocId.text = currentTank?.documentId ?? 'NO ID!';
    }
  }

  void addItem(ValueItem item) {}

  void updateSelectedItem(ValueItem? newSelectedItem) {
    selectedSingleItem = newSelectedItem;
    // here is where we save the newly selected tankline
    Tank? currentTank = returnCurrentPhysicalTank();
    currentTank?.tankLineDocId = selectedSingleItem?.value;
    widget.tankViewModelNoContext
        .saveExistingTank((currentTank?.absolutePosition)!)
        .then((value) {
      widget.tankViewModelNoContext.callNotifyListeners();
    });
  }

  void _updateNumberOfFishController() {
    Tank? currentTank = returnCurrentPhysicalTank();

    if (controllerForNumberOfFish.text !=
        currentTank?.numberOfFish.toString()) {
      controllerForNumberOfFish.text =
          currentTank?.numberOfFish.toString() ?? '1';
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

    // add listeners for the text-based widgets
    widget.tankViewModelNoContext.addListener(_updateNumberOfFishController);
    widget.tankViewModelNoContext.addListener(_updateFishGenerationController);
    widget.tankViewModelNoContext.addListener(_updateDocId);

    if (widget.incomingRackFk != null && widget.incomingTankPosition != null) {
      if (widget.incomingRackFk! != "0") {
        // parked cells don't have racks associated with them; rack is just 0 as a string.

        int? theRackAbsolutePosition =
            await facilityModel.returnRacksAbsolutePosition(widget
                .incomingRackFk!); // looks like we can just read this from the loaded racks

        await widget.tankViewModelNoContext.selectThisRackByAbsolutePosition(
            cFacilityClickableGrid,
            facilityModel,
            theRackAbsolutePosition!,
            cNoNotify);
      }
      // fixed bug, we do have to call notifylisteners after all
      widget.tankViewModelNoContext.selectThisTankCellConvertsVirtual(
          widget.incomingTankPosition!, cNotify);
    }
  }

  @override
  void initState() {
    super.initState();
    _prepareRacksAndTanksForCaller();
  }

  void _showErrorDialog(String errorMessage) {
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

  // BUGfixed we were missing the dispose call
  @override
  void dispose() {
    // BUGfixed needed to add removeListener
    widget.tankViewModelNoContext.removeListener(_updateNumberOfFishController);
    widget.tankViewModelNoContext
        .removeListener(_updateFishGenerationController);

    widget.tankViewModelNoContext.removeListener(_updateDocId);

    controllerForBirthDate.dispose();
    controllerForScreenPositive.dispose();
    controllerForNumberOfFish.dispose();
    controllerForGeneration.dispose();

    controllerForDocId.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  void notesDialog(
      BuildContext context, TanksViewModel tanksModel, Tank currentTank) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return NotesDialogBody(
            tanksModel: tanksModel, currentTank: currentTank);
      },
    );
  }

  Widget simpleSearchDropdown(BuildContext context, Tank currentTank) {
    TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    // we supply a unique key to this widget to force it to redraw each time a new tank is selected
    Key searchDropDownKey = UniqueKey();

    ValueItem selectedTank =
        tanksLineViewModel.returnTankLineFromDocId(currentTank.tankLineDocId);

    SimpleSearchbarSettings searchBarSettings = const SimpleSearchbarSettings(dropdownHeight: 34, dropdownWidth: 220,hintStyle: TextStyle(fontSize: 10), hint:"Select a tank line");
    SimpleOverlaySettings overlayListSettings = const SimpleOverlaySettings(dialogHeight:300,selectedItemTextStyle: TextStyle(fontSize: 10,color: Colors.black),unselectedItemTextStyle:TextStyle(fontSize: 9,color: Colors.black45));

    return SearchDropDown(
      key: searchDropDownKey,
      listItems: tanksLineViewModel.convertTankLinesToValueItems(),
      onAddItem: addItem,
      addMode: false,
      deleteMode: false,
      updateSelectedItem: updateSelectedItem,
      selectedItem: selectedTank, // this doesn’t get reapplied when we change the selected tank, so we give it a unique key to force rebuilding
      searchBarSettings: searchBarSettings,
      overlayListSettings: overlayListSettings,
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
/*
  Widget returnMultiSelectDropDown(
      BuildContext context,
      Tank? currentTank) {

    TanksLineViewModel tanksLineViewModel =
    Provider.of<TanksLineViewModel>(context, listen: false);

    List<ValueItem> v = tanksLineViewModel.returnTankLineFromDocId((currentTank?.tankLine)!);

    return MultiSelectDropDown(
      onOptionSelected: (options) async {
        print("options, ${options}");
        /*try {
          // business logic 2
          print("selected item is ${options[0].value}");
          currentTank?.tankLine = options[0].value;

          TanksViewModel tanksViewModel =
          Provider.of<TanksViewModel>(context, listen: false);

          await tanksViewModel.saveExistingTank((currentTank?.absolutePosition)!);
          //tanksViewModel.callNotifyListeners();
        } catch (e) {
          _showErrorDialog(e.toString());
        }*/
      },
      // i think we would need to have a function here returning the right item and
      // and the provider would update this item
      // but right now it is not selecting any item
      selectedOptions: v,
      options: tanksLineViewModel.convertTankLinesToValueItems(),
      selectionType: SelectionType.single,
      chipConfig: const ChipConfig(wrapType: WrapType.scroll),
      dropdownHeight: 400,
      optionTextStyle: const TextStyle(fontSize: 16),
      selectedOptionIcon: const Icon(Icons.check_circle),
      searchEnabled: true,
    );
  }
  */
  /*
    return TypeAheadField<String>(
      hideOnEmpty: true,
      hideOnLoading: true,
      autoFlipDirection: true,
      textFieldConfiguration: TextFieldConfiguration(
          controller: textController,
          onChanged: (value) async {
            try {
              // business logic 1
              // BUGfixed 11.19.2023
              currentTank?.tankLine = textController.text;
              await tanksModel.saveExistingTank((currentTank?.absolutePosition)!);

              tanksModel.callNotifyListeners();
            } catch (e) {
              _showErrorDialog(e.toString());
            }
          }),
      minCharsForSuggestions: 0,
      suggestionsCallback: (String pattern) async {
        if (pattern != "") {
          SearchViewModel searchModel =
              Provider.of<SearchViewModel>(context, listen: false);

          // BUGfixed, this is actually an async call
          // this may be the reason the Nemia was getting incomplete tankline names
          await searchModel.prepareFullTankList();

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
      onSuggestionSelected: (String suggestion) async {
        try {
          // business logic 2
          currentTank?.tankLine = suggestion;
          await tanksModel.saveExistingTank((currentTank?.absolutePosition)!);
          tanksModel.callNotifyListeners();
        } catch (e) {
          _showErrorDialog(e.toString());
        }
      },
    );
  }*/

  Widget buildInnerLabel(
      String labelText,
      TextEditingController? textController,
      TanksViewModel tanksModel,
      TankStringsEnum tanksStringsValue,
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
                ? simpleSearchDropdown(context, currentTank)
                : TextField(
                    enabled: (currentTank != null),
                    style: Theme.of(context).textTheme.bodyMedium,
                    keyboardType: returnTextInputType(tanksStringsValue),
                    controller: textController,
                    onChanged: (value) async {
                      try {
                        switch (tanksStringsValue) {
                          case TankStringsEnum.tankLine:
                            // nothing to do here because this is handled by returnAutoCompleteForTankLine above
                            break;

                          case TankStringsEnum.numberOfFish:
                            if (textController?.text != "") {
                              // business logic 4
                              currentTank?.numberOfFish =
                                  int.parse((textController?.text)!);
                            }
                            break;

                          case TankStringsEnum.generation:
                            if (textController?.text != "") {
                              // business logic 5
                              currentTank?.generation =
                                  int.parse((textController?.text)!);
                            }
                            break;
                          case TankStringsEnum.docId:
                            break;
                        }
                        await tanksModel
                            .saveExistingTank((currentTank?.absolutePosition)!);
                      } catch (e) {
                        _showErrorDialog(e.toString());
                      }
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
      try {
        setState(() {
          // business logic 6
          updateValue?.call(picked.millisecondsSinceEpoch);
        });
        await tankModel.saveExistingTank((currentTank?.absolutePosition)!);
        // BUGfixed, wasn’t updating state
        tankModel.callNotifyListeners();
      } catch (e) {
        _showErrorDialog(e.toString());
      }
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
            : (newValue) async {
                try {
                    updateValue?.call(newValue ?? false);
                  await tankModel
                      .saveExistingTank(currentTank.absolutePosition);
                  // BUGfixed wasn’t telling listeners, despite updating state (now removed).
                  tankModel.callNotifyListeners();
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
        controlAffinity:
            ListTileControlAffinity.leading, //  <-- leading Checkbox
      ),
    );
  }

  Widget buildParkedTank(BuildContext context) {
    // here we have listen on.
    TanksViewModel tankModel = Provider.of<TanksViewModel>(context);

    if (tankModel.isThereAParkedTank()) {
      Tank? tank = tankModel.returnParkedTankedInfo();

      FacilityViewModel facilityModel = Provider.of<FacilityViewModel>(context);

      double height = returnHeight(facilityModel);
      double width = returnWidth(facilityModel);

      if (tank?.getSmallTank() == false) {
        width = width * 2;
      }

      return ParkedTank(
        height: height,
        width: width,
        tankLine: tank?.tankLineDocId,
        dateOfBirth: tank?.getBirthDate(),
        screenPositive: tank?.getScreenPositive(),
        numberOfFish: tank?.getNumberOfFish(),
        fatTankPosition: tank?.fatTankPosition,
        generation: tank?.generation,
      );
    }
    return Container();
  }

  void printTank(BuildContext context, Tank? currentTank) async {
    //BUGfixed, now supplies actual tankline
    TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    ValueItem theTankLineValueItem = tanksLineViewModel
        .returnTankLineFromDocId((currentTank?.tankLineDocId)!);
    String tankLineString = theTankLineValueItem.value;

    String screenPositiveString = (currentTank?.getScreenPositive() ?? false)
        ? "screen positive"
        : "screen negative";

    String smallTankString = (currentTank?.getSmallTank() ?? false)
        ? "$cThinTank tank"
        : "$cFatTank tank";

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
    // last line embeds the given info into the barcode, BUG this line was part of the ZPL text
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
    TanksViewModel tankModel = Provider.of<TanksViewModel>(context);

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
          Row(
            children: [
              buildOuterLabel(context, "Tank Info"),
              TextButton(
                onPressed: (currentTank == null)
                    ? null
                    : () {
                        tankModel.copyTank();
                      },
                child: const Text("Copy Tank Template"),
              ),
              TextButton(
                // BUGfixed, was testing the wrong boolean
                onPressed: (!tankModel.isTemplateInPlay)
                    ? null
                    : () {
                        tankModel.clearTankTemplate();
                      },
                child: const Text("Clear Tank Template"),
              ),
            ],
          ),
          Row(
            children: [
              buildInnerLabel(
                  "Tank Line", null, tankModel, TankStringsEnum.tankLine, 300),
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
              buildInnerLabel("doc id", controllerForDocId, tankModel,
                  TankStringsEnum.docId, 200),
            ],
          ),
          Row(
            children: [
              ((currentTank?.absolutePosition == cParkedRackAbsPosition) ||
                      (currentTank == null) ||
                      tankModel.isThereAParkedTank())
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // remove any padding
                        ),
                        onPressed: () {
                          // setStateRedundant?
                          setState(() {
                            // business logic 9
                            currentTank.parkIt();
                            tankModel
                                .saveExistingTank(cParkedRackAbsPosition)
                                .then((value) {
                              widget.tankViewModelNoContext
                                  .selectThisTankCellConvertsVirtual(
                                      cParkedRackAbsPosition, cNotify);
                            });
                            // BUGfixed was not selecting this parked tank
                            // BUGfixed we are not awaiting saveExistingTank to complete, but why does it matter? We are not re-reading the database
                            // do we need this function to call notifylisteners if we are already calling setstate?
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
                          printTank(context, currentTank);
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
                padding: const EdgeInsets.only(left: 40),
                child: ElevatedButton(
                    onPressed: (currentTank == null)
                        ? null
                        : () async {
                            bool confirmed =
                                await confirmActionSpecifiedInMessage(
                                    context, 'Delete the selected tank?');
                            if (confirmed) {

                              ValueItem tankLineValueItem = widget.tankLineViewModelNoContext.returnTankLineFromDocId(currentTank.tankLineDocId);

                              tankModel
                                  .euthanizeTank(tankLineValueItem.label, currentTank.absolutePosition);
                              // BUGfixed is not selecting an empty tank
                              widget.tankViewModelNoContext
                                  .selectThisTankCellConvertsVirtual(
                                      kEmptyTankIndex, cNotify);

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
