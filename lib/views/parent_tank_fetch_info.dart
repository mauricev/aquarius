import '../view_models/tanks_viewmodel.dart';
import '../views/consts.dart';
import '../models/tank_model.dart';
import '../view_models/tanklines_viewmodel.dart';

class ParentTankComponents {
  String? parentLabel;
  Tank? parentTank;

  ParentTankComponents(this.parentLabel, this.parentTank);
}

Future<ParentTankComponents> fetchParentDetails({
  required Tank? currentTank,
  required TankStringsEnum whichParent,
  required TanksViewModel tanksViewModel,
  required TanksLineViewModel tanksLineViewModel,
}) async {

  Tank? parentTank;

  ParentTankComponents parentTankComponents = ParentTankComponents("", parentTank);

  parentTankComponents.parentLabel = "${whichParent == TankStringsEnum.parentFemale ? 'Female' : 'Male'} Parent: not specified";

  if (currentTank == null) return parentTankComponents;

  switch (whichParent) {
    case TankStringsEnum.parentFemale:
      if (currentTank.parentFemale != null) {
        parentTankComponents.parentTank = await tanksViewModel.loadTankById(currentTank.parentFemale!);
      }
      break;
    case TankStringsEnum.parentMale:
      if (currentTank.parentMale != null) {
        parentTankComponents.parentTank = await tanksViewModel.loadTankById(currentTank.parentMale!);
      }
      break;
    default:
      return parentTankComponents;
  }

  String? tankLine;
  if (parentTankComponents.parentTank != null && parentTankComponents.parentTank?.tankLineDocId != null) {
    if (parentTankComponents.parentTank?.euthanizedDate == null) {
      tankLine = tanksLineViewModel.returnTankLineFromDocId((parentTankComponents.parentTank?.tankLineDocId)!).label;
    } else {
      tankLine = parentTankComponents.parentTank?.tankLineDocId; // euthanized tanks have an embedded tankline
    }
    parentTankComponents.parentLabel = "${whichParent == TankStringsEnum.parentFemale ? 'Female' : 'Male'} Parent: $tankLine";
  }
  return parentTankComponents;
}
