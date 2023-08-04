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
        facilityModel.documentId,
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

  Future<bool> confirmSmallTank(BuildContext context) async {
    bool isFatTank = false;

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Create Tank'),
              actions: <Widget>[
                CheckboxListTile(
                  tileColor: Colors.red,
                  title: const Text('Make this a fat tank?'),
                  value: false,
                  onChanged: (bool? value) {
                    isFatTank = value ?? false;
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
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
        ) ??
        false;
  }

  void assignParkedTankItsNewHome(
      Tank? parkedTank, MyAquariumManagerTanksModel tankModel) {
    parkedTank?.assignTankNewLocation(
        tankModel.rackDocumentid, widget.absolutePosition);
  }

  void parkRackedTank(Tank? destinationTank) {
    destinationTank?.parkIt();
  }

  bool canAbsolutePositionHostAFatTank(BuildContext context, int tankPosition) {
    MyAquariumManagerFacilityModel facilityModel =
    Provider.of<MyAquariumManagerFacilityModel>(context,
        listen: false);

    // are we at the end of a row? If so, then no
    if ((facilityModel.maxTanks % widget.absolutePosition) == 0) {
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
          onTap: (rackID == -2)
              ? null
              : () {
                  // make sure we have a selected rack
                  myPrint("we clicked a tank cell");
                  if (tankID != kEmptyTankIndex) {
                    // we only want to select actual tanks at the moment
                    myPrint("we clicked an a real tank cell");

                    /*
              tankID will return a physical tank always
              but this selectthistankcel is selecting a virtual tank
              we this postion minus 1 but what is telling it we are virtual?
              we could have another intervening function here that checks
              if this position harbors a real or physical tank
              we can have a convert function
              pass in widget.absolutePosition and it looks to see if it there is a physical tank
              at this position and if there is, it returns widget.absolutePosition
              otherwise, it checks to see if there a fattankposition at this widget.absolutePosition
              and if there is it returns its absoluteposition
              convertVirtualTankPositionToPhysical(widget.absolutePosition);
              do we want to pass this function or to call it inside selectThisTankCell
              because we don’t really want selectThisTankCell to ever select a virtual tank
               */

                    tankModel.selectThisTankCellConvertsVirtual(
                        widget.absolutePosition);
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
                      ? (tankModel.returnIsThisTankSelectedWithVirtual(
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

                            // can this function be called from a parked tank position?
                            // because fattankposition will be wrong

                            // new check: if there is a tank to the right of widget.absolutePosition, then this must return false

                            if (canAbsolutePositionHostAFatTank(
                                context, widget.absolutePosition)) {
                              myPrint(
                                  "tank at ${widget.absolutePosition} can host a fat tank");
                              confirmSmallTank(context).then((fatTankState) {
                                myPrint("we clicked OK to the fat tank dialog");
                                if (fatTankState != null) {
                                  // null means the user cancelled
                                  setState(() {
                                    myPrint(
                                        "we are creating a tank with state ${fatTankState}");
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
                    : Text("${widget.absolutePosition}"),
          ),
        );
      },
      onWillAccept: (data) {
        myPrint("shouldn't we be coming here");
        Tank parkedTank = data as Tank;

        // if we have a fat parked tank
        if (parkedTank.fatTankPosition != null) {
          if (canAbsolutePositionHostAFatTank(
              context, widget.absolutePosition) == false) {
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
          if (tankModel.IsThisTankVirtual(widget.absolutePosition)) {
            thisPosition = widget.absolutePosition - 1;
          }

          // this will be physical
          int tankID = tankModel.tankIdWithThisAbsolutePositionOnlyPhysical(
              thisPosition); // this represents the new, not parked tank
          if (tankID == kEmptyTankIndex) {
            // there is no tank at this position
            // the user dragged over an empty tank
            // our parked tank needs two new pieces of info
            // a new abs position and the rack_fk
            // do we have a copy of the parked tank or the actual parked tank?
            assignParkedTankItsNewHome(parkedTank, tankModel);
            // the tank has not been saved with this new info
            // this will be physical
            tankModel.saveExistingTank(
                facilityModel.documentId, thisPosition);
          } else {
            // here we are swapping tank positions
            // this will be physical
            Tank? destinationTank =
                tankModel.returnPhysicalTankWithThisAbsolutePosition(
                    thisPosition);

            // this tank is in the rack and now it's becoming a parked tank
            // ideally this should be a function
            //destinationTank?.rackFk = "0";
            //destinationTank?.absolutePosition = cParkedAbsolutePosition;
            parkRackedTank(destinationTank);

            assignParkedTankItsNewHome(parkedTank, tankModel);
            // this will be physical
            tankModel.saveExistingTank(
                facilityModel.documentId, thisPosition);
            // this will be physical
            tankModel.saveExistingTank(
                facilityModel.documentId, cParkedAbsolutePosition);
          }
          // below we are passing a physical tank position
          // so selectThisTankCell should never come to the virtual tank code
          tankModel.selectThisTankCellConvertsVirtual(thisPosition);
        });
      },
    );
  }
}
