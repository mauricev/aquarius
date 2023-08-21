import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/aquarium_manager_facilities_model.dart';
import '../model/aquarium_manager_tanks_model.dart';
import 'package:aquarium_manager/views/consts.dart';
import 'package:aquarium_manager/views/utility.dart';

class TankCell extends StatefulWidget {
  final int absolutePosition; // this can’t be altered
  final double height;
  final double width;
  final String? tankLine;
  final int? dateOfBirth;
  final bool? screenPositive;
  final int? numberOfFish;
  final int? fatTankPosition;
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
    this.fatTankPosition,
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

  void createTank(bool? bigTank) {
    MyAquariumManagerFacilityModel facilityModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context, listen: false);

    // two things here, addNewEmptyTank must set its fatTankPosition value if bigtank is picked,

    tankModel.addNewEmptyTank(
        facilityModel.returnFacilityId(),
        widget.absolutePosition,
        bigTank == true
            ? (widget.absolutePosition + 1)
            : null); // we call setstate because this function updates the current tank with a new position

    // we need to force select this tank; otherwise, there is no current tank
    tankModel.selectThisTankCellConvertsVirtual(widget
        .absolutePosition); // we are selecting the parent tank of a fat tank cell pair
    // position will have absoluteposition as a value and will act as if it is also selected
    // bug fixed here
  }

  Future<bool?> confirmSmallTank(BuildContext context) async {
    bool isFatTank = false;

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Tank'),
          actions: <Widget>[
            // for whatever reason inside the alertdialog, the outside variable isFatTank
            // is regarded as local, so we need StatefulBuilder to attach it to outside
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return CheckboxListTile(
                  //tileColor: Colors.red,
                  title: const Text('Make this a fat tank?'),
                  value: isFatTank,
                  onChanged: (bool? value) {
                    setState(() {
                      isFatTank = value ?? false;
                    });
                  },
                );
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                myPrint("we clicked cancel");
                Navigator.of(context).pop(null); // null to cancel dialog
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(isFatTank);
              },
            ),
          ],
        );
      },
    );
  }

  // we can’t use widget.absoluteposition because that represents the cell the user clicked on
  // and if it’s a virtual tank, we need the tank to its immediate left
  void assignParkedTankItsNewHome(Tank? parkedTank, int newTankPosition,
      MyAquariumManagerTanksModel tankModel) {
    parkedTank?.assignTankNewLocation(
        tankModel.rackDocumentid, newTankPosition);
  }

  void parkRackedTank(Tank? destinationTank) {
    destinationTank?.parkIt();
  }

  bool canAbsolutePositionHostAFatTank(BuildContext context, int tankPosition) {
    MyAquariumManagerFacilityModel facilityModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

    // are we at the end of a row? If so, then no
    // BUG this was reversed
    if ((widget.absolutePosition % facilityModel.maxTanks) == 0) {
      return false;
    }

    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context, listen: false);

    // is the cell over 1 occupied physically?
    Tank? tank =
        tankModel.returnPhysicalTankWithThisAbsolutePosition(tankPosition + 1);
    if (tank != null) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    MyAquariumManagerTanksModel tankModel =
        Provider.of<MyAquariumManagerTanksModel>(context);

    int rackID = tankModel.whichRackCellIsSelected();

    // this can return a physical tank or a virtual tank
    // so when drawing the tank cell if a physical tank has a virtual tank at this widget.absolutePosition
    // it will drawn as if there is a tank there
    // however, there is a problem, selectThisTankCell will select a virtual tank
    // and it can't do that; it needs to select the physical tank

    int tankID = tankModel
        .tankIdWithThisAbsolutePositionIncludesVirtual(widget.absolutePosition);

    return DragTarget(
      builder: (BuildContext context, List<dynamic> candidateData,
          List<dynamic> rejectedData) {
        return InkWell(
          onTap: (rackID == kNoRackSelected)
              ? null
              : () {
                  // make sure we have a selected rack
                  if (tankID != kEmptyTankIndex) {
                    // we only want to select actual tanks at the moment
                    tankModel.selectThisTankCellConvertsVirtual(
                        widget.absolutePosition);
                  }
                },
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              border: Border(
                top: const BorderSide(width: 1.5, color: Colors.black),
                left: tankModel.isThisTankVirtual(widget.absolutePosition)
                    ? const BorderSide(width: 0, color: Colors.transparent)
                    : const BorderSide(width: 1.0, color: Colors.grey),
                right:
                    tankModel.isThisTankPhysicalAndFat(widget.absolutePosition)
                        ? const BorderSide(width: 0, color: Colors.transparent)
                        : const BorderSide(width: 1.0, color: Colors.grey),
                bottom: const BorderSide(width: 1.5, color: Colors.black),
              ),
              color: (rackID == kNoRackSelected) // no rack is selected
                  ? Colors.transparent
                  : (tankID !=
                          kEmptyTankIndex) // if we are in tankmode (not editable) and there is no text, we get grayed out
                      ? (tankModel.returnIsThisTankSelectedWithVirtual(
                              widget.absolutePosition))
                          ? Colors.white
                          //: Colors.lightGreen[500] // this grid cell has a tank
                          : Color(0xFF90CAF9)
                      : Colors
                          .transparent, // this grid cell does not have a tank, but we need a third state here
            ),
            child: (rackID == kNoRackSelected) // no rack is selected
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

                            // can this function be called from a parked tank position?
                            // because fattankposition will be wrong

                            // new check: if there is a tank to the right of widget.absolutePosition, then this must return false
                            if (canAbsolutePositionHostAFatTank(
                                context, widget.absolutePosition)) {

                              confirmSmallTank(context).then((fatTankState) {

                                if (fatTankState != null) {
                                  // null means the user cancelled
                                  setState(() {
                                    createTank(fatTankState);
                                  });
                                }
                              });
                            } else {
                              setState(() {
                                createTank(false); // false means small tank
                              });
                            }
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
                    : tankModel
                                .isThisTankVirtual(widget.absolutePosition + 1)
                            ? Image.asset("assets/tank_fat_left.png")
                            : tankModel
                                    .isThisTankVirtual(widget.absolutePosition)
                                ? Image.asset("assets/tank_fat_right.png")
                                : Image.asset("assets/tank_thin.png"),
          ),
        );
      },
      onWillAccept: (data) {
        myPrint("on will accept");
        Tank parkedTank = data as Tank;
        myPrint("on will accept");
        // if we have a fat parked tank
        if (parkedTank.fatTankPosition != null) {
          myPrint("on will accept, parked is fat");
          if (canAbsolutePositionHostAFatTank(
                  context, widget.absolutePosition) ==
              false) {
            myPrint("on will accept, reject fat tank here");
            return false;
          }
        }
        return true;
      },
      onAccept: (data) {
        //we have to guard against a race condition
        // what was this race condition?
        setState(() {
          Tank parkedTank = data as Tank;

          MyAquariumManagerFacilityModel facilityModel =
              Provider.of<MyAquariumManagerFacilityModel>(context,
                  listen: false);

          MyAquariumManagerTanksModel tankModel =
              Provider.of<MyAquariumManagerTanksModel>(context, listen: false);

          // if this destination widget is a virtual tank, make the swap with the prior position numerically
          int thisPosition = widget.absolutePosition;
          if (tankModel.isThisTankVirtual(thisPosition)) {
            myPrint("dragging, this tank is virtual");
            thisPosition = widget.absolutePosition - 1;
          }

          // this will be physical
          int tankID = tankModel.tankIdWithThisAbsolutePositionOnlyPhysical(
              thisPosition); // this represents the new, not parked tank
          if (tankID == kEmptyTankIndex) {
            myPrint("we dragged to an empty tank spot");
            // there is no tank at this position
            // the user dragged over an empty tank
            // our parked tank needs two new pieces of info
            // a new abs position and the rack_fk
            // do we have a copy of the parked tank or the actual parked tank?
            assignParkedTankItsNewHome(parkedTank, thisPosition, tankModel);
            // the tank has not been saved with this new info
            // this will be physical
            tankModel.saveExistingTank(facilityModel.returnFacilityId(), thisPosition);
          } else {
            myPrint("we dragged to an active tank spot");
            // here we are swapping tank positions
            // this will be physical
            Tank? destinationTank = tankModel
                .returnPhysicalTankWithThisAbsolutePosition(thisPosition);

            // BUG if this tank is fat, then its fat position needs a special value, perhaps 0, so it doesn’t select anything
            parkRackedTank(destinationTank);

            // BUG if this tank is fat, then its fat position needs to be updated
            assignParkedTankItsNewHome(parkedTank, thisPosition, tankModel);
            // this will be physical
            tankModel.saveExistingTank(facilityModel.returnFacilityId(), thisPosition);
            // this will be physical
            tankModel.saveExistingTank(
                facilityModel.returnFacilityId(), cParkedAbsolutePosition);
          }
          // below we are passing a physical tank position
          // so selectThisTankCell should never come to the virtual tank code
          myPrint(
              "about to select a physical tank after dragging, ${thisPosition}");
          tankModel.selectThisTankCellConvertsVirtual(thisPosition);
        });
      },
    );
  }
}
