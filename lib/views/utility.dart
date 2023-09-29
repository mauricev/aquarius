import 'package:flutter/material.dart';
import '../view_models/facilities_viewmodel.dart';
import '../views/consts.dart';

void myPrint(String printThis) {
  //print(printThis);
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
  return (kGridHSize / facilityModel.maxTanks);
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
