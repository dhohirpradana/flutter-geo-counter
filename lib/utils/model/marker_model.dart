import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerModel with ChangeNotifier {
  // PolygonModel({required this.polygon});
  Set<Marker> marker = HashSet<Marker>();
  bool color = false;
  Color buttonColor = Colors.black54;

  // when `notifyListeners` is called, it will invoke
  // any callbacks that have been registered with an instance of this object
  // `addListener`.

  int markerIdCounter = 1;
  void addMarker({
    required LatLng points,
  }) {
    markerIdCounter++;
    marker.add(Marker(
        markerId: (MarkerId('marker_id_$markerIdCounter')), position: points));
    notifyListeners();
  }

  void clearMarker() {
    markerIdCounter == 1;
    marker.clear();
    notifyListeners();
  }

  void changeButtonColor({required bool isDisable}) {
    if (color == isDisable) {
      buttonColor = Colors.red.withOpacity(0.70);
    } else {
      buttonColor = Colors.black54;
    }
    notifyListeners();
  }
}
