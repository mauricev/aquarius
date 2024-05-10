import '../view_models/tankitems_viewmodel.dart';
import 'package:flutter/material.dart';
import '../view_models/facilities_viewmodel.dart';
import '../views/consts.dart';
import '../models/tank_model.dart';
import '../view_models/tanks_viewmodel.dart';
import 'tanks_view_rackgrid.dart';
import 'package:provider/provider.dart';
import '../view_models/search_viewmodel.dart';

void myPrint(String printThis) {
  print(printThis);
}

Stack returnTankWithOverlaidText(TanksViewModel tankViewModel, TanksLineViewModel tanksLineViewModel, int tankPosition, String imagePath) {
  const cMaxAbbreviatedLength = 5;

  Tank? tankItself = tankViewModel.returnPhysicalTankWithThisAbsolutePosition(tankPosition);

  int length = 0;
  String abbreviatedTankLine = "";

  if (tankItself != null) {
    // BUGfixed previous code was using tankLineDocId instead of actual tankline
    String tankLine = tanksLineViewModel.returnTankItemFromDocId(tankItself.tankLineDocId).label;
    length = tankLine.length;
    if (length < cMaxAbbreviatedLength) {
      abbreviatedTankLine = tankLine.substring(0, length);
    } else {
      abbreviatedTankLine = tankLine.substring(0, cMaxAbbreviatedLength);
    }
  }

  return Stack(alignment: Alignment.center,children: <Widget>[
    ClipRRect(
      clipBehavior: Clip.none,
      child: Image.asset(imagePath,
      filterQuality: FilterQuality.high,
      ),
    ),
    Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 3.0),
        child: Text(abbreviatedTankLine,style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
        )),
      ),
    )
  ]);
}

Widget buildOuterLabel(BuildContext context, String labelText) {
  return Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(
          left: 20,
        ),
        child: Text(
          labelText,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ],
  );
}

Widget buildOuterLabelHeadlineSmall(BuildContext context, String labelText) {
  return Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(
          left: 20,
          top: 20,
          bottom: 10,
        ),
        child: Text(
          labelText,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    ],
  );
}

Widget expandedFlex1() {
  return Expanded(
    flex: 1,
    child: Container(
    ),
  );
}

double returnHeight(FacilityViewModel facilityModel) {
  return (kGridVSize / facilityModel.maxShelves);
}

double returnWidth(FacilityViewModel facilityModel) {
  return (rackGridWidth / facilityModel.maxTanks);
}

int returnTimeNow() {
  DateTime now = DateTime.now();
  return now.millisecondsSinceEpoch;
}

DateTime convertMillisecondsToDateTime (int millisecondsSinceEpoch) {
  return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

String returnLocalDateAsString (DateTime fullTimeAndDate) {
  return "${fullTimeAndDate.toLocal()}".split(' ')[0];
}

String buildDateOfBirth(int? Function()? retrieveValue) {
  String dobText = "date not yet specified";

  int initialTimeAsInt = retrieveValue?.call() ?? returnTimeNow();
  if (initialTimeAsInt != 0) {
    dobText = returnLocalDateAsString(convertMillisecondsToDateTime(
        retrieveValue?.call() ?? returnTimeNow()));
  }
  return dobText;
}

Future<bool> confirmActionSpecifiedInMessage(BuildContext context, String message) async {
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

void informViewModelsOfTheFacility(BuildContext context) {
  // we are going to tell the other models what the facility is; it has already been selected

  FacilityViewModel facilityViewModel =
  Provider.of<FacilityViewModel>(context, listen: false);

  // this fetches the facility info
  // I am passing the facility to itself. How does that make any sense?
  // getFacilityInfo will also be called when a new facility is being created.
  // so we call getFacilityInfo with an empty facility, and that new facility has not been selected
  // another facility may or may not be selected. so getFacilityInfo doesn’t change the
  // selected facility; it just loads up some info on the newly created facility.
  // when the facility dropdown is set selected, then we select the facility and then call this
  // method, which in turn apprises facilityViewModel of the newly selected facility

  facilityViewModel.getFacilityInfo(facilityViewModel.selectedFacility);

  SearchViewModel searchViewModel =
  Provider.of<SearchViewModel>(context, listen: false);

  searchViewModel.setFacilityId(facilityViewModel.selectedFacility);

  TanksLiveViewModel tanksLiveViewModel =
  Provider.of<TanksLiveViewModel>(context, listen: false);

  TanksSelectViewModel tanksSelectViewModel =
  Provider.of<TanksSelectViewModel>(context, listen: false);

  tanksLiveViewModel.setFacilityId(facilityViewModel.selectedFacility);
  // BUGfixed new view model needs to know the facility
  tanksSelectViewModel.setFacilityId(facilityViewModel.selectedFacility);
}
