import 'package:aquarius/view_models/tankitems_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tanks_viewmodel.dart';
import '../views/consts.dart';
import '../models/tank_model.dart';
import '../views/utility.dart';

class ParkedTank extends StatelessWidget {
  final TanksViewModel tanksViewModel;
  final bool canDrag;
  final double height;
  final double width;
  final String? tankLine;
  final int? dateOfBirth;
  final bool? screenPositive;
  final int? numberOfFish;
  final int? fatTankPosition;
  final int? generation;

  const ParkedTank({
    super.key,
    required this.tanksViewModel,
    this.canDrag = true,
    this.height = 0,
    this.width = 0,
    this.tankLine,
    this.dateOfBirth,
    this.screenPositive,
    this.numberOfFish,
    this.fatTankPosition,
    this.generation,
  });

  Widget parkedContainer(BuildContext context) {

    TanksLineViewModel tanksLineViewModel =
    Provider.of<TanksLineViewModel>(context, listen: false);

    // we want these two functions below to always return a physical tank
    // because only a physical tank can live inside the parked tank
    // so if we had this function search virtual tanks, we need a guard for the parked tank position

    int tankID =
    tanksViewModel.tankIdWithThisAbsolutePositionOnlyPhysical(cParkedAbsolutePosition);

    return InkWell(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          border: Border.all(),
          // we should test tankid here and if it's not in the list, then we should draw transparent; otherwise it should be gray
          color: (tankID !=
              kEmptyTankIndex) // if we are in tankmode (not editable) and there is no text, we get grayed out
              ? (tanksViewModel.returnIsThisTankSelectedWithVirtual(cParkedAbsolutePosition))
              ? Colors.lightGreen[800]
              : Colors.grey // this grid cell has a tank
              : Colors
              .transparent, // this grid cell does not have a tank, but we need a third state here
        ),
        child: tanksViewModel.isThisTankPhysicalAndFat(cParkedAbsolutePosition) ? returnTankWithOverlaidText(tanksViewModel, tanksLineViewModel, cParkedAbsolutePosition, "assets/tank_fat.png") : returnTankWithOverlaidText(tanksViewModel, tanksLineViewModel, cParkedAbsolutePosition, "assets/tank_thin.png"),
      ),
      onTap: () {
        if (tankID != kEmptyTankIndex) {
          // we only want to select actual tanks at the moment
          tanksViewModel.selectThisTankCellConvertsVirtual(cParkedAbsolutePosition,cNotify);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    Tank? thisTank =
    tanksViewModel.returnPhysicalTankWithThisAbsolutePosition(cParkedAbsolutePosition);

    if (canDrag) {
      return Draggable(
        feedback: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            border: Border.all(),
            color: Colors.red,
          ),
        ),
        data: thisTank, // we pass this tank to the draggable target
        child: parkedContainer(context),
      );
    } else {
      return parkedContainer(context);
    }
  }
}