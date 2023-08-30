import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tanks_viewmodel.dart';
import 'package:aquarium_manager/views/consts.dart';
import 'package:aquarium_manager/models/tank_model.dart';

class ParkedTank extends StatelessWidget {
  final double height;
  final double width;
  final String? tankLine;
  final int? dateOfBirth;
  final bool? screenPositive;
  final int? numberOfFish;
  final int? fatTankPosition;
  final int? generation;

  const ParkedTank({
    Key? key,
    this.height = 0,
    this.width = 0,
    this.tankLine,
    this.dateOfBirth,
    this.screenPositive,
    this.numberOfFish,
    this.fatTankPosition,
    this.generation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TanksViewModel tankModel =
    Provider.of<TanksViewModel>(context);

    // we want these two functions below to always return a physical tank
    // because only a physical tank can live inside the parked tank
    // so if we had this function search virtual tanks, we need a guard for the parked tank position

    int tankID =
    tankModel.tankIdWithThisAbsolutePositionOnlyPhysical(cParkedAbsolutePosition);

    Tank? thisTank =
    tankModel.returnPhysicalTankWithThisAbsolutePosition(cParkedAbsolutePosition);

    // i think we can pass the tank to the receiver
    // how do we swap tanks
    // we need a second temporary rack
    // change rack id of receiver to 0 and abs position to -3
    // then change parked rack’s fk to this rack and position to is new position
    // then go back and change

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
      child: InkWell(
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            border: Border.all(),
            // we should test tankid here and if it's not in the list, then we should draw transparent; otherwise it should be gray
            color: (tankID !=
                kEmptyTankIndex) // if we are in tankmode (not editable) and there is no text, we get grayed out
                ? (tankModel.returnIsThisTankSelectedWithVirtual(cParkedAbsolutePosition))
                ? Colors.lightGreen[800]
                : Colors.grey // this grid cell has a tank
                : Colors
                .transparent, // this grid cell does not have a tank, but we need a third state here
          ),
          child: tankModel.isThisTankPhysicalAndFat(cParkedAbsolutePosition) ? Image.asset("assets/tank_fat.png") : Image.asset("assets/tank_thin.png"),
        ),
        onTap: () {
          if (tankID != kEmptyTankIndex) {
            // we only want to select actual tanks at the moment
            tankModel.selectThisTankCellConvertsVirtual(cParkedAbsolutePosition);
          }
        },
      ),
    );
  }
}