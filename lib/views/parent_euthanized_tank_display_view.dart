import 'package:flutter/material.dart';
import '../views/consts.dart';
import '../models/tank_model.dart';
import 'parent_tank_select_view.dart';
import 'parent_tanks_view_common.dart';

class ParentEuthanizedTankSelectView extends ParentTankSelectView {
  final Tank? euthanizedParentTank;

  @override
   const ParentEuthanizedTankSelectView(
      {super.key,
        super.incomingRackFk,
        super.incomingTankPosition,
        required super.tankSelectViewModelNoContext,
        required super.tankLineViewModelNoContext,
        this.euthanizedParentTank});

  @override
  State<ParentEuthanizedTankSelectView> createState() => ParentEuthanizedTankSelectViewState();
}

class ParentEuthanizedTankSelectViewState extends State<ParentEuthanizedTankSelectView> {

  @override
  Widget build(BuildContext context) {

    Tank? currentTank;
    if (widget.euthanizedParentTank != null ) {
      currentTank = widget.euthanizedParentTank;
    } else {
      currentTank = widget.tankSelectViewModelNoContext.returnCurrentPhysicalTank(); // incoming values setup a current tank
    }

    return Column(
      children: [
        Row(
          children: [
            buildInnerLabel(context, stdLeftIndent, "Tankline", widget.tankSelectViewModelNoContext,
                TankStringsEnum.tankLine, widget.tankLineViewModelNoContext,200),
            drawDateOfBirth(context, widget.tankSelectViewModelNoContext, currentTank,
                currentTank?.getBirthDate, currentTank?.setBirthDate),
            buildCheckBox(
              context,
                widget.tankSelectViewModelNoContext,
                currentTank,
                "Screen +",
                currentTank?.getScreenPositive,
                currentTank?.setScreenPositive),
            buildInnerLabel(context,
                0, "Fish #", widget.tankSelectViewModelNoContext, TankStringsEnum.numberOfFish, widget.tankLineViewModelNoContext),
          ],
        ),
        Row(
          children: [
            buildInnerLabel(context, stdLeftIndent, "Generation", widget.tankSelectViewModelNoContext,
                TankStringsEnum.generation, widget.tankLineViewModelNoContext),
            buildInnerLabel(context,
                0, "Genotype", widget.tankSelectViewModelNoContext, TankStringsEnum.genotype, widget.tankLineViewModelNoContext,140),
          ],
        ),
        const SizedBox(
          height:20,
        ),
        Row(
          children: [
            buildInnerLabel(context,
                stdLeftIndent, "Parents", widget.tankSelectViewModelNoContext, TankStringsEnum.parentMale, widget.tankLineViewModelNoContext, 300),
          ],
        ),
        const SizedBox(
          height:20,
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
