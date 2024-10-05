import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:khadima/mapScreen.dart';
// import 'package:khadima/payment_screen.dart';
// import 'package:khadima/screens/aadharcard_number.dart';
// import 'package:khadima/screens/checkoutpage.dart';
// import 'package:khadima/screens/licence_dob.dart';
// import 'package:khadima/screens/pan_card_photo.dart';
// import 'package:khadima/screens/vehicle_insurance_photo.dart';
// import 'package:khadima/screens/vehicle_permit_photo.dart';
// import 'package:khadima/screens/vehicle_rc_photo.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Example',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: mapScreen(),
    );
  }
}

// class MainScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Main Screen'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => AttendanceScreen()),
//             );
//           },
//           child: Text('Go to Attendance Screen'),
//         ),
//       ),
//     );
//   }
// }
//
