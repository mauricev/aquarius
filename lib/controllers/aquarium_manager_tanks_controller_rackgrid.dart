import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/aquarium_manager_facilities_model.dart';
import '../model/aquarium_manager_tanks_model.dart';
import '../views/utility.dart';
import 'package:aquarium_manager/controllers/aquarium_manager_tanks_controller_tankcell.dart';

class RackGrid extends StatelessWidget {
  RackGrid({
    Key? key,
  }) : super(key: key);

  final List<Row> gridDown = <Row>[];

  List<Widget> buildGridAcross(
      int absolutePosition,
      MyAquariumManagerFacilityModel facilityModel,
      MyAquariumManagerTanksModel tanksModel) {
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
      Tank? tank =
      tanksModel.tankInfoWithThisAbsolutePosition(absolutePosition);

      gridAcross.add(TankCell(
        absolutePosition: absolutePosition,
        height: height,
        width: width,
        tankLine: tank?.tankLine,
        dateOfBirth: tank?.birthDate,
        screenPositive: tank?.screenPositive,
        numberOfFish: tank?.numberOfFish,
        smallTank: tank?.smallTank,
        generation: tank?.generation,
      ));
    }
    return gridAcross;
  }

  // we might want to build designations into the tanks A-6, B-3, etc
  List<Widget> buildGridDown(MyAquariumManagerFacilityModel facilityModel,
      MyAquariumManagerTanksModel tanksModel) {

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
    MyAquariumManagerFacilityModel facilityModel =
    Provider.of<MyAquariumManagerFacilityModel>(context);

    MyAquariumManagerTanksModel tankModel =
    Provider.of<MyAquariumManagerTanksModel>(context);

    return Center(
      child: Column(
        children: buildGridDown(facilityModel, tankModel),
      ),
    );
  }
}