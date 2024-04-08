import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tanks_viewmodel.dart';
import 'utility.dart';
import '../views/consts.dart';
import '../models/tank_model.dart';
import '../view_models/tanklines_viewmodel.dart';
import 'package:simple_search_dropdown/simple_search_dropdown.dart';
import 'parent_tank_fetch_info.dart';

Widget buildCheckBox(
    BuildContext context,
    TanksSelectViewModel tankModel,
    Tank? currentTank,
    String labelText,
    bool? Function()? retrieveValue,
    void Function(bool newValue)? updateValue) {
  return SizedBox(
    width: 130,
    child: CheckboxListTile(
      title: Text(
        labelText,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: retrieveValue?.call() ?? false,
      onChanged: null,
      controlAffinity: ListTileControlAffinity.leading, //  <-- leading Checkbox
    ),
  );
}

Widget drawDateOfBirth(
    BuildContext context,
    TanksSelectViewModel tankModel,
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
      Text(buildDateOfBirth(retrieveValue)),
    ],
  );
}

Widget chooseGenoType(BuildContext context, Tank currentTank) {
  TanksSelectViewModel tanksSelectViewModel =
  Provider.of<TanksSelectViewModel>(context, listen: false);

  ValueItem? selectedGenoType = tanksSelectViewModel
      .convertGenoTypeToValueItem(currentTank.getGenoType());

  String genoType = selectedGenoType?.label ?? "genotype not specified";
  return Text(
    genoType,
    style: Theme.of(context).textTheme.bodySmall,
  );
}

Widget buildInnerLabel(
    BuildContext context,
    double leftIndent,
    String labelText,
    TanksSelectViewModel tanksSelectViewModel,
    TankStringsEnum tanksStringsValue,
    TanksLineViewModel tankLineViewModelNoContext,
    [double? width]) {
  Tank? currentTank = tanksSelectViewModel.returnCurrentPhysicalTank();

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
                  : ((tanksStringsValue == TankStringsEnum.parentMale) ||
                              (tanksStringsValue ==
                                  TankStringsEnum.parentFemale)) &&
                          (currentTank != null)
                      ? chooseParents(context, currentTank,
                          tanksSelectViewModel, tankLineViewModelNoContext)
                      : (tanksStringsValue == TankStringsEnum.numberOfFish) &&
                              (currentTank != null)
                          ? Text(
                              currentTank.numberOfFish.toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          : (tanksStringsValue == TankStringsEnum.generation) &&
                                  (currentTank != null)
                              ? Text(
                                  currentTank.generation.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              : const Text(""),
        ),
      ],
    ),
  );
}

Widget chooseTankLineDropDown(BuildContext context, Tank currentTank) {
  TanksLineViewModel tanksLineViewModel =
      Provider.of<TanksLineViewModel>(context, listen: false);

  ValueItem selectedTank =
      tanksLineViewModel.returnTankLineFromDocId(currentTank.tankLineDocId);
  String tankLine = "tankline not yet specified";
  if (selectedTank.label != "") {
    tankLine = selectedTank.label;
  }
  return Text(
    tankLine,
    style: Theme.of(context).textTheme.bodySmall,
  );
}

Widget chooseParents(
    BuildContext context,
    Tank currentTank,
    TanksViewModel tanksSelectViewModel,
    TanksLineViewModel tanksLineViewModel) {

  return FutureBuilder<List<ParentTankComponents>>(
    future: Future.wait([
      fetchParentDetails(
        currentTank: currentTank,
        whichParent: TankStringsEnum.parentFemale,
        tanksViewModel: tanksSelectViewModel,
        tanksLineViewModel: tanksLineViewModel,
      ),
      fetchParentDetails(
        currentTank: currentTank,
        whichParent: TankStringsEnum.parentMale,
        tanksViewModel: tanksSelectViewModel,
        tanksLineViewModel: tanksLineViewModel,
      ),
    ]),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Text("Loading parent details...",style: Theme.of(context).textTheme.bodySmall);
      } else if (snapshot.hasData) {
        String combinedParentDetails = snapshot.data!
            .map((parentDetails) => parentDetails.parentLabel)
            .join(' | ');
        return Text(combinedParentDetails, style: Theme.of(context).textTheme.bodySmall);
      } else {
        return Text("Failed to load parent details", style: Theme.of(context).textTheme.bodySmall);
      }
    },
  );
}
