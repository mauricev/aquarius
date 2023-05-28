// import 'package:aquarium_manager/controllers/aquarium_manager_tanks_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
//
// class MyAquariumManagerQRCodeController extends StatefulWidget {
//   const MyAquariumManagerQRCodeController({Key? key}) : super(key: key);
//
//   @override
//   State<MyAquariumManagerQRCodeController> createState() => _MyAquariumManagerQRCodeControllerState();
// }
//
// class _MyAquariumManagerQRCodeControllerState extends State<MyAquariumManagerQRCodeController> {
//
//   final mobileScannerController = MobileScannerController(
//     formats: [BarcodeFormat.qrCode],
//     detectionSpeed: DetectionSpeed.noDuplicates,
//     facing: CameraFacing.back,
//     torchEnabled: true,
//   );
//
//   Future<void> TransferFromQrCodeToTank(BarcodeCapture capture) async {
//     final List<Barcode> barcodes = capture.barcodes;
//     // for (final barcode in barcodes) {
//     //   debugPrint('Barcode found! ${barcode.rawValue}');
//     // }
//     print("1");
//     await mobileScannerController.stop();
//     print("2");
//     // launch and replace navigation screen (can this go back to the screen before this one?)
//     String? rawValue = barcodes[0].rawValue;
//     List<String> stringParts = rawValue!.split(RegExp('[,;]'));
//
//     if (stringParts.length >= 2) {
//       String rackFk = stringParts[0];
//       String absolutePositionString = stringParts[1];
//       int absolutePosition = int.parse(absolutePositionString);
//
//       Map<String, dynamic> arguments = {
//         'incomingRack_Fk': rackFk,
//         'incomingTankPosition': absolutePositionString,
//       };
//
//       print("the camera rack_fk is ${rackFk}");
//       print("the camera incomingTankPosition is ${absolutePosition}");
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MyAquariumManagerTankController(
//             arguments: {
//               'incomingRack_Fk': rackFk,
//               'incomingTankPosition': absolutePosition,
//             },
//           ),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // can we make this a modal bottom sheet? will the camera take over the whole screen?
//     print("even before before 1");
//     return  MobileScanner(
//         controller: mobileScannerController,
//         onDetect: (capture) {
//           print("before 1");
//           TransferFromQrCodeToTank(capture);
//         },
//       );
//
//   }
// }
