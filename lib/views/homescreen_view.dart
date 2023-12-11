import 'package:aquarius/view_models/tanklines_viewmodel.dart';
import '../view_models/search_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/viewmodel.dart';
import '../views/facilities_view.dart';
import '../view_models/facilities_viewmodel.dart';
import 'search_view.dart';
import 'tanks_view.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../views/utility.dart';
import '../views/consts.dart';
import '../views/login_view.dart';
import '../view_models/tanks_viewmodel.dart';
import '../views/tanklines_view.dart';

class HomeScreenView extends StatefulWidget {
  const HomeScreenView({super.key});

  @override
  State<HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<HomeScreenView> {
  // when the app starts and managesession is initialized, we read from local storage any saved facility
  // we can then assign it to the dropdown and everything else

  void informViewModelsOfTheFacility(BuildContext context) {
    // we are going to tell the other models what the facility is; it has already been selected

    FacilityViewModel facilityViewModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    // this fetches the facility info; it’s async, but we don’t need to await it because we don”t use it here
    // I am passing the facility to itself. How does that make any sense?
    // getFacilityInfo will also be called when a new facility is being created.
    // so we call getFacilityInfo with an empty facility, and that new facility has not been selected
    // another facility may or may not be selected. so getFacilityInfo doesn’t change the
    // selected facility; it just loads up some info on the newly created facility.
    // when the facility dropdown is set selected, then we select the facility and then call this
    // method, which in turn apprises facilityViewModel of the newly selected facility

    facilityViewModel.getFacilityInfo(facilityViewModel.selectedFacility);

    SearchViewModel searchViewModel =
        Provider.of<SearchViewModel>(context, listen: false);

    searchViewModel.setFacilityId(facilityViewModel.selectedFacility!);

    TanksViewModel tanksViewModel =
        Provider.of<TanksViewModel>(context, listen: false);

    tanksViewModel.setFacilityId(facilityViewModel.selectedFacility!);
  }

  Widget facilityDropDown(BuildContext context) {
    FacilityViewModel facilityViewModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    // if we are not null, a facility had been previously selected
    if (facilityViewModel.selectedFacility != null) {
      informViewModelsOfTheFacility(context);
    }

    return FutureBuilder<List<Map<String, String>>>(
      future: facilityViewModel.getFacilityNames2(),
      builder: (BuildContext context,
          AsyncSnapshot<List<Map<String, String>>> snapshot) {
        if (snapshot.hasData) {
          List<DropdownMenuItem<String>> dropdownItems = [];

          // now handles the situation if the saved facility doesn’t match anything in the list
          bool isSelectedValueValid = false;
          String? selectedValue =
              facilityViewModel.selectedFacility;

          for (Map<String, String> item in snapshot.data!) {

            if (selectedValue == item['facility_fk']) isSelectedValueValid = true;

            dropdownItems.add(DropdownMenuItem<String>(
              value: item['facility_fk'],
              child: Text(item['facility_name'].toString()),
            ));
          }

          return DropdownButton<String>(
            value: (isSelectedValueValid) ? selectedValue : null,
            icon: const Icon(Icons.arrow_downward),
            elevation: 16,
            style: const TextStyle(color: Colors.deepPurple),
            underline: Container(
              height: 2,
              color: Colors.deepPurpleAccent,
            ),
            onChanged: (String? value) {
              setState(() {
                if (value != null) {
                  facilityViewModel.setSelectedFacility(
                      value); // this is the document id, not the name itself
                  informViewModelsOfTheFacility(context);
                }
              });
            },
            items: dropdownItems.isNotEmpty
                ? dropdownItems
                : [
                    DropdownMenuItem<String>(
                      value: null,
                      child: const Text('No facility selected'),
                      onTap: () {}, // Disable the "No facility selected" option
                    ),
                  ],
          );
        } else if (snapshot.hasError) {
          // Handle the error state
          return Text('Error: ${snapshot.error}');
        } else {
          // Handle the loading state
          return const CircularProgressIndicator();
        }
      },
    );
  }

  void loadFacilitiesPage(BuildContext context, bool newFacility) {
    FacilityViewModel facilitiesModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    String? whichFacility = facilitiesModel.selectedFacility;

    // if we are creating a new facility, clear out this variable
    if (newFacility == cNewFacility) {
      whichFacility = null;
    }

    facilitiesModel.getFacilityInfo(whichFacility).then((data) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const FacilitiesView()) // this will read from facility model, which has already been updated
          ).then((data) {
        setState(() {
          // does this work?, yes it does; this should trigger the future builder to make a new facilities list
        });
      });
    });
  }

  void loadTanksController(BuildContext context) {
    TanksViewModel tankViewModel =
        Provider.of<TanksViewModel>(context, listen: false);

    TanksLineViewModel tankLinesViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    // TankView depends on having the list of tanks
    tankLinesViewModel.buildTankLinesList().then((data) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TankView(
                  incomingRackFk: null,
                  incomingTankPosition: null,
                  tankViewModelNoContext: tankViewModel, tankLineViewModelNoContext: tankLinesViewModel,))).then((data) {});
    });
  }

  // because of https://dart-lang.github.io/linter/lints/use_build_context_synchronously.html
  // we pass build context and wrap the navigator.push/materialpageroute with
  // WidgetsBinding.instance!.addPostFrameCallback((_)

  // i changed this to use a then construction eliminating the need for async
  // do we still need context to be passed?
  void transferFromQrCodeToTank(BuildContext context2,
      MobileScannerController mobileScannerController, BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    mobileScannerController.stop().then((value) {
      // launch and replace navigation screen (can this go back to the screen before this one?)
      String? rawValue = barcodes[0].rawValue;
      List<String> stringParts = rawValue!.split(RegExp('[;]'));

      if (stringParts.length >= 2) {
        String rackFk = stringParts[0];
        String absolutePositionString = stringParts[1];
        int absolutePosition = int.parse(absolutePositionString);

        TanksViewModel tankViewModel =
            Provider.of<TanksViewModel>(context2, listen: false);

        TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context2, listen: false);

        Navigator.pop(context2);

        // is this still needed?
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TankView(
                incomingRackFk: rackFk,
                incomingTankPosition: absolutePosition,
                tankViewModelNoContext: tankViewModel,
                tankLineViewModelNoContext: tanksLineViewModel,
              ),
            ),
          );
        });
      } else {
        Navigator.pop(context);
      }
    });
  }

  Widget displayCameraForReadingQrCode(BuildContext context) {
    final MobileScannerController mobileScannerController =
        MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: true,
    );

    return MobileScanner(
      controller: mobileScannerController,
      onDetect: (capture) {
        transferFromQrCodeToTank(context, mobileScannerController, capture);
      },
    );
  }

  void loadQRCodeController(BuildContext context) {
    // I am not sure why I am selecting the facility here; it had to have been set by the dropdown
    // plus why do we need all that info loaded here
    // facilitiesModel.getFacilityInfo(facilitiesModel.selectedFacility).then((data) {
    // are we wrong to assume this will be filled in?
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return displayCameraForReadingQrCode(context);
      },
    );
    //});
  }

  void loadSearchController(BuildContext context) {
    SearchViewModel searchModel =
        Provider.of<SearchViewModel>(context, listen: false);

    TanksLineViewModel tankLinesViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    // SearchViewModel needs the tanklines of the current facility
    // so it needs TanksLineViewModel to build the mapping of the facility’s tanks to the tanklines
    tankLinesViewModel.buildTankLinesList().then((data) {
      searchModel.buildInitialSearchList(tankLinesViewModel).then((data) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const SearchView())
            );
      });
    });
  }

  void loadTankLinesView(BuildContext context) {
    TanksLineViewModel tankLinesViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    tankLinesViewModel.buildTankLinesList().then((data) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TankslineView()),
      );
    });
  }

  void logoutController(BuildContext context) {
    AquariusViewModel model =
        Provider.of<AquariusViewModel>(context, listen: false);

    Future<dynamic> result = model.logOut();
    result.then((response) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginView(),
        ),
      );
    });
  }

  Widget loadCommonButton(
      BuildContext context,
      void Function(BuildContext) loadController,
      bool Function() enableOnPressed,
      String buttonTitle) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 60,
      ),
      child: ElevatedButton(
        onPressed: enableOnPressed()
            ? () {
                // if we return true, then enable the button; for new facility must return true
                loadController(context);
              }
            : null,
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(
            const Size(200, 50),
          ),
        ),
        child: Text(buttonTitle),
      ),
    );
  }

  Widget loadCommonButtonWithParameter(
      BuildContext context,
      bool controllerState,
      void Function(BuildContext, bool) loadController,
      bool Function() disableOnPressed,
      String buttonTitle) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 60,
      ),
      child: ElevatedButton(
        // if disableOnPressed is true, then
        onPressed: disableOnPressed()
            ? () {
                loadController(context, controllerState);
              }
            : null,
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(
            const Size(200, 50),
          ),
        ),
        child: Text(buttonTitle),
      ),
    );
  }

  // we already have a scaffold created in the main body
  Widget buildHomeScreen(BuildContext context) {
    FacilityViewModel facilityViewModel =
        Provider.of<FacilityViewModel>(context, listen: true);

    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                top: 20,
              ),
              child: Text(
                "Selected Facility for some associated tasks below:",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            facilityDropDown(context),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        buildOuterLabelHeadlineSmall(context, "Create"),
        Row(
          children: [
            loadCommonButtonWithParameter(
                context,
                cNewFacility,
                loadFacilitiesPage,
                facilityViewModel.pretendFacilityIsAlwaysSelected,
                "New Facility…"),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        buildOuterLabelHeadlineSmall(context, "Manage"),
        Row(
          children: [
            loadCommonButtonWithParameter(
                context,
                cNotANewFacility,
                loadFacilitiesPage,
                facilityViewModel.isAFacilitySelected,
                "Facility…"),
            loadCommonButton(context, loadTanksController,
                facilityViewModel.isAFacilitySelected, "Tanks…"),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        buildOuterLabelHeadlineSmall(context, "Search"),
        Row(
          children: [
            // we might want to add an indent value to align this button with the above
            // we the button for loadQRCodeController to be enabled only if a facility is selected
            // and we are on ios, new function isAFacilitySelectedAndOnIos
            loadCommonButton(
                context,
                loadQRCodeController,
                facilityViewModel.isAFacilitySelectedAndOnIos,
                "Scan a Tank’s Barcode…"),
            loadCommonButton(context, loadSearchController,
                facilityViewModel.isAFacilitySelected, "Search For a Tank…"),
          ],
        ),
        buildOuterLabelHeadlineSmall(context, "TankLines"),
        Row(
          children: [
            loadCommonButton(context, loadTankLinesView,
                facilityViewModel.pretendFacilityIsIrrelevant, "Tanklines"),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 150.0),
          child: Row(
            children: [
              // we might want to add an indent value to align this button with the above
              loadCommonButton(context, logoutController,
                  facilityViewModel.isAFacilitySelected, "Logout"),
            ],
          ),
        ),
      ],
    );
  }

  void showVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            },
          child: const AlertDialog(
            title: Center(child: Text(kProgramName)),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Version $kVersion"),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: () {
            showVersionDialog(context);
          },
          child: const Text(
            kProgramName,
            style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: buildHomeScreen(context),
    );
  }

  // Widget build(BuildContext context) {
  //   return buildHomeScreen(context);
  // }
}
