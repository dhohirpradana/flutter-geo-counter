import 'dart:async';
import 'dart:math';
import 'package:chat_app/utils/model/marker_model.dart';
import 'package:chat_app/utils/model/polygon_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);
  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  bool _isPolygon = false;
  bool _isMarker = false;
  bool _isJarak = false;
  bool _isLuas = false;
  List<LatLng> polygonLatLngs = <LatLng>[];
  List<mp.LatLng> mpPolygonLatLngs = <mp.LatLng>[];
  final Completer<GoogleMapController> _controller = Completer();

  Future<void> _getCurentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        _myLocation(lat: position.latitude, lng: position.longitude)));
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-6.959079, 111.1032827),
    zoom: 14.4746,
    // zoom: 16.0,
  );

  static CameraPosition _myLocation({required lat, required lng}) =>
      CameraPosition(
          bearing: 192.8334901395799,
          target: LatLng(lat, lng),
          tilt: 59.440717697143555,
          zoom: 19.151926040649414);

  _mapOnTap(point) {
    final mpPoint = mp.LatLng(point.latitude, point.longitude);
    if (_isPolygon) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      polygonLatLngs.add(point);
      mpPolygonLatLngs.add(mpPoint);
      Provider.of<PolygonModel>(context, listen: false).addPolygon(
        points: polygonLatLngs,
      );
    } else if (_isMarker) {
      Provider.of<MarkerModel>(context, listen: false).clearMarker();
      Provider.of<MarkerModel>(context, listen: false).addMarker(points: point);
    }
  }

  _distance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _surfaceArea() {
    final luas = mp.SphericalUtil.computeArea(mpPolygonLatLngs);
    final hectare = luas / 10000;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(days: 1),
        content: Text('Luas : ' +
            luas.toStringAsFixed(2) +
            ' m2 / ' +
            hectare.toStringAsFixed(4) +
            ' ha')));
  }

  void _showSnacbar(text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1900), content: Text(text)));
  }

  void _showSnacbarPermanent(text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: Text(text),
      ),
    );
  }

  void _dimissSnackbar() {
    Future.delayed(const Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  void _disablePolygon() {
    _isPolygon = false;
    polygonLatLngs.clear();
    mpPolygonLatLngs.clear();
    Provider.of<PolygonModel>(context, listen: false).clearPolygon();
    Provider.of<PolygonModel>(context, listen: false)
        .changeButtonColor(isDisable: !_isPolygon);
    _dimissSnackbar();
  }

  void _enablePolygon() {
    _isPolygon = true;
    _isMarker = false;
    Provider.of<PolygonModel>(context, listen: false)
        .changeButtonColor(isDisable: !_isPolygon);
  }

  void _disableMarker() {
    _isMarker = false;
    Provider.of<MarkerModel>(context, listen: false).clearMarker();
    Provider.of<MarkerModel>(context, listen: false)
        .changeButtonColor(isDisable: !_isMarker);
  }

  void _enableMarker() {
    _isMarker = true;
    _isPolygon = false;
    Provider.of<MarkerModel>(context, listen: false)
        .changeButtonColor(isDisable: !_isMarker);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo Counter'),
        backgroundColor: const Color(0xff2c3e50),
      ),
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            polygons: Provider.of<PolygonModel>(context).polygon,
            markers: Provider.of<MarkerModel>(context).marker,
            compassEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.hybrid,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: (point) {
              _mapOnTap(point);
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PaddingWidget(
                    child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Provider.of<PolygonModel>(context)
                                    .buttonColor)),
                        onPressed: () {
                          if (_isPolygon) {
                            _disablePolygon();
                          } else {
                            _enablePolygon();
                          }
                        },
                        child: const Text('Line')),
                  ),
                  PaddingWidget(
                    child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Provider.of<MarkerModel>(context).buttonColor)),
                        onPressed: () {
                          if (_isMarker) {
                            _disableMarker();
                          } else {
                            _enableMarker();
                          }
                        },
                        child: const Text('Marker')),
                  ),
                  PaddingWidget(
                    child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.black54)),
                        onPressed: () {
                          _isJarak = !_isJarak;
                          if (polygonLatLngs.length == 2 && _isJarak) {
                            final double jarak = _distance(
                                polygonLatLngs[0].latitude,
                                polygonLatLngs[0].longitude,
                                polygonLatLngs[1].latitude,
                                polygonLatLngs[1].longitude);
                            _showSnacbarPermanent(
                                'Jarak : ' + jarak.toStringAsFixed(2) + ' km');
                          } else if (polygonLatLngs.length != 2) {
                            _showSnacbar('Harus berupa garis tunggal!');
                          } else if (!_isJarak) {
                            _dimissSnackbar();
                          }
                        },
                        child: const Text('Jarak')),
                  ),
                  PaddingWidget(
                    child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.black54)),
                        onPressed: () {
                          _isLuas = !_isLuas;
                          if (mpPolygonLatLngs.length > 2 && _isLuas) {
                            _surfaceArea();
                          } else if (mpPolygonLatLngs.length < 3) {
                            _showSnacbar('Harus berupa polygon!');
                          } else if (!_isLuas) {
                            _dimissSnackbar();
                          }
                        },
                        child: const Text('Luas')),
                  )
                ],
              )
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_pin_circle),
        onPressed: () {
          _getCurentLocation();
        },
      ),
    );
  }
}

class PaddingWidget extends StatelessWidget {
  final Widget child;
  const PaddingWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: child,
    );
  }
}
