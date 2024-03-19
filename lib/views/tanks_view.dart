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
//import 'package:flutter_zebra_sdk/flutter_zebra_sdk.dart';

class TankView extends StatefulWidget {
  final String? incomingRackFk;
  final int? incomingTankPosition;
  final TanksViewModel tankViewModelNoContext;
  final TanksLineViewModel tankLineViewModelNoContext;
  final FacilityViewModel facilityViewModelNoContext;

  const TankView(
      {super.key,
      this.incomingRackFk,
      this.incomingTankPosition,
      required this.tankViewModelNoContext,
      required this.tankLineViewModelNoContext,
      required this.facilityViewModelNoContext});

  @override
  TankViewState createState() => TankViewState();
}

class TankViewState extends State<TankView> {
  TextEditingController controllerForBirthDate = TextEditingController();
  TextEditingController controllerForScreenPositive = TextEditingController();
  TextEditingController controllerForNumberOfFish = TextEditingController();
  TextEditingController controllerForGeneration = TextEditingController();

  Tank? returnCurrentPhysicalTank() {
    return widget.tankViewModelNoContext.returnCurrentPhysicalTank();
  }

  // placeholder for adding to dropdowns
  void addItem(ValueItem item) {}

  void updateSelectedTankLine(ValueItem? newSelectedTankLine) {
    ValueItem replacementSelectedTankLine = const ValueItem(value: cTankLineValueNotYetAssigned,label: cTankLineLabelNotYetAssigned);
    if (newSelectedTankLine != null) {
      replacementSelectedTankLine = newSelectedTankLine;
    }

    // here is where we save the newly selected tankline
    Tank? currentTank = returnCurrentPhysicalTank();
    currentTank?.tankLineDocId = replacementSelectedTankLine?.value;
    widget.tankViewModelNoContext
        .saveExistingTank((currentTank?.absolutePosition)!)
        .then((value) {
      widget.tankViewModelNoContext.callNotifyListeners();
    });
  }

  void updateSelectedGenoType(ValueItem? newSelectedGenoType) {
    Tank? currentTank = returnCurrentPhysicalTank();
    currentTank?.genoType = newSelectedGenoType?.value;
    widget.tankViewModelNoContext
        .saveExistingTank((currentTank?.absolutePosition)!)
        .then((value) {
      widget.tankViewModelNoContext.callNotifyListeners();
    });
  }

