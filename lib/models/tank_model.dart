import '../view_models/session_key.dart';
import '../models/notes_model.dart';
import '../views/utility.dart';
import '../views/consts.dart';

class Tank {
  String? documentId = "bad value"; // this should never say this
  final String? facilityFk;
  String rackFk;
  int absolutePosition;
  String tankLineDocId;
  int? birthDate;
  bool? screenPositive;
  int? numberOfFish;
  int? fatTankPosition;
  int? generation;
  String? genoType;
  String? parentFemale;
  String? parentMale;
  int? euthanizedDate;
  final ManageSession manageSession;
  late final Notes notes;
  Tank({
    this.documentId,
    required this.facilityFk,
    required this.rackFk,
    required this.absolutePosition,
    this.tankLineDocId = cTankLineValueNotYetAssigned,
    int? birthDate,
    this.screenPositive,
    this.numberOfFish,
    this.fatTankPosition,
    this.generation,
    this.genoType,
    this.parentFemale,
    this.parentMale,
    this.euthanizedDate,
    required this.manageSession,
  }) : birthDate = birthDate ?? returnTimeNow() {
    notes = createNotes();
    notes.loadNotes();
  }

  Notes createNotes() {
    return Notes(parentTank: this, manageSession: manageSession);
  }

  void parkIt() {
    absolutePosition = cParkedRackAbsPosition;
    rackFk = cParkedRackFkAddress;
    // fat tanks stay fat, but have no virtual partner while they are parked
    if (fatTankPosition != null) {
      fatTankPosition = 0;
    }
  }

  void assignTankNewLocation(String rackIdentifier, int position) {
    absolutePosition = position;
    rackFk = rackIdentifier;
    // fat tanks get a new virtual partner
    // we need to know if fatTankPosition has a valid value when it’s a parked tank
    if (fatTankPosition != null) {
      fatTankPosition = position + 1;
    }
  }

  void updateTankDocumentId (String tankFk) {
    documentId = tankFk;
  }

  void setScreenPositive (bool newScreenPositiveValue) {
    screenPositive = newScreenPositiveValue;
  }

  bool getSmallTank() {
    return (fatTankPosition == null);
  }

  bool? getScreenPositive() {
    return screenPositive;
  }

  int? getBirthDate() {
    return birthDate;
  }

  void setBirthDate(int newBirthDateValue) {
    birthDate = newBirthDateValue;
  }

  int? getNumberOfFish() {
    return numberOfFish;
  }

  String? getGenoType() {
    return genoType;
  }
}