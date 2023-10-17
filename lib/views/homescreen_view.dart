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

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class HomeScreenView extends StatefulWidget {
  const HomeScreenView({Key? key}) : super(key: key);

  @override
  State<HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<HomeScreenView> {
  final cNotANewFacility = false;
  final cNewFacility = true;

  Widget facilityDropDown(BuildContext context) {
    AquariusViewModel model =
        Provider.of<AquariusViewModel>(context, listen: false);

    // can we set the facility here?
    if (model.selectedFacility != null) {
      FacilityViewModel facilityViewModel =
      Provider.of<FacilityViewModel>(context, listen: false);
      facilityViewModel.getFacilityInfo(model.selectedFacility);
    }

    return FutureBuilder<List<Map<String, String>>>(
      future: model.getFacilityNames2(),
      builder: (BuildContext context,
          AsyncSnapshot<List<Map<String, String>>> snapshot) {
        if (snapshot.hasData) {
          List<DropdownMenuItem<String>> dropdownItems = [];

          for (Map<String, String> item in snapshot.data!) {
            dropdownItems.add(DropdownMenuItem<String>(
              value: item['facility_fk'],
              child: Text(item['facility_name'].toString()),
            ));
          }

          String? selectedValue = model.selectedFacility; // what if this is null?

          return DropdownButton<String>(
            value: selectedValue,
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
                  model.setSelectedFacility(
                      value); // this is the document id, not the name itself
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
    AquariusViewModel model =
        Provider.of<AquariusViewModel>(context, listen: false);

    FacilityViewModel facilitiesModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    String? whichFacility = model.selectedFacility;
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
          // does this work?, yes it does
        });
      });
    });
  }

  void loadTanksController(BuildContext context) {

    TanksViewModel tankViewModel =
    Provider.of<TanksViewModel>(context, listen: false);
    tankViewModel.setFacilityId(extractFacilityId(context));

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const TankView(
                    arguments: {
                      'incomingRack_Fk': null,
                      'incomingTankPosition': null,
                    },
                  ))
          ).then((data) {});
  }

  // because of https://dart-lang.github.io/linter/lints/use_build_context_synchronously.html
  // we pass build context and wrap the navigator.push/materialpageroute with
  // WidgetsBinding.instance!.addPostFrameCallback((_)
  Future<void> transferFromQrCodeToTank(
      BuildContext context2,
      MobileScannerController mobileScannerController,
      BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;

    await mobileScannerController.stop();

    // launch and replace navigation screen (can this go back to the screen before this one?)
    String? rawValue = barcodes[0].rawValue;
    List<String> stringParts = rawValue!.split(RegExp('[;]'));

    if (stringParts.length >= 2) {
      String rackFk = stringParts[0];
      String absolutePositionString = stringParts[1];
      int absolutePosition = int.parse(absolutePositionString);

      TanksViewModel tankViewModel =
      Provider.of<TanksViewModel>(context2, listen: false);
      tankViewModel.setFacilityId(extractFacilityId(context2));

      Navigator.pop(context2);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TankView(
              arguments: {
                'incomingRack_Fk': rackFk,
                'incomingTankPosition': absolutePosition,
              },
            ),
          ),
        );
      });
    } else {
      Navigator.pop(context);
    }
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
    AquariusViewModel model =
        Provider.of<AquariusViewModel>(context, listen: false);

    FacilityViewModel facilitiesModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    facilitiesModel.getFacilityInfo(model.selectedFacility).then((data) {
      // are we wrong to assume this will be filled in?
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return displayCameraForReadingQrCode(context);
        },
      );
    });
  }

  void loadSearchController(BuildContext context) {
    SearchViewModel searchModel =
        Provider.of<SearchViewModel>(context, listen: false);

    searchModel.buildInitialSearchList(extractFacilityId(context)).then((data) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const SearchView()) // this will read from facility model, which has already been updated
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

  bool isAFacilitySelectedAndOnIos(BuildContext context) {
    AquariusViewModel model =
        Provider.of<AquariusViewModel>(context, listen: false);

    return (model.returnSelectedFacility() != null) &
        (defaultTargetPlatform == TargetPlatform.iOS);
  }

  bool isAFacilitySelected(BuildContext context) {
    AquariusViewModel model =
        Provider.of<AquariusViewModel>(context, listen: false);

    return model.returnSelectedFacility() != null;
  }

  bool pretendFacilityIsAlwaysSelected(BuildContext context) {
    AquariusViewModel model =
        Provider.of<AquariusViewModel>(context, listen: false);

    return model.returnSelectedFacility() ==
        null; // if a facility is not selected, return true
  }

  Widget loadCommonButton(
      BuildContext context,
      void Function(BuildContext) loadController,
      bool Function(BuildContext) enableOnPressed,
      String buttonTitle) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 60,
      ),
      child: ElevatedButton(
        onPressed: enableOnPressed(context)
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
      bool Function(BuildContext) disableOnPressed,
      String buttonTitle) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 160,
      ),
      child: ElevatedButton(
        // if disableOnPressed is true, then
        onPressed: disableOnPressed(context)
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
                "Selected Facility for associated tasks below:",
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
                pretendFacilityIsAlwaysSelected,
                "New Facility…"),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        buildOuterLabelHeadlineSmall(context, "Manage"),
        Row(
          children: [
            loadCommonButtonWithParameter(context, cNotANewFacility,
                loadFacilitiesPage, isAFacilitySelected, "Facility…"),
            loadCommonButton(
                context, loadTanksController, isAFacilitySelected, "Tanks…"),
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
            loadCommonButton(context, loadQRCodeController,
                isAFacilitySelectedAndOnIos, "Scan a Tank’s Barcode…"),
            loadCommonButton(context, loadSearchController, isAFacilitySelected,
                "Search For a Tank…"),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        Row(
          children: [
            // we might want to add an indent value to align this button with the above
            loadCommonButton(
                context, logoutController, isAFacilitySelected, "Logout"),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kProgramName),
      ),
      body: buildHomeScreen(context),
    );
  }

  // Widget build(BuildContext context) {
  //   return buildHomeScreen(context);
  // }
}