  void updateSelectedParents(List<ValueItem> newlySelectedParents) {

    // there can only be 2 parents
    if (newlySelectedParents.length > 2) {
      print("we are removing");
      newlySelectedParents.removeAt(2);
    }

    print("updateSelectedParents");
    Tank? currentTank = returnCurrentPhysicalTank();
    if (newlySelectedParents.isEmpty) {
      print("updateSelectedParents is empty");
      currentTank?.parent1 = null;
      currentTank?.parent2 = null;
    }
    if (newlySelectedParents.length == 1) {
      print("updateSelectedParents is 1, ${newlySelectedParents[0].label}");
      currentTank?.parent1 = newlySelectedParents[0].label;
      currentTank?.parent2 = null;
    }
    if (newlySelectedParents.length == 2) {
      print("updateSelectedParents is 2, ${newlySelectedParents[0].label} and ${newlySelectedParents[1].label}");
      currentTank?.parent1 = newlySelectedParents[0].label;
      currentTank?.parent2 = newlySelectedParents[1].label;
    }
    widget.tankViewModelNoContext
        .saveExistingTank((currentTank?.absolutePosition)!)
        .then((value) {
      //widget.tankViewModelNoContext.callNotifyListeners();
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
    FacilityViewModel facilityModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    // add listeners for the text-based widgets
    widget.tankViewModelNoContext.addListener(_updateNumberOfFishController);
    widget.tankViewModelNoContext.addListener(_updateFishGenerationController);

    if (widget.incomingRackFk != null && widget.incomingTankPosition != null) {
      // parked cells don't have racks associated with them; parked rack is just 0 as a string.
      if (widget.incomingRackFk! != "0") {
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
    } else {
      await widget.tankViewModelNoContext.selectThisRackByAbsolutePosition(
          cFacilityClickableGrid, facilityModel, kNoRackSelected, cNoNotify);
      widget.tankViewModelNoContext
          .selectThisTankCellConvertsVirtual(kEmptyTankIndex, cNotify);
    }
    // what happens when rack and tank are, in fact, null?
    // for tank, we
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

  Widget chooseTankLineDropDown(BuildContext context, Tank currentTank) {
    TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    // we supply a unique key to this widget to force it to redraw each time a new tank is selected
    Key tankLineDropDownKey = UniqueKey();

    ValueItem selectedTank =
        tanksLineViewModel.returnTankLineFromDocId(currentTank.tankLineDocId);

    SimpleSearchbarSettings searchBarSettings = const SimpleSearchbarSettings(
        dropdownHeight: 34,
        dropdownWidth: 220,
        hintStyle: TextStyle(fontSize: 10),
        hint: "Select a tank line");
    SimpleOverlaySettings overlayListSettings = const SimpleOverlaySettings(
      dialogHeight: 400,
      selectedItemTextStyle: TextStyle(fontSize: 10, color: Colors.black),
      unselectedItemTextStyle: TextStyle(fontSize: 9, color: Colors.black45),
      // offsetHeight:-250 forces the dropdown to appear at a reasonable location
      // that is, not partially off-screen
      offsetHeight: -250,
    );

    return SearchDropDown(
      key: tankLineDropDownKey,
      listItems: tanksLineViewModel.convertTankLinesToValueItems(),
      onAddItem: addItem,
      addMode: false,
      deleteMode: false,
      updateSelectedItem: updateSelectedTankLine,
      // this will be a list of at most two items
      selectedItem:
          selectedTank, // this doesn’t get reapplied when we change the selected tank, so we give it a unique key to force rebuilding
      searchBarSettings: searchBarSettings,
      overlayListSettings: overlayListSettings,
    );
  }

  Widget chooseGenoType(BuildContext context, Tank currentTank) {
    // we supply a unique key to this widget to force it to redraw each time a new tank is selected
    Key genoTypeDropDownKey = UniqueKey();

    TanksViewModel tanksViewModel =
        Provider.of<TanksViewModel>(context, listen: false);

    ValueItem? selectedGenoType =
        tanksViewModel.convertGenoTypeToValueItem(currentTank.getGenoType());

    SimpleSearchbarSettings searchBarSettings = const SimpleSearchbarSettings(
        dropdownHeight: 30,
        dropdownWidth: 100,
        hintStyle: TextStyle(fontSize: 10),
        hint: "Select a genotype");
    SimpleOverlaySettings overlayListSettings = const SimpleOverlaySettings(
        dialogHeight: 200,
        selectedItemTextStyle: TextStyle(fontSize: 10, color: Colors.black),
        unselectedItemTextStyle: TextStyle(fontSize: 9, color: Colors.black45),
        offsetHeight: -40);

    return SearchDropDown(
      key: genoTypeDropDownKey,
      listItems: tanksViewModel.returnGenoTypes(),
      onAddItem: addItem,
      addMode: false,
      deleteMode: false,
      updateSelectedItem: updateSelectedGenoType,
      selectedItem:
          selectedGenoType, // this doesn’t get reapplied when we change the selected tank, so we give it a unique key to force rebuilding
      searchBarSettings: searchBarSettings,
      overlayListSettings: overlayListSettings,
    );
  }

  Widget chooseParents(BuildContext context, Tank currentTank) {
    // we supply a unique key to this widget to force it to redraw each time a new tank is selected
    Key parentsDropDownKey = UniqueKey();

    TanksLineViewModel tanksLineViewModel =
    Provider.of<TanksLineViewModel>(context, listen: false);

    ValueItem theTankToExclude =
    tanksLineViewModel.returnTankLineFromDocId(currentTank.tankLineDocId);

    List<ValueItem> theTankLines = tanksLineViewModel.convertTankLinesToValueItems();

    // we exclude the current tankline; it doesn’t make sense to be a parent of itself
    theTankLines.remove(theTankToExclude);

    List<ValueItem>  selectedParents = tanksLineViewModel.returnTankLinesFromTank(currentTank);

    SimpleSearchbarSettings searchBarSettings = const SimpleSearchbarSettings(
        dropdownHeight: 34,
        dropdownWidth: 220,
        boxMultiSelectedClearIconSize: 15,
        searchBarTextStyle: TextStyle(fontSize: 10),
        hintStyle: TextStyle(fontSize: 10),
        boxMultiSelectedTextStyle:TextStyle(fontSize: 10),
        hint: "Select parents");

    SimpleOverlaySettings overlayListSettings = const SimpleOverlaySettings(
        dialogHeight: 400,
        selectedItemTextStyle: TextStyle(fontSize: 10, color: Colors.black),
        unselectedItemTextStyle: TextStyle(fontSize: 9, color: Colors.black45),
        offsetHeight: -250);

    return MultipleSearchDropDown(
      key: parentsDropDownKey,
      listItems: theTankLines,
      onAddItem: addItem,
      addMode: false,
      deleteMode: false,
      updateSelectedItems: updateSelectedParents,
      selectedItems:
      selectedParents, // this doesn’t get reapplied when we change the selected tank, so we give it a unique key to force rebuilding
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

  Widget buildInnerLabel(
      double leftIndent,
      String labelText,
      TextEditingController? textController,
      TanksViewModel tanksModel,
      TankStringsEnum tanksStringsValue,
      [double? width]) {
    // business logic 3
    Tank? currentTank = tanksModel.returnCurrentPhysicalTank();

    return Padding(
      padding: EdgeInsets.only(
        left: leftIndent,
      ),
      child: Row(
        children: [
          Text(
            labelText,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 10,
            ),
            width: (width == null) ? kStandardTextWidthDouble : width,
            child: (tanksStringsValue == TankStringsEnum.tankLine) &&
                    (currentTank != null)
                ? chooseTankLineDropDown(context, currentTank)
                : (tanksStringsValue == TankStringsEnum.genotype) &&
                        (currentTank != null)
                    ? chooseGenoType(context, currentTank) : (tanksStringsValue == TankStringsEnum.parents) &&
                (currentTank != null)
                ? chooseParents(context, currentTank)
                    : TextField(
                        enabled: (currentTank != null),
                        style: Theme.of(context).textTheme.bodyMedium,
                        keyboardType: returnTextInputType(tanksStringsValue),
                        controller: textController,
                        onChanged: (value) async {
                          try {
                            switch (tanksStringsValue) {
                              case TankStringsEnum.tankLine:
                                // nothing to do here because this is handled by simpleSearchDropdown above
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
                              case TankStringsEnum.genotype:
                                // we handle this above
                                break;
                              case TankStringsEnum.parents:
                              // we handle this above
                                break;
                            }
                            await tanksModel.saveExistingTank(
                                (currentTank?.absolutePosition)!);
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
        //BUGfixed, was DateTime(kEndingYear)
        lastDate: DateTime.now());
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
      BuildContext context,
      TanksViewModel tankModel,
      Tank? currentTank,
      int? Function()? retrieveValue,
      void Function(int newValue)? updateValue) {
    return Row(
      children: [
         Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            "DOB:",
              style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
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
      width: 120,
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
    //BUGFixed was using value and not label. 2023_12_27
    String tankLineString = theTankLineValueItem.label;

    String screenPositiveString = (currentTank?.getScreenPositive() ?? false)
        ? "screen positive"
        : "screen negative";

    String smallTankString = (currentTank?.getSmallTank() ?? false)
        ? "$cThinTank tank"
        : "$cFatTank tank";

    String numberOfFishString = currentTank?.getNumberOfFish().toString() ?? "";
    String generationString = currentTank?.generation.toString() ?? "";
    String dateOfBirthString = buildDateOfBirth(currentTank?.getBirthDate);

    // BUGfixed 2024-03-05
    // we now store the tank’s document id and no longer its rack and abs position
    // this way the barcode works for the tank regardless of where it's located
    String tankDocumentId = (currentTank?.documentId)!;

    // multiline string requires three quotes
    // last line embeds the given info into the barcode, BUG this line was part of the ZPL text
    // BUGFixed, location information which may change if the tank is moved has been removed from
    // the qr code (now it’s the tank id) and from the text display

    String zplCode = """
^XA
^FO275,30^A0N,25^FD$tankLineString^FS
^FO275,65^A0N,30^FDDOB:$dateOfBirthString^FS
^FO275,100^A0N,30^FDCount:$numberOfFishString^FS
^FO275,135^A0N,30^FD$smallTankString^FS
^FO275,170^A0N,30^FD$screenPositiveString^FS
^FO275,205^A0N,30^FDGen:F$generationString^FS
^FO20,20^BQN,2,8^FH^FDMA:$tankDocumentId^FS 
^XZ
""";
    //ZebraSdk.printZPLOverTCPIP('10.49.98.105', data: zplCode);
  }

  Future<Map<String, dynamic>> deleteTankDialog(BuildContext context) async {
    String tankLineDeleteOption = "";

    Map<String, dynamic>? dialogResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Euthanize/Delete Tank'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile<String>(
                    title: const Text('Euthanize Tank'),
                    value: cEuthanizeTank,
                    groupValue: tankLineDeleteOption,
                    onChanged: (value) {
                      setState(() {
                        tankLineDeleteOption = value ?? cEuthanizeTank;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Delete Tank'),
                    value: cDeleteTank,
                    groupValue: tankLineDeleteOption,
                    onChanged: (value) {
                      setState(() {
                        tankLineDeleteOption = value ?? cDeleteTank;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop({'confirm': false});
                  },
                ),
                TextButton(
                  onPressed: (tankLineDeleteOption != cEuthanizeTank) &&
                          (tankLineDeleteOption != cDeleteTank)
                      ? null
                      : () {
                          Navigator.of(context).pop({
                            'confirm': true,
                            'tankLineDeleteOption': tankLineDeleteOption
                          });
                        },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
    return dialogResult ??
        {'confirm': false, 'tankLineDeleteOption': tankLineDeleteOption};
  }

  void deleteEuthanizeTank(BuildContext context, Tank currentTank) async {
    Map<String, dynamic> deleteTankResult = await deleteTankDialog(context);
    if (deleteTankResult['confirm'] == true) {
      ValueItem tankLineValueItem = widget.tankLineViewModelNoContext
          .returnTankLineFromDocId(currentTank.tankLineDocId);

      ValueItem? genoTypeValueItem = widget.tankViewModelNoContext
          .convertGenoTypeToValueItem(currentTank.genoType);
      String genoTypeLabel = genoTypeValueItem?.label ?? "";

      widget.facilityViewModelNoContext
          .convertFacilityFkToFacilityName(currentTank.facilityFk!)
          .then((facilityName) {
        widget.tankViewModelNoContext.deleteEuthanizeTank(
            tankLineValueItem.label,
            genoTypeValueItem?.label,
            currentTank.parent1,
            currentTank.parent2,
            facilityName!,
            currentTank.absolutePosition,
            deleteTankResult['tankLineDeleteOption']);
        // BUGfixed is not selecting an empty tank
        widget.tankViewModelNoContext
            .selectThisTankCellConvertsVirtual(kEmptyTankIndex, cNotify);
      });
    }
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
              buildInnerLabel(stdLeftIndent, "Tankline", null, tankModel,
                  TankStringsEnum.tankLine, 260),
              drawDateOfBirth(context,tankModel, currentTank, currentTank?.getBirthDate,
                  currentTank?.setBirthDate),
              buildCheckBox(
                  tankModel,
                  currentTank,
                  "Screen +",
                  currentTank?.getScreenPositive,
                  currentTank?.setScreenPositive),
              buildInnerLabel(0, "Fish #", controllerForNumberOfFish, tankModel,
                  TankStringsEnum.numberOfFish),
            ],
          ),
          Row(
            children: [
              buildInnerLabel(
                  stdLeftIndent,
                  "Generation",
                  controllerForGeneration,
                  tankModel,
                  TankStringsEnum.generation),
              buildInnerLabel(0, "Genotype", null, tankModel,
                  TankStringsEnum.genotype, 180),
              buildInnerLabel(15, "Parents", null, tankModel,
                  TankStringsEnum.parents, 260),
            ],
          ),
          Row(
            children: [
              ((currentTank?.absolutePosition == cParkedRackAbsPosition) ||
                      (currentTank == null) ||
                      tankModel.isThereAParkedTank())
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(left: 40, top: 10),
                      child: ElevatedButton(
                        onPressed: () {
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
                            // BUGBroken evaluate to decided just error or Appwrite extension
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
            height: 20,
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: stdLeftIndent),
                child: ElevatedButton(
                    onPressed: (currentTank == null)
                        ? null
                        : () {
                            deleteEuthanizeTank(context, currentTank);
                          },
                    child: const Text("Delete/Euthanize Tank")),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
