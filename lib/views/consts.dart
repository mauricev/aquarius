const int kGridHSize = 650;
const int kGridVSize = 500;
const String kProgramName = 'Aquarius';

const int cParkedRackAbsPosition = -2;
const String cParkedRackFkAddress = "0";

// this will change for local, real-world output
// 1 of 3
const String kIPAddress = 'http://192.168.1.91/v1';
//const String kIPAddress = 'https://aquarius-at-peredalab.org/v1';

//local
// 2 of 3
const String kProjectId = '6477fda3e6695f938f0d';

//real-world
//const String kProjectId = '648fc20504d0ed7a089d';

// set to true or false accordingly
// 3 of 3
const kRunningLocal = true;

const String kDatabaseId = '63eefc50e6d7b0cb4c4e';
// we don’t use this; the user selects the facility by name in the dropdown
// we look up the id and store that

// the kFacilityCollection is NOT the same as the document id of the facility document id
const String kFacilityCollection = "63eefc630814627ea850";
const String cRackCollection = '63f97b76c200d9237cea';
const String cTankCollection = '6408223c577dec6908e7';
const String cNotesCollection = '64239dc4f03b6125e61d';

const double kFullWidth = 200;
const double kHalfWidth  = 100;
const double kNumberWidth = 50;
const double kIndentWidth = 20.0;

const double kGridSize = 200;

enum TankStringsEnum { tankLine, numberOfFish, generation, docId }

const int kStandardTextWidth = 75;
const double kStandardTextWidthDouble = 75;

const int kNoRackSelected = -2;
const int cParkedAbsolutePosition = -2;

const int kEmptyTankIndex = -1;

const int kStartingYear = 2021;
const int kStartingMonth = 1;
const int kEndingYear = 2024;

//const int kStartingDOBOffset = 66000000000; // Calculated the default DOB by subtracting this value (a little over 2 years) from the current date.

const int cTankLineSearch = 1;
const int cCrossBreedSearch = 2;
const int kCrossBreedTime = 15552000000; // new value at 180 days; 15774336000 was the old value
const int kDayInMilliseconds = 86400000;

const bool cNotify = true;
const bool cNoNotify = false;

const String cThinTank = "3L";
const String cFatTank = "10L";

const cNotANewFacility = false;
const cNewFacility = true;