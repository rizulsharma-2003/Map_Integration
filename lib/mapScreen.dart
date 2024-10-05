import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import 'google_places_flutter.dart';
import 'model/prediction.dart';

class mapScreen extends StatefulWidget {
  const mapScreen({Key? key}) : super(key: key);

  @override
  _mapScreenState createState() => _mapScreenState();
}

class _mapScreenState extends State<mapScreen> with SingleTickerProviderStateMixin {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  LatLng? _destinationLocation; // Default location
  bool _isPermissionGranted = false;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  TextEditingController _fromController = TextEditingController(); // For "From" field
  TextEditingController _toController = TextEditingController();   // For "To" field
  late AnimationController _animationController;

  static const String _apiKey = 'AIzaSyDO8ZayxOthLcRSQeTqqz8molJwLdS2cQ0'; // Replace with your API key

  MapType _currentMapType = MapType.normal; // Default map type

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _requestLocationPermission();
  }

  // Method to toggle map type
  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.terrain;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }



  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      await _getCurrentLocation();
      _addMarkers();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Location location = Location();
      var currentLocationData = await location.getLocation();
      setState(() {
        _currentLocation = LatLng(currentLocationData.latitude!, currentLocationData.longitude!);
      });

      // Add the current location marker and update camera position
      if (_currentLocation != null) {
        mapController.moveCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 14.0));
        _addMarkers();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _setupPolylines() async {
    if (_currentLocation == null || _destinationLocation == null) return;

    final originString = 'origin=${_currentLocation!.latitude},${_currentLocation!.longitude}';
    final destString = 'destination=${_destinationLocation!.latitude},${_destinationLocation!.longitude}';

    final drivingPolyline = await _fetchPolyline('$originString&$destString&mode=driving&key=$_apiKey');
    if (drivingPolyline != null) {
      setState(() {
        _polylines.clear(); // Clear old polylines
        _polylines.add(
          Polyline(
            polylineId: PolylineId('driving_polyline'),
            visible: true,
            points: drivingPolyline,
            color: Colors.blue,
            width: 5,
          ),
        );
      });
    }
  }

  Future<List<LatLng>?> _fetchPolyline(String url) async {
    try {
      final response = await http.get(Uri.parse('https://maps.googleapis.com/maps/api/directions/json?$url'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'].isNotEmpty) {
          final encodedPolyline = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(encodedPolyline);
        }
      } else {
        print('Failed to fetch polyline. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching polyline: $e');
    }
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng((lat / 1E5), (lng / 1E5)));
    }

    return polyline;
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      }
    } else {
      print('Failed to fetch location. Status code: ${response.statusCode}');
    }
    return null;
  }

  void _addMarkers() {
    setState(() {
      _markers.clear();

      // Marker for current location
      if (_currentLocation != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('origin'),
            position: _currentLocation!,
            infoWindow: InfoWindow(
              title: 'Your Location',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Custom color for current location
          ),
        );
      }

      // Marker for destination location
      if (_destinationLocation != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: _destinationLocation!,
            infoWindow: InfoWindow(
              title: 'Destination',
            ),
          ),
        );
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (_currentLocation != null) {
      mapController.moveCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 14.0));
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text('Location permission is required to use this feature.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget placesAutoCompleteTextField(TextEditingController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: controller,
        googleAPIKey: _apiKey,
        inputDecoration: InputDecoration(
          hintText: "Search your location",
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        debounceTime: 400,
        countries: ["in"],
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          print("placeDetails" + prediction.lat.toString());
        },
        itemClick: (Prediction prediction) {
          controller.text = prediction.description ?? "";
          controller.selection = TextSelection.fromPosition(
              TextPosition(offset: prediction.description?.length ?? 0));
        },
        seperatedBuilder: Divider(),
        containerHorizontalPadding: 10,
        itemBuilder: (context, index, Prediction prediction) {
          return Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.location_on),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prediction.description ?? ""),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: _polylines,
            mapType: _currentMapType, // Use the current map type
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? LatLng(28.7041, 77.1025), // Default to New Delhi if no location
              zoom: 14,
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              // padding: EdgeInsets.symmetric(horizontal: 16.0),  // Adding padding for a cleaner look
              child: Column(
                children: [
                  Container(
                    width: double.infinity,  // Makes the container span full width
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),  // Optional: Rounded corners
                      border: Border.all(color: Colors.grey.shade300),  // Optional: Adding border for a defined look
                    ),
                    child: placesAutoCompleteTextField(_fromController),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,  // Makes the container span full width
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),  // Optional: Rounded corners
                      border: Border.all(color: Colors.grey.shade300),  // Optional: Adding border for a defined look
                    ),
                    child: placesAutoCompleteTextField(_toController),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80, // Adjust position for the button
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _toggleMapType,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Change Map Type'),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                final fromAddress = _fromController.text;
                final toAddress = _toController.text;

                if (fromAddress.isNotEmpty && toAddress.isNotEmpty) {
                  _currentLocation = await _getLatLngFromAddress(fromAddress);
                  _destinationLocation = await _getLatLngFromAddress(toAddress);
                  _addMarkers();
                  await _setupPolylines();

                  // Move the camera to the current location and set the zoom level
                  if (_currentLocation != null) {
                    mapController.moveCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 14.0));
                  }
                } else {
                  print('Please enter valid From and To locations');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,  // Button background color
                foregroundColor: Colors.white,  // Button text (foreground) color
                padding: EdgeInsets.symmetric(vertical: 16),  // Optional: Adjust padding for button height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),  // Optional: Border radius for rounded corners
                ),
              ),
              child: Text('Show Direction'),
            ),
          ),
        ],
      ),
    );
  }
}
