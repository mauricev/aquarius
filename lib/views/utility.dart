import 'package:flutter/material.dart';

import '../model/aquarium_manager_facilities_model.dart';

const int kGridHSize = 650;
const int kGridVSize = 500;
const String kProgramName = 'Aquarius';

Widget BuildOuterLabel(BuildContext context, String labelText) {
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

Widget BuildOuterLabel_HeadlineSmall(BuildContext context, String labelText) {
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

Widget ExpandedFlex1() {
  return Expanded(
    flex: 1,
    child: Container(
    ),
  );
}

double ReturnHeight(MyAquariumManagerFacilityModel facilityModel) {
  return (kGridVSize / facilityModel.maxShelves);
}

double ReturnWidth(MyAquariumManagerFacilityModel facilityModel) {
  return (kGridHSize / facilityModel.maxTanks);
}

int returnTimeNow() {
  DateTime now = DateTime.now();
  return now.millisecondsSinceEpoch ~/ 1000;
}

DateTime ConvertMillisecondsToDateTime (int millisecondsSinceEpoch) {
  return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

String ReturnLocalDateAsString (DateTime fullTimeAndDate) {
  return "${fullTimeAndDate.toLocal()}".split(' ')[0];
}

String buildDateOfBirth(int? retrieveValue()?) {
  String dobText = "date not yet specified";

  int initialTimeAsInt = retrieveValue?.call() ?? returnTimeNow();
  if (initialTimeAsInt != 0) {
    dobText = ReturnLocalDateAsString(ConvertMillisecondsToDateTime(
        retrieveValue?.call() ?? returnTimeNow()));
  }
  return dobText;
}