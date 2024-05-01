import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/facilities_viewmodel.dart';
import '../view_models/tanks_viewmodel.dart';
import 'utility.dart';
import 'facility_grid.dart';
import '../views/consts.dart';
import '../views/tanks_view_parkedtank.dart';
import '../views/tanks_view_rackgrid.dart';
import '../models/tank_model.dart';
import '../view_models/tankitems_viewmodel.dart';
import 'parent_tanks_view_common.dart';

class ParentTankSelectView extends StatefulWidget {
  final String? incomingRackFk;
  final int? incomingTankPosition;
  final TanksSelectViewModel tankSelectViewModelNoContext;
  final TanksLineViewModel tankLineViewModelNoContext;
  final String? excludedTank;

  const ParentTankSelectView(
      {super.key,
      this.incomingRackFk,
      this.incomingTankPosition,
      required this.tankSelectViewModelNoContext,
      required this.tankLineViewModelNoContext,
      this.excludedTank});

  @override
  State<ParentTankSelectView> createState() => ParentTankSelectViewState();
}

class ParentTankSelectViewState extends State<ParentTankSelectView> {
  Tank? returnCurrentPhysicalTank() {
    return widget.tankSelectViewModelNoContext.returnCurrentPhysicalTank();
  }

  void _prepareRacksAndTanksForCaller() async {
    FacilityViewModel facilityModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    if (widget.incomingRackFk != null && widget.incomingTankPosition != null) {
      // parked cells don't have racks associated with them; parked rack is just 0 as a string.
      if (widget.incomingRackFk! != "0") {
        int? theRackAbsolutePosition =
            await facilityModel.returnRacksAbsolutePosition(widget
                .incomingRackFk!); // looks like we can just read this from the loaded racks

        await widget.tankSelectViewModelNoContext
            .selectThisRackByAbsolutePosition(FacilityEditState.readonlyDialog,
                facilityModel, theRackAbsolutePosition!, cNoNotify);
      }
      widget.tankSelectViewModelNoContext.selectThisTankCellConvertsVirtual(
          widget.incomingTankPosition!, cNotify);
    } else {
      await widget.tankSelectViewModelNoContext
          .selectThisRackByAbsolutePosition(FacilityEditState.readonlyDialog,
              facilityModel, kNoRackSelected, cNoNotify);
      widget.tankSelectViewModelNoContext
          .selectThisTankCellConvertsVirtual(kEmptyTankIndex, cNotify);
    }
  }

  @override
  void initState() {
    super.initState();
    _prepareRacksAndTanksForCaller();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  Widget buildParkedTank(BuildContext context) {
    // here we have listen on.
    TanksSelectViewModel tankSelectViewModel =
        Provider.of<TanksSelectViewModel>(context);

    if (tankSelectViewModel.isThereAParkedTank()) {
      Tank? tank = tankSelectViewModel.returnParkedTankedInfo();

      // if we are in select and the parked tank is the currentank, don’t draw it
      if ((widget.excludedTank != null) && (tank?.documentId == widget.excludedTank)) {
        return Container();
      }

      FacilityViewModel facilityModel = Provider.of<FacilityViewModel>(context);

      double height = returnHeight(facilityModel);
      double width = returnWidth(facilityModel);

      if (tank?.getSmallTank() == false) {
        width = width * 2;
      }

      return ParkedTank(
        tanksViewModel: tankSelectViewModel,
        canDrag: false,
        height: height,
        width: width,
        tankLine: tank?.tankLineDocId,
        dateOfBirth: tank?.getBirthDate(),
        screenPositive: tank?.getScreenPositive(),
        numberOfFish: tank?.getNumberOfFish(),
        fatTankPosition: tank?.fatTankPosition,
        generation: tank?.generation,
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    TanksSelectViewModel tankSelectViewModel =
        Provider.of<TanksSelectViewModel>(context);

    Tank? currentTank = tankSelectViewModel.returnCurrentPhysicalTank();

    return Column(
      children: [
        buildOuterLabel(context, "Select Rack (top view)"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: FacilityGrid(tankMode: FacilityEditState.readonlyDialog),
            ),
          ],
        ),
        buildOuterLabel(context, "Select Tank (facing view)"),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            RackGrid(
                rackWidth: kGridDialogHSize,
                tanksViewModel: tankSelectViewModel,
                canCreateTank: false,
                excludedTank: widget.excludedTank),
            buildParkedTank(context),
          ],
        ),
        Row(
          children: [
            buildInnerLabel(context, stdLeftIndent, "Tankline",
                tankSelectViewModel, TankStringsEnum.tankLine, widget.tankLineViewModelNoContext,200),
            drawDateOfBirth(context, tankSelectViewModel, currentTank,
                currentTank?.getBirthDate, currentTank?.setBirthDate),
            buildCheckBox(context, tankSelectViewModel, currentTank, "Screen +",
                currentTank?.getScreenPositive, currentTank?.setScreenPositive),
            buildInnerLabel(context, 0, "Fish #", tankSelectViewModel,
                TankStringsEnum.numberOfFish, widget.tankLineViewModelNoContext),
          ],
        ),
        Row(
          children: [
            buildInnerLabel(context, stdLeftIndent, "Generation",
                tankSelectViewModel, TankStringsEnum.generation, widget.tankLineViewModelNoContext),
            buildInnerLabel(context, 0, "Genotype", tankSelectViewModel,
                TankStringsEnum.genotype, widget.tankLineViewModelNoContext,140),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            buildInnerLabel(context, stdLeftIndent, "Parents",
                tankSelectViewModel, TankStringsEnum.parentFemale, widget.tankLineViewModelNoContext,300),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            SizedBox(
              width: 390, //space for the note
              child: Text(currentTank?.notes.returnCurrentNoteText() ??
                  "No current note"),
            ),
          ],
        ),
      ],
    );
  }
}
