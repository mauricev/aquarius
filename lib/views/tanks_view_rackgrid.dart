import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/facilities_viewmodel.dart';
import '../view_models/tanks_viewmodel.dart';
import 'utility.dart';
import '../views/tanks_view_tankcell.dart';
import '../models/tank_model.dart';

class RackGrid extends StatelessWidget {
  RackGrid({
    Key? key,
  }) : super(key: key);

  final List<Row> gridDown = <Row>[];

  List<Widget> buildGridAcross(
      int absolutePosition,
      FacilityViewModel facilityModel,
      TanksViewModel tanksModel) {
    List<Widget> gridAcross = <TankCell>[];

    double height = returnHeight(facilityModel);
    double width = returnWidth(facilityModel);

    int offset = 0;
    for (int theIndex = 1; theIndex <= facilityModel.maxTanks; theIndex++) {
      absolutePosition =
          absolutePosition + offset; //absolutePosition is never 0;
      if (offset == 0) {
        offset = offset + 1;
      }
      // virtual tanks don’t get any actual tank info; we trick it when it’s drawn or clicked on
      Tank? tank =
      tanksModel.returnPhysicalTankWithThisAbsolutePosition(absolutePosition);

      gridAcross.add(TankCell(
        absolutePosition: absolutePosition,
        height: height,
        width: width,
        tankLine: tank?.tankLine,
        dateOfBirth: tank?.getBirthDate(),
        screenPositive: tank?.getScreenPositive(),
        numberOfFish: tank?.getNumberOfFish(),
        fatTankPosition: tank?.fatTankPosition,
        generation: tank?.generation,
      ));
    }
    return gridAcross;
  }

  // we might want to build designations into the tanks A-6, B-3, etc
  List<Widget> buildGridDown(FacilityViewModel facilityModel,
      TanksViewModel tanksModel) {

    int offset = 0;
    for (int theIndex = 1; theIndex <= facilityModel.maxShelves; theIndex++) {
      gridDown.add(Row(
        children: buildGridAcross(theIndex + offset, facilityModel, tanksModel),
      ));
      offset = offset +
          (facilityModel.maxTanks -
              1); // we are offsetting the index for each row by the amount of tanks minus 1
    }
    return gridDown;
  }

  @override
  Widget build(BuildContext context) {
    FacilityViewModel facilityModel =
    Provider.of<FacilityViewModel>(context);

    TanksViewModel tankModel =
    Provider.of<TanksViewModel>(context, listen:false);

    return Center(
      child: Column(
        children: buildGridDown(facilityModel, tankModel),
      ),
    );
  }
}