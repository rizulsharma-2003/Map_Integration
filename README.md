## Map Screen - Flutter Application
This Flutter application displays a Google Map with functionalities such as retrieving the user's current location, entering a starting and destination location via autocomplete, and displaying directions on the map. The app also includes map type toggling (normal, satellite, terrain).

## Features
Google Maps Integration:
Displays a map with the user's current location.
Dynamically moves the camera to the current location.
Uses markers to show the current and destination locations on the map.
Google Places Autocomplete:

## Users can enter the "From" and "To" locations using an autocomplete text field integrated with the Google Places API.
Polyline Drawing for Directions:

## Draws a polyline from the origin (current location) to the destination.
## Fetches route data from Google Directions API.
## Location and Map Permissions:

## Requests location permission from the user.
Handles permission denial with a pop-up dialog.
Map Type Toggle:

## Allows the user to toggle between normal, satellite, and terrain map types.
Prerequisites
APIs and Libraries
Google Maps API Key:

## Replace the _apiKey in the code with your own Google Maps API key.
Ensure that you have enabled the following APIs in the Google Cloud Console:
Google Maps SDK for Android
Google Maps SDK for iOS
Google Places API
Google Directions API


## You also need a custom google_places_flutter.dart file for handling the autocomplete field, along with a model for handling predictions.

## Setup and Configuration
Enable Permissions: Ensure that you have added the required permissions to your AndroidManifest.xml file (for Android):


## For iOS, you will need to modify your Info.plist:


## Displays the current location.
## Shows markers for the origin and destination.
## Shows a polyline for the route.
## Autocomplete Text Fields:

## The placesAutoCompleteTextField widget provides a search bar for entering and selecting locations.

## Directions Setup:
_fetchPolyline: Fetches the polyline for the route between two locations using the Google Directions API.
_setupPolylines: Calls _fetchPolyline and draws the polyline on the map.
Marker and Camera Updates:

## Markers are dynamically added for the current and destination locations.
## The camera is updated to center the map on the current location or destination.
## Map Type Toggle:
_toggleMapType: Allows the user to switch between different map types (normal, satellite, terrain).