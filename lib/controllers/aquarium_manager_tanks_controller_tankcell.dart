import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/aquarium_manager_facilities_model.dart';
import '../model/aquarium_manager_tanks_model.dart';
import 'package:aquarium_manager/views/consts.dart';

class TankCell extends StatefulWidget {
  final int absolutePosition; // this can’t be altered
  final double height;
  final double width;
  final String? tankLine;
  final int? dateOfBirth;
  final bool? screenPositive;
  final int? numberOfFish;
  final bool? smallTank;
  final int? generation;

  const TankCell({
    Key? key,
    this.absolutePosition =
    0, // index starts at 1, so 0 means it’s not yet assigned, which is never the case
    this.height = 0,
    this.width = 0,
    this.tankLine,
    this.dateOfBirth,
    this.screenPositive,
    this.numberOfFish,
    this.smallTank,
    this.generation,
  }) : super(key: key);
  @override
  State<TankCell> createState() => _TankCellState();
}

class _TankCellState extends State<TankCell> {
  @override
  initState() {
    super.initState();
  }

  void createTank() {
    MyAquariumManagerFacilityModel facilityModel =
    Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);
    MyAquariumManagerTanksModel tankModel =
    Provider.of<MyAquariumManagerTanksModel>(context, listen: false);

    tankModel.addNewEmptyTank(
        facilityModel.document_id,
        widget
            .absolutePosition); // we call setstate because this function updates the current tank with a new position
    // we need to force select this tank; otherwise, there is no current tank
    tankModel.selectThisTankCell(widget.absolutePosition); // bug fixed here
  }

  void assignParkedTankItsNewHome(
      Tank? parkedTank, MyAquariumManagerTanksModel tankModel) {
    parkedTank?.absolutePosition = widget.absolutePosition;
    parkedTank?.rackFk = tankModel.rack_documentId;
  }

  void parkRackedTank(Tank? destinationTank) {
    destinationTank?.rackFk = "0";
    destinationTank?.absolutePosition = cParkedAbsolutePosition;
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerTanksModel tankModel =
    Provider.of<MyAquariumManagerTanksModel>(context);

    int rackID = tankModel.whichRackCellIsSelected();

    int tankID =
    tankModel.tankIdWithThisAbsolutePosition(widget.absolutePosition);

    return DragTarget(
      builder: (BuildContext context, List<dynamic> candidateData,
          List<dynamic> rejectedData) {
        return InkWell(
          onTap: (rackID == -2)
              ? null
              : () {
            // make sure we have a selected rack
            print("we clicked a tank cell");
            if (tankID != kEmptyTankIndex) {
              // we only want to select actual tanks at the moment
              print("we clicked an a real tank cell");
              tankModel.selectThisTankCell(widget.absolutePosition);
            }
          },
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              border: Border.all(),
              color: (rackID == -2) // no rack is selected
                  ? Colors.transparent
                  : (tankID !=
                  kEmptyTankIndex) // if we are in tankmode (not editable) and there is no text, we get grayed out
                  ? (tankModel.returnIsThisTankSelected(
                  widget.absolutePosition))
                  ? Colors.lightGreen[800]
                  : Colors.grey // this grid cell has a tank
                  : Colors
                  .transparent, // this grid cell does not have a tank, but we need a third state here
            ),
            child: (rackID == -2) // no rack is selected
                ? Text(
                  "no rack selected",
                  style: Theme.of(context).textTheme.bodySmall,
                )
                : (tankID == kEmptyTankIndex)
                ? FractionallySizedBox(
              widthFactor: 0.9, // Takes 90% of the container's width
              heightFactor:
              0.3, // Takes 30% of the container's height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero, // remove any padding
                ),
                onPressed: () {
                  // call facilities model to get facility_fk
                  // call function to return the rack_fk from the selected rack
                  // when we call selectthisrack, why don't we store the rack_fk

                  setState(() {
                    createTank();
                  });
                },
                child: const Text(
                  "Create Tank",
                  style: TextStyle(
                    fontSize: 7,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
            )
                : Text("${widget.absolutePosition}"),
          ),
        );
      },
      onWillAccept: (data) {
        print("shouldn't we be coming here");
        return true;
      },
      onAccept: (data) {
        //we have to guard against a race condition
        // what was this race condition?
        setState(() {
          Tank? parkedTank = data as Tank;

          MyAquariumManagerFacilityModel facilityModel =
          Provider.of<MyAquariumManagerFacilityModel>(context,
              listen: false);

          MyAquariumManagerTanksModel tankModel =
          Provider.of<MyAquariumManagerTanksModel>(context, listen: false);

          int tankID = tankModel.tankIdWithThisAbsolutePosition(widget
              .absolutePosition); // this represents the new, not parked tank
          if (tankID == kEmptyTankIndex) {
            // there is no tank at this position
            // the user dragged over an empty tank
            // our parked tank needs two new pieces of info
            // a new abs position and the rack_fk
            // do we have a copy of the parked tank or the actual parked tank?
            assignParkedTankItsNewHome(parkedTank, tankModel);
            // the tank has not been saved with this new info
            tankModel.saveExistingTank(
                facilityModel.document_id, widget.absolutePosition);
          } else {
            // here we are swapping tank positions
            Tank? destinationTank = tankModel
                .returnTankWithThisAbsolutePosition(widget.absolutePosition);

            // this tank is in the rack and now it's becoming a parked tank
            // ideally this should be a function
            //destinationTank?.rackFk = "0";
            //destinationTank?.absolutePosition = cParkedAbsolutePosition;
            parkRackedTank(destinationTank);

            assignParkedTankItsNewHome(parkedTank, tankModel);
            tankModel.saveExistingTank(
                facilityModel.document_id, widget.absolutePosition);
            tankModel.saveExistingTank(
                facilityModel.document_id, cParkedAbsolutePosition);
          }
          tankModel.selectThisTankCell(widget.absolutePosition);
        });
      },
    );
  }
}