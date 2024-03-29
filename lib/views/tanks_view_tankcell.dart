import 'package:aquarius/view_models/tanklines_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/facilities_viewmodel.dart';
import '../view_models/tanks_viewmodel.dart';
import '../views/consts.dart';
import '../views/utility.dart';
import '../models/tank_model.dart';

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
    super.key,
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
  });
  @override
  State<TankCell> createState() => _TankCellState();
}

class _TankCellState extends State<TankCell> {
  @override
  initState() {
    super.initState();
  }

  void createTank(bool? bigTank) {
    TanksViewModel tankModel =
        Provider.of<TanksViewModel>(context, listen: false);

    // two things here, addNewEmptyTank must set its fatTankPosition value if bigtank is picked,

    tankModel.addNewEmptyTank(
        widget.absolutePosition,
        bigTank == true
            ? (widget.absolutePosition + 1)
            : null);

    // we need to force select this tank; otherwise, there is no current tank
    tankModel.selectThisTankCellConvertsVirtual(widget
        .absolutePosition,cNotify); // we are selecting the parent tank of a fat tank cell pair
    // position will have absoluteposition as a value and will act as if it is also selected
    // BUGfixed
  }

  void pasteTank(bool? bigTank){
    // we will create a new tank internally and copy the info from the tank template;
    TanksViewModel tankModel =
    Provider.of<TanksViewModel>(context, listen: false);

    tankModel.pasteTank(
        widget.absolutePosition,
        bigTank == true
            ? (widget.absolutePosition + 1)
            : null);

    // we need to force select this tank; otherwise, there is no current tank
    tankModel.selectThisTankCellConvertsVirtual(widget
        .absolutePosition,cNotify); // we are selecting the parent tank of a fat tank cell pair
  }

  void prepareForNewTank(bool? bigTank) {

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
                  title: const Text('Make this a $cFatTank tank?'),
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

  bool canAbsolutePositionHostAFatTank(BuildContext context, int tankPosition) {
    FacilityViewModel facilityModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    // are we at the end of a row? If so, then no
    // BUGfixed this was reversed
    if ((widget.absolutePosition % facilityModel.maxTanks) == 0) {
      return false;
    }

    TanksViewModel tankModel =
        Provider.of<TanksViewModel>(context, listen: false);

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
    TanksViewModel tankModel = Provider.of<TanksViewModel>(context);

    TanksLineViewModel tanksLineViewModel = Provider.of<TanksLineViewModel>(context, listen: false);

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
                        widget.absolutePosition,cNotify);
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
                          : const Color(0xFF90CAF9)
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
                                    if (tankModel.isTemplateInPlay) {
                                      pasteTank(fatTankState);
                                    } else {
                                      createTank(fatTankState);
                                    }
                                  });
                                }
                              });
                            } else {
                              setState(() {
                                // false to bigtank, means a thin tank
                                if (tankModel.isTemplateInPlay) {
                                  pasteTank(false);
                                } else {
                                  createTank(false);
                                }
                              });
                            }
                          },
                          child: Text( (tankModel.isTemplateInPlay) ? "Paste Tank" : "Create Tank",
                            style: const TextStyle(
                              fontSize: 7,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      )
                    // this is where we draw the tank, real or virtual
                    // we need a compound widget that draws a portion of the tank line
                    // and the icon; i just noticed that the fat icon takes up the cell
                    : tankModel.isThisTankVirtual(widget.absolutePosition + 1)
                        ? returnTankWithOverlaidText(tankModel, tanksLineViewModel, widget.absolutePosition,"assets/tank_fat_left.png")
                        : tankModel.isThisTankVirtual(widget.absolutePosition)
                            ? Image.asset("assets/tank_fat_right.png")
                            : returnTankWithOverlaidText(tankModel, tanksLineViewModel, widget.absolutePosition,"assets/tank_thin.png"),
          ),
        );
      },
    onWillAcceptWithDetails: (DragTargetDetails<Tank> dragTargetDetails) {
        Tank parkedTank = dragTargetDetails.data;
        // if we have a fat parked tank
        if (parkedTank.fatTankPosition != null) {
          if (canAbsolutePositionHostAFatTank(
                  context, widget.absolutePosition) ==
              false) {
            return false;
          }
        }
        return true;
      },
      onAcceptWithDetails: (DragTargetDetails<Tank> dragTargetDetails) {
        //we have to guard against a race condition
        // what was this race condition?
        setState(() {
          Tank parkedTank = dragTargetDetails.data;

          TanksViewModel tankModel =
              Provider.of<TanksViewModel>(context, listen: false);

          tankModel.parkedADraggedTank(parkedTank,widget.absolutePosition);
        });
      },
    );
  }
}
