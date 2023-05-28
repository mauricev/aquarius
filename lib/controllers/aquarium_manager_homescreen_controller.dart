import 'package:aquarium_manager/controllers/aquarium_manager_qrcode_controller.dart';
import 'package:aquarium_manager/model/aquarium_manager_search_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/aquarium_manager_model.dart';
import 'aquarium_manager_facilities_controller.dart';
import '../model/aquarium_manager_facilities_model.dart';

import 'aquarium_manager_search_controller.dart';

import 'aquarium_manager_tanks_controller.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../views/utility.dart';

class AquariumManagerHomeScreenController extends StatefulWidget {
  const AquariumManagerHomeScreenController({Key? key}) : super(key: key);

  @override
  State<AquariumManagerHomeScreenController> createState() =>
      _AquariumManagerHomeScreenControllerState();
}

class _AquariumManagerHomeScreenControllerState
    extends State<AquariumManagerHomeScreenController> {
  final cNotANewFacility = false;
  final cNewFacility = true;

  Widget facilityDropDown(BuildContext context) {
    MyAquariumManagerModel model =
        Provider.of<MyAquariumManagerModel>(context, listen: false);

    return FutureBuilder(
        future: model.getFacilityNames(), // we return this as a future
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? Container(
                  child: DropdownButton<String>(
                    value: snapshot.data.contains(model.selectedFacility)
                        ? model.selectedFacility
                        : null,
                    icon: const Icon(Icons.arrow_downward),
                    elevation: 16,
                    style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (String? value) {
                      setState(() {
                        print("is setstate even being called");
                        if (snapshot.data.contains(value)) {
                          model.setSelectedFacility(value!);
                        } else if (snapshot.data.isNotEmpty) {
                          model.setSelectedFacility(snapshot.data.first);
                          print("do we come here");
                        } else {
                          model.setSelectedFacility(null);
                        }
                      });
                    },
                    items: snapshot.data.map<DropdownMenuItem<String>>((value) {
                      print(value.runtimeType);
                      // we could append the data here to our data structure, item by item
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                )
              : Container();
        });
  }

  void loadFacilitiesPage(BuildContext context, bool newFacility) {
    MyAquariumManagerModel model =
        Provider.of<MyAquariumManagerModel>(context, listen: false);

    MyAquariumManagerFacilityModel facilitiesModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

    String? whichFacility = model.selectedFacility;
    if (newFacility == cNewFacility) {
      whichFacility = null;
    }

    facilitiesModel.getFacilityInfo(whichFacility).then((data) {
      // are we wrong to assume this will be filled in?
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MyAquariumManagerFacilitiesController()) // this will read from facility model, which has already been updated
          ).then((data) {});
    });
  }

  void loadTanksController(BuildContext context) {
    MyAquariumManagerModel model =
        Provider.of<MyAquariumManagerModel>(context, listen: false);

    MyAquariumManagerFacilityModel facilitiesModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

    facilitiesModel.getFacilityInfo(model.selectedFacility).then((data) {
      // are we wrong to assume this will be filled in?
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyAquariumManagerTankController(
                    arguments: {
                      'incomingRack_Fk': null,
                      'incomingTankPosition': null,
                    },
                  )) // this will read from facility model, which has already been updated
          ).then((data) {});
    });
  }

  // because of https://dart-lang.github.io/linter/lints/use_build_context_synchronously.html
  // we pass build context and wrap the navigator.push/materialpageroute with
  // WidgetsBinding.instance!.addPostFrameCallback((_)
  Future<void> TransferFromQrCodeToTank(BuildContext context2, MobileScannerController mobileScannerController, BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;

    await mobileScannerController.stop();

    // launch and replace navigation screen (can this go back to the screen before this one?)
    String? rawValue = barcodes[0].rawValue;
    List<String> stringParts = rawValue!.split(RegExp('[;]'));

    if (stringParts.length >= 2) {
      String rackFk = stringParts[0];
      String absolutePositionString = stringParts[1];
      int absolutePosition = int.parse(absolutePositionString);

      Navigator.pop(context2);
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyAquariumManagerTankController(
              arguments: {
                'incomingRack_Fk': rackFk,
                'incomingTankPosition': absolutePosition,
              },
            ),
          ),
        );
      });
    } else Navigator.pop(context);
  }

  Widget DisplayCameraForReadingQrCode(BuildContext context) {
    final MobileScannerController mobileScannerController = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: true,
    );

    return MobileScanner(
      controller: mobileScannerController,
      onDetect: (capture) {
        TransferFromQrCodeToTank(context,mobileScannerController, capture);
      },
    );
  }

  void loadQRCodeController(BuildContext context) {
    MyAquariumManagerModel model =
        Provider.of<MyAquariumManagerModel>(context, listen: false);

    MyAquariumManagerFacilityModel facilitiesModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

    MyAquariumManagerSearchModel searchModel =
        Provider.of<MyAquariumManagerSearchModel>(context, listen: false);

    facilitiesModel.getFacilityInfo(model.selectedFacility).then((data) {
      // are we wrong to assume this will be filled in?
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return DisplayCameraForReadingQrCode(context);
        },
      );
    });
  }

  void loadSearchController(BuildContext context) {
    MyAquariumManagerModel model =
        Provider.of<MyAquariumManagerModel>(context, listen: false);

    MyAquariumManagerFacilityModel facilitiesModel =
        Provider.of<MyAquariumManagerFacilityModel>(context, listen: false);

    MyAquariumManagerSearchModel searchModel =
        Provider.of<MyAquariumManagerSearchModel>(context, listen: false);

    facilitiesModel.getFacilityInfo(model.selectedFacility).then((data) {
      // are we wrong to assume this will be filled in?
      searchModel
          .buildInitialSearchList(facilitiesModel.document_id)
          .then((data) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    MyAquariumManagerSearchController()) // this will read from facility model, which has already been updated
            );
      });
    });
  }

  Widget loadCommonButton(BuildContext context,
      void Function(BuildContext) loadController, String buttonTitle) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 60,
      ),
      child: ElevatedButton(
        onPressed: () {
          loadController(context);
        },
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(
            Size(200, 50),
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
      String buttonTitle) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 160,
      ),
      child: ElevatedButton(
        onPressed: () {
          loadController(context, controllerState);
        },
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(
            Size(200, 50),
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
          SizedBox(
            height: 20,
          ),
          BuildOuterLabel_HeadlineSmall(context, "Create"),
          Row(
            children: [
              loadCommonButtonWithParameter(
                  context, cNewFacility, loadFacilitiesPage, "New Facility…"),
            ],
          ),
          SizedBox(
            height: 30,
          ),
          BuildOuterLabel_HeadlineSmall(context, "Manage"),
          Row(
            children: [
              loadCommonButtonWithParameter(
                  context, cNotANewFacility, loadFacilitiesPage, "Facility…"),
              loadCommonButton(
                  context, loadTanksController, "Tanks…"),
            ],
          ),
          SizedBox(
            height: 30,
          ),
          BuildOuterLabel_HeadlineSmall(context, "Search"),
          Row(
            children: [
              // we might want to add an indent value to align this button with the above
              loadCommonButton(
                  context, loadQRCodeController, "Scan a Tank’s Barcode…"),
              loadCommonButton(
                  context, loadSearchController, "Search For a Tank…"),
            ],
          ),
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    return buildHomeScreen(context);
  }
}
