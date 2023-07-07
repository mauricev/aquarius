import 'package:flutter/material.dart';
import '../model/aquarium_manager_facilities_model.dart';
import 'package:aquarium_manager/views/consts.dart';

void myPrint(String printThis) {
  print(printThis);
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

double returnHeight(MyAquariumManagerFacilityModel facilityModel) {
  return (kGridVSize / facilityModel.maxShelves);
}

double returnWidth(MyAquariumManagerFacilityModel facilityModel) {
  return (kGridHSize / facilityModel.maxTanks);
}

int returnTimeNow() {
  DateTime now = DateTime.now();
  //return now.millisecondsSinceEpoch ~/ 1000;
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
