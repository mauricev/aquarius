import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/facilities_viewmodel.dart';
import '../view_models/tanks_viewmodel.dart';
import 'utility.dart';
import '../views/tanks_view_tankcell.dart';
import '../models/tank_model.dart';
import 'consts.dart';

int rackGridWidth = kGridFullHSize;

class RackGrid extends StatelessWidget {
  final bool canCreateTank;
  final int rackWidth;
  final TanksViewModel tanksViewModel;
  final String? excludedTank;
  RackGrid(
      {super.key,
      required this.rackWidth,
      required this.tanksViewModel,
      required this.canCreateTank,
      this.excludedTank}) {
    rackGridWidth = rackWidth;
  }

  final List<Row> gridDown = <Row>[];

  List<Widget> buildGridAcross(int absolutePosition,
      FacilityViewModel facilityModel, TanksViewModel tanksViewModel) {
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
      Tank? tank = tanksViewModel
          .returnPhysicalTankWithThisAbsolutePosition(absolutePosition);

      gridAcross.add(canCreateTank
          ? TankLiveCell(
              tanksViewModel:
                  tanksViewModel, // the underlying class of tanksViewModel is tied to the subclass that is instantiated here
              absolutePosition: absolutePosition,
              height: height,
              width: width,
              tankLine: tank?.tankLineDocId,
              dateOfBirth: tank?.getBirthDate(),
              screenPositive: tank?.getScreenPositive(),
              numberOfFish: tank?.getNumberOfFish(),
              fatTankPosition: tank?.fatTankPosition,
              generation: tank?.generation,
            )
          : TankSelectCell(
              tanksViewModel:
                  tanksViewModel, // the underlying class of tanksViewModel is tied to the subclass that is instantiated here
              absolutePosition: absolutePosition,
              height: height,
              width: width,
              tankLine: tank?.tankLineDocId,
              dateOfBirth: tank?.getBirthDate(),
              screenPositive: tank?.getScreenPositive(),
              numberOfFish: tank?.getNumberOfFish(),
              fatTankPosition: tank?.fatTankPosition,
              generation: tank?.generation,
              excludedTank: excludedTank));
    }
    return gridAcross;
  }

  // we might want to build designations into the tanks A-6, B-3, etc
  List<Widget> buildGridDown(
      FacilityViewModel facilityModel, TanksViewModel tanksViewModel) {
    int offset = 0;
    for (int theIndex = 1; theIndex <= facilityModel.maxShelves; theIndex++) {
      gridDown.add(Row(
        children:
            buildGridAcross(theIndex + offset, facilityModel, tanksViewModel),
      ));
      offset = offset +
          (facilityModel.maxTanks -
              1); // we are offsetting the index for each row by the amount of tanks minus 1
    }
    return gridDown;
  }

  @override
  Widget build(BuildContext context) {
    FacilityViewModel facilityModel = Provider.of<FacilityViewModel>(context);

    return Center(
      child: Column(
        children: buildGridDown(facilityModel, tanksViewModel),
      ),
    );
  }
}
