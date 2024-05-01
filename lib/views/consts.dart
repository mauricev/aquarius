const int kGridFullHSize = 650;
const int kGridDialogHSize = 590;
const int kGridVSize = 500;
const String kProgramName = 'Aquarius';
const String kVersion = "3.2.0";

const int cParkedRackAbsPosition = -2;
const String cParkedRackFkAddress = "0";

// this will change for local, real-world output
// 1 of 5
//const String kIPAddress = 'http://192.168.1.91:8080/v1';
const String kIPAddress = 'https://aquarius-appwrite-at-peredalab.org/v1';

//local
// 2 of 5
//const String kProjectId = '6477fda3e6695f938f0d';

//real-world
const String kProjectId = '648fc20504d0ed7a089d';

// set to true or false accordingly
// 3 of 5
//const kRunningLocal = true;
const kRunningLocal = false;

// 4 of 5, zebra printing
// 5 of 5, main (window code for iPad, but disable for web)

const String kDatabaseId = '63eefc50e6d7b0cb4c4e';

// the kFacilityCollection is NOT the same as the document id of the facility document id
const String kFacilityCollection = "63eefc630814627ea850";
const String cRackCollection = '63f97b76c200d9237cea';
const String cTankCollection = '6408223c577dec6908e7';
const String cNotesCollection = '64239dc4f03b6125e61d';
const String cTankLinesCollection = '6563c50e67141c771cc2';
const String cGenoTypeCollection = "65e95407dda8f5538dd4";

const double kFullWidth = 200;
const double kHalfWidth  = 100;
const double kNumberWidth = 50;
const double kIndentWidth = 20.0;

const double kGridSize = 170;

enum TankStringsEnum { tankLine, numberOfFish, generation, genotype, parentMale, parentFemale }

const cTopEntrance = 1;
const cBottomEntrance = 2;

// for facilities, the grid itself should always remain editable
// the tank screen displays the grid, but is selectable and only for text with racks
//const cFacilityEditableGrid = false; // tankMode is false
//const cFacilityClickableGrid =
//true; // tankMode is true; we are on the tank page
enum FacilityEditState { editable, readonlyMainScreen, readonlyDialog }

const int kStandardTextWidth = 75;
const double kStandardTextWidthDouble = 75;

const int cParkedAbsolutePosition = -2;
const int kNoRackSelected = -2;
const int kEmptyTankIndex = -1;

const int kStartingYear = 2021;
const int kStartingMonth = 1;

//const int kStartingDOBOffset = 66000000000; // Calculated the default DOB by subtracting this value (a little over 2 years) from the current date.

const int cTankLineSearch = 1;
const int cCrossBreedSearch = 2;

const int cEditTankMode = 1;
const int cDeleteTankMode = 2;

const int kCrossBreedTime = 15552000000; // new value at 180 days; 15774336000 was the old value
const int kDayInMilliseconds = 86400000;

const bool cNotify = true;
const bool cNoNotify = false;

const String cThinTank = "3L";
const String cFatTank = "10L";

const cNotANewFacility = false;
const cNewFacility = true;

const String cFacilityNameKey = "faciltyNameKey";
const String cParkedTankFacility = "no associated facility";

const int cNewTankItem = -1;
const int cInvalidTankItem = -1;
const bool cTankItemNotInUse = false;

const bool cTankItemToBeEdited = false;
const bool cTankItemToBeCreated = true;
const bool cTankItemDialogCancelled = false;
const bool cTankItemDialogOKed = true;
enum TankItemStatusEnum { eTankItemBlank, eTankItemInUse, eTankItemReadyToEdit }

const String cEuthanizeTank = 'euthanize';
const String cDeleteTank = 'delete';

const String cTankLineValueNotYetAssigned = "not yet assigned"; // value is document id
const String cTankLineLabelNotYetAssigned = ""; // label actual tank line text

const String cGenoTypeValueNotYetAssigned = "not yet assigned"; // value is document id
const String cGenoTypeLabelNotYetAssigned = ""; // label actual tank line text

const int cTankItemMaxLength = 60;
const int cNoFishSelected = 0;

const double stdLeftIndent = 40;

const String cGenoTypeNotSpecified = "genotype not specified";

enum TankItemType {eTankLine, eGenoType }

const String cCreateTankLines = "Create Tanklines";
const String cCreateGenoTypes = "Add Genotypes";

const String cCreateNewTankLines = "Create New Tankline…";
const String cCreateNewGenoTypes = "Create New Genotype…";

const String cNewTankLine = 'New Tankline';
const String cNewGenotype = 'New Genotype';

const String cEditTankLines = "Edit TankLines";
const String cEditGenotypes = "Edit Genotypes";

const String cEditTankLine = "Edit TankLine";
const String cEditGenotype = "Edit Genotype";

const String cModifyTankLine = "Tanklines (tap to modify)";
const String cModifyGenotype = "Genotypes (tap to modify)";

const String cDeleteTankLines = "Delete TankLines";
const String cDeleteGenotypes = "Delete Genotypes";

const String cDeleteTankLine = "Delete TankLine";
const String cDeleteGenotype = "Delete Genotype";

const String cTankLineInUse = 'This TankLine is in Use';
const String cGenoTypeInUse = 'This Genotype is in Use';

const String cTankLineCantBeBlank = "Tankline can’t be blank";
const String cGenoTypeCantBeBlank = "Genotype can’t be blank";

const String cTankLineExisting = "That’s an existing tankline";
const String cGenoTypeExisting = "That’s an existing genotype";