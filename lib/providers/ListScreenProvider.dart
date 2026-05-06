import 'package:flutter/material.dart';
// import 'package:flutter_google_street_view/flutter_google_street_view.dart';
import 'package:uconnect/data/model/devices.dart';

class ListScreenProvider extends ChangeNotifier {
  // Map<int, StreetViewController> _streetViewControllers = {};
  Map<int, deviceItems> _vehiclesData = {};

  // void addStreetViewController(int vehicleId, StreetViewController controller) {
  //   _streetViewControllers[vehicleId] = controller;
  //   notifyListeners();
  // }

  // StreetViewController getStreetViewController(int vehicleId) {
  //   return _streetViewControllers[vehicleId]!;
  // }

  void addVehicleData(int vehicleId, deviceItems vehicleData) {
    _vehiclesData[vehicleId] = vehicleData;
    notifyListeners();
  }

  deviceItems getVehicleData(int vehicleId) {
    return _vehiclesData[vehicleId]!;
  }

  void removeVehicle(int vehicleId) {
    // _streetViewControllers.remove(vehicleId);
    _vehiclesData.remove(vehicleId);
    notifyListeners();
  }
}
