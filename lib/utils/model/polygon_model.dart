import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolygonModel with ChangeNotifier {
  // PolygonModel({required this.polygon});
  Set<Polygon> polygon = HashSet<Polygon>();
  bool color = false;
  Color buttonColor = Colors.black54;

  // when `notifyListeners` is called, it will invoke
  // any callbacks that have been registered with an instance of this object
  // `addListener`.

  int polygonIdCounter = 1;
  Future<void> addPolygon({
    required List<LatLng> points,
  }) async {
    polygonIdCounter++;
    polygon.add(Polygon(
        polygonId: PolygonId("polygon_id_$polygonIdCounter"),
        points: points,
        strokeWidth: 2,
        strokeColor: Colors.yellow,
        fillColor: Colors.yellow.withOpacity(0.05)));
    notifyListeners();
  }

  void clearPolygon() {
    polygonIdCounter == 1;
    polygon.clear();
    notifyListeners();
  }

  void changeButtonColor({required bool isDisable}) {
    if (color == isDisable) {
      buttonColor = Colors.yellow.withOpacity(0.70);
    } else {
      buttonColor = Colors.black54;
    }
    notifyListeners();
  }
}
