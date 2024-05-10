import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../view_models/tanks_viewmodel.dart';
import '../view_models/facilities_stream_controller.dart';
import 'package:aquarius/view_models/tankitems_viewmodel.dart';
import 'package:provider/provider.dart';
import '../view_models/facilities_viewmodel.dart';
import 'tanks_view.dart';
import '../views/utility.dart';

class ScannerView extends StatefulWidget {
  final MobileScannerController mobileScannerController =
      MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: true,
  );

  ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  @override
  void dispose() {
    widget.mobileScannerController.dispose();
    super.dispose();
  }

  void jumpToTheTank(String tankDocumentId) {
    TanksLiveViewModel tankLiveViewModel =
        Provider.of<TanksLiveViewModel>(context, listen: false);

    TanksLineViewModel tanksLineViewModel =
        Provider.of<TanksLineViewModel>(context, listen: false);

    FacilityViewModel facilitiesModel =
        Provider.of<FacilityViewModel>(context, listen: false);

    tankLiveViewModel
        .findTankLocationInfoByID(tankDocumentId)
        .then((theTankMap) {
      facilitiesModel.setSelectedFacility(theTankMap!['facility_fk']);
      informViewModelsOfTheFacility(context);
      facilityStreamController.add("update"); // this should trigger a rebuild

      // remove the window holding the MobileScanner
      Navigator.pop(context);

      // is this still needed? There is no longer an async gap
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TankView(
            incomingRackFk: theTankMap['rack_fk'],
            incomingTankPosition: theTankMap['absolute_position'],
            tankLiveViewModelNoContext: tankLiveViewModel,
            tankLineViewModelNoContext: tanksLineViewModel,
            facilityViewModelNoContext: facilitiesModel,
          ),
        ),
      );
      // });
    }).catchError((error) { // if the user scans an older qr code that specifies rack and tank location rather than tank document id
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Something went wrong."),
            content: const Text("I can’t find this tank. Might this be an older QR code?"),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  void transferFromQrCodeToTank(
      MobileScannerController mobileScannerController, BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    mobileScannerController.stop().then((value) {
      // launch and replace navigation screen (can this go back to the screen before this one?)
      String? rawValue = barcodes[0].rawValue;
      if (rawValue != null) {
        String tankDocumentId = rawValue;
        jumpToTheTank(tankDocumentId);
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: widget.mobileScannerController,
      onDetect: (capture) {
        transferFromQrCodeToTank(widget.mobileScannerController, capture);
      },
    );
  }
}
