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
import '../view_models/tankitems_viewmodel.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'parent_tank_select_view.dart';
import 'parent_euthanized_tank_display_view.dart';
import 'parent_tank_fetch_info.dart';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

// for local, comment out
//import 'package:flutter_zebra_sdk/flutter_zebra_sdk.dart';

class TankView extends StatefulWidget {
  final String? incomingRackFk;
  final int? incomingTankPosition;
  final TanksLiveViewModel tankLiveViewModelNoContext;
  final TanksLineViewModel tankLineViewModelNoContext;
  final FacilityViewModel facilityViewModelNoContext;

  const TankView(
      {super.key,
      this.incomingRackFk,
      this.incomingTankPosition,
      required this.tankLiveViewModelNoContext,
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
    return widget.tankLiveViewModelNoContext.returnCurrentPhysicalTank();
  }

  void saveTank(Tank? currentTank) {
    widget.tankLiveViewModelNoContext
        .saveExistingTank((currentTank?.absolutePosition)!)
        .then((value) {
      widget.tankLiveViewModelNoContext.callNotifyListeners();
    });
  }

  // placeholder for adding to dropdowns
  void addItem(ValueItem item) {}

  void updateSelectedTankLine(ValueItem? newSelectedTankLine) {
    ValueItem replacementSelectedTankLine = const ValueItem(
        value: cTankLineValueNotYetAssigned,
        label: cTankLineLabelNotYetAssigned);
    if (newSelectedTankLine != null) {
      replacementSelectedTankLine = newSelectedTankLine;
    }

    // here is where we save the newly selected tankline
    Tank? currentTank = returnCurrentPhysicalTank();
    currentTank?.tankLineDocId = replacementSelectedTankLine.value;
    saveTank(currentTank);
  }

  void updateSelectedGenoType(ValueItem? newSelectedGenoType) {
    Tank? currentTank = returnCurrentPhysicalTank();
    currentTank?.genoType = newSelectedGenoType?.value;
    saveTank(currentTank);
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
    widget.tankLiveViewModelNoContext
        .addListener(_updateNumberOfFishController);
    widget.tankLiveViewModelNoContext
        .addListener(_updateFishGenerationController);

    if (widget.incomingRackFk != null && widget.incomingTankPosition != null) {
      // parked cells don't have racks associated with them; parked rack is just 0 as a string.
      if (widget.incomingRackFk! != "0") {
        int? theRackAbsolutePosition =
            await facilityModel.returnRacksAbsolutePosition(widget
                .incomingRackFk!); // looks like we can just read this from the loaded racks

        await widget.tankLiveViewModelNoContext
            .selectThisRackByAbsolutePosition(
                FacilityEditState.readonlyMainScreen,
                facilityModel,
                theRackAbsolutePosition!,
                cNoNotify);
      }
      // fixed bug, we do have to call notifylisteners after all
      widget.tankLiveViewModelNoContext.selectThisTankCellConvertsVirtual(
          widget.incomingTankPosition!, cNotify);
    } else {
      await widget.tankLiveViewModelNoContext.selectThisRackByAbsolutePosition(
          FacilityEditState.readonlyMainScreen,
          facilityModel,
          kNoRackSelected,
          cNoNotify);
      widget.tankLiveViewModelNoContext
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
    widget.tankLiveViewModelNoContext
        .removeListener(_updateNumberOfFishController);
    widget.tankLiveViewModelNoContext
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
      BuildContext context, TanksLiveViewModel tanksModel, Tank currentTank) {
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
        tanksLineViewModel.returnTankItemFromDocId(currentTank.tankLineDocId);

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
      listItems: tanksLineViewModel.convertTankItemsToValueItems(),
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

    GenoTypeViewModel genoTypeViewModel =
        Provider.of<GenoTypeViewModel>(context, listen: false);

    ValueItem? selectedGenoType =
    genoTypeViewModel.returnTankItemFromDocId(currentTank.getGenoType());

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
      listItems: genoTypeViewModel.returnTankItemListAsValueItemList(),
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

  Future<bool> displayChooseParentsDialog({
    required TankStringsEnum whichParent,
    int? euthanizedDate,
    String? selectedRack,
    int? selectedTankPosition,
    required TanksSelectViewModel tankParentSelectViewModel,
    required TanksLineViewModel tanksLineViewModel,
    Tank? euthanizedParentTank,
    String? excludedTank,
  }) async {
    String parentString =
        whichParent == TankStringsEnum.parentFemale ? "female" : "male";

    final dialogResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Tank Parent $parentString'),
          content: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: (euthanizedDate != null)
                ? ParentEuthanizedTankSelectView(
                    incomingRackFk: selectedRack,
                    incomingTankPosition: selectedTankPosition,
                    tankSelectViewModelNoContext: tankParentSelectViewModel,
                    tankLineViewModelNoContext: tanksLineViewModel,
                    euthanizedParentTank: euthanizedParentTank)
                : ParentTankSelectView(
                    incomingRackFk: selectedRack,
                    incomingTankPosition: selectedTankPosition,
                    tankSelectViewModelNoContext: tankParentSelectViewModel,
                    tankLineViewModelNoContext: tanksLineViewModel,
                    excludedTank: excludedTank,
                  ),
          ),
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
    );
    return dialogResult ?? false;
  }

  Future<bool> chooseParentsDialog(
      BuildContext context,
      TankStringsEnum whichParent,
      Tank? parentTank,
      String excludedTank) async {
    TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    TanksSelectViewModel tankParentSelectViewModel =
        Provider.of<TanksSelectViewModel>(context, listen: false);
    // FacilityViewModel facilitiesViewModel =
    //     Provider.of<FacilityViewModel>(context, listen: false);

    String? selectedRack;
    int? selectedTankPosition;
    int? euthanizedDate;

    if (parentTank != null) {
      selectedRack = parentTank.rackFk;
      selectedTankPosition = parentTank.absolutePosition;
      euthanizedDate = parentTank.euthanizedDate;
    }
    // we found the parent tank
    return displayChooseParentsDialog(
        whichParent: whichParent,
        euthanizedDate: euthanizedDate,
        selectedRack: selectedRack,
        selectedTankPosition: selectedTankPosition,
        tankParentSelectViewModel: tankParentSelectViewModel,
        tanksLineViewModel: tanksLineViewModel,
        euthanizedParentTank: parentTank,
        excludedTank: excludedTank);
  }

  void saveParentTank(TankStringsEnum whichParent, Tank? currentTank) {
    TanksSelectViewModel tanksSelectViewModel =
        Provider.of<TanksSelectViewModel>(context, listen: false);

    Tank? newParentTank = tanksSelectViewModel.returnCurrentPhysicalTank();
    if (newParentTank != null && newParentTank.documentId != null) {
      switch (whichParent) {
        case TankStringsEnum.parentFemale:
          currentTank?.parentFemale = newParentTank.documentId;
          break;
        case TankStringsEnum.parentMale:
          currentTank?.parentMale = newParentTank.documentId;
          break;
        default:
          break;
      }
      saveTank(currentTank);
    }
  }

  Widget chooseParents(BuildContext context, TankStringsEnum whichParent,
      TanksLiveViewModel tanksLiveViewModel) {
    Tank? currentTank = tanksLiveViewModel.returnCurrentPhysicalTank();

    TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    String initialParentLabel =
        "${whichParent == TankStringsEnum.parentFemale ? 'Female' : 'Male'} Parent: not specified";

    Tank? parentTank;

    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: ElevatedButton(
        onPressed: (currentTank == null)
            ? null
            : () async {
                bool dialogResult = await chooseParentsDialog(
                    context, whichParent, parentTank, (currentTank.documentId)!);

                // look at the tank that is being passed in
                // if this tank has a euthanized date, then we don't execute the code below
                // we need to not make any change
                // we can't use the code below since there may be a “current” tank already saved
                // from earlier.
                if (dialogResult) {
                  if (parentTank != null) {
                    // a real parent had been selected; is it euthanized?
                    if (parentTank?.euthanizedDate == null) {
                      saveParentTank(whichParent, currentTank);
                    }
                  } else {
                    // there was no initial selection and we OKed, so we have a new selection
                    saveParentTank(whichParent, currentTank);
                  }
                }
              },
        style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black,
                ),
            minimumSize: const Size(250, 20)),
        child: FutureBuilder<ParentTankComponents>(
          future: fetchParentDetails(currentTank: currentTank, whichParent: whichParent,tanksViewModel: tanksLiveViewModel,tanksLineViewModel: tanksLineViewModel),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(initialParentLabel);
            }
            if (snapshot.connectionState == ConnectionState.done) {
              parentTank = (snapshot.data as ParentTankComponents).parentTank;
            }
            return Text((snapshot.data as ParentTankComponents).parentLabel ?? initialParentLabel);
          },
        ),
      ),
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
      TanksLiveViewModel tanksModel,
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
                    ? chooseGenoType(context, currentTank)
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
                              case TankStringsEnum.parentFemale:
                              case TankStringsEnum.parentMale:
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
      TanksLiveViewModel tankModel,
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
      TanksLiveViewModel tankModel,
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
      TanksLiveViewModel tankModel,
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
    TanksLiveViewModel tankModel = Provider.of<TanksLiveViewModel>(context);

    if (tankModel.isThereAParkedTank()) {
      Tank? tank = tankModel.returnParkedTankedInfo();

      FacilityViewModel facilityModel = Provider.of<FacilityViewModel>(context);

      double height = returnHeight(facilityModel);
      double width = returnWidth(facilityModel);

      if (tank?.getSmallTank() == false) {
        width = width * 2;
      }

      return ParkedTank(
        tanksViewModel: widget.tankLiveViewModelNoContext,
        canDrag: true,
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
        .returnTankItemFromDocId((currentTank?.tankLineDocId)!);

    GenoTypeViewModel genoTypeViewModel =
    Provider.of<GenoTypeViewModel>(context, listen: false);

    //BUGFixed was using value and not label. 2023_12_27
    String tankLineString = theTankLineValueItem.label;

    String screenPositiveString = (currentTank?.getScreenPositive() ?? false)
        ? "screen positive"
        : "screen negative";

    // added in 3.2
    String? genoType = currentTank?.getGenoType();
    ValueItem genoTypeValueItem = genoTypeViewModel.returnTankItemFromDocId(genoType);
    String genoTypeString = genoTypeValueItem.label;

    if (genoTypeString != cGenoTypeNotSpecified) {
      genoTypeString = "genotype: $genoTypeString";
    }

    String? numberOfFishString = currentTank?.getNumberOfFish().toString();
    String? generationString = currentTank?.generation.toString();
    String? dateOfBirthString = buildDateOfBirth(currentTank?.getBirthDate);

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
^FO275,135^A0N,30^FD$genoTypeString^FS
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

  void deleteEuthanizeTankDialog(BuildContext context, Tank currentTank) async {
    Map<String, dynamic> deleteTankResult = await deleteTankDialog(context);
    if (deleteTankResult['confirm'] == true) {
      ValueItem tankLineValueItem = widget.tankLineViewModelNoContext
          .returnTankItemFromDocId(currentTank.tankLineDocId);

      widget.facilityViewModelNoContext
          .convertFacilityFkToFacilityName(currentTank.facilityFk!)
          .then((facilityName) {
        widget.tankLiveViewModelNoContext.deleteEuthanizeTank(
            tankLineValueItem.label,
            facilityName!,
            currentTank.absolutePosition,
            deleteTankResult['tankLineDeleteOption']);

        // BUGfixed is not selecting an empty tank
        widget.tankLiveViewModelNoContext
            .selectThisTankCellConvertsVirtual(kEmptyTankIndex, cNotify);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // listen is on
    TanksLiveViewModel tankLiveViewModel =
        Provider.of<TanksLiveViewModel>(context);

    // we want a real physical tank here
    // business logic 8
    Tank? currentTank = tankLiveViewModel.returnCurrentPhysicalTank();

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
                child: FacilityGrid(
                    tankMode: FacilityEditState.readonlyMainScreen),
              ),
            ],
          ),
          buildOuterLabel(context, "Select Tank (facing view)"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RackGrid(
                  rackWidth: kGridFullHSize,
                  tanksViewModel: tankLiveViewModel,
                  canCreateTank: true),
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
                        tankLiveViewModel.copyTank();
                      },
                child: const Text("Copy Tank Template"),
              ),
              TextButton(
                // BUGfixed, was testing the wrong boolean
                onPressed: (!tankLiveViewModel.isTemplateInPlay)
                    ? null
                    : () {
                        tankLiveViewModel.clearTankTemplate();
                      },
                child: const Text("Clear Tank Template"),
              ),
            ],
          ),
          Row(
            children: [
              buildInnerLabel(stdLeftIndent, "Tankline", null,
                  tankLiveViewModel, TankStringsEnum.tankLine, 260),
              drawDateOfBirth(context, tankLiveViewModel, currentTank,
                  currentTank?.getBirthDate, currentTank?.setBirthDate),
              buildCheckBox(
                  tankLiveViewModel,
                  currentTank,
                  "Screen +",
                  currentTank?.getScreenPositive,
                  currentTank?.setScreenPositive),
              buildInnerLabel(0, "Fish #", controllerForNumberOfFish,
                  tankLiveViewModel, TankStringsEnum.numberOfFish),
            ],
          ),
          Row(
            children: [
              buildInnerLabel(
                  stdLeftIndent,
                  "Generation",
                  controllerForGeneration,
                  tankLiveViewModel,
                  TankStringsEnum.generation),
              buildInnerLabel(0, "Genotype", null, tankLiveViewModel,
                  TankStringsEnum.genotype, 200),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  chooseParents(
                      context, TankStringsEnum.parentFemale, tankLiveViewModel),
                  chooseParents(
                      context, TankStringsEnum.parentMale, tankLiveViewModel),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ((currentTank?.absolutePosition == cParkedRackAbsPosition) ||
                      (currentTank == null) ||
                      tankLiveViewModel.isThereAParkedTank())
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(left: 40, top: 10),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // business logic 9
                            currentTank.parkIt();
                            tankLiveViewModel
                                .saveExistingTank(cParkedRackAbsPosition)
                                .then((value) {
                              widget.tankLiveViewModelNoContext
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
                            notesDialog(
                                context, tankLiveViewModel, currentTank);
                            // BUGBroken evaluate to decided just error or Appwrite extension
                          }).catchError((error) {});
                        },
                  child: const Text("Notes…"),
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
                            deleteEuthanizeTankDialog(context, currentTank);
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
