import '../models/tank_model.dart';
import 'session_key.dart';

void addTankFromDatabase(
    String documentId,
    String? facilityFk,
    String rackFk,
    int absolutePosition,
    String tankLine,
    int birthDate,
    bool? screenPositive,
    int? numberOfFish,
    int? fatTankPosition,
    int? generation,
    String? genotype,
    String? parentFemale,
    String? parentMale,
    ManageSession manageSession,
    List<Tank> tankList
    ) {
  Tank aTank = Tank(
      documentId: documentId,
      facilityFk: facilityFk,
      rackFk: rackFk,
      absolutePosition: absolutePosition,
      tankLineDocId: tankLine,
      birthDate: birthDate,
      screenPositive: screenPositive,
      numberOfFish: numberOfFish,
      fatTankPosition: fatTankPosition,
      generation: generation,
      genoType: genotype,
      parentFemale: parentFemale,
      parentMale: parentMale,
      manageSession: manageSession);
      tankList.add(aTank);
}