// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:geocoding/geocoding.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final Set<Marker> _markers = <Marker>{};
  BitmapDescriptor? _customIcon;
  late GoogleMapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
  }

  Future<void> _loadCustomIcon() async {
    final Uint8List byteIcon =
        await getBytesFromAsset('assets/images/red.png', 100);
    // ignore: deprecated_member_use
    _customIcon = BitmapDescriptor.fromBytes(byteIcon);
  }

  Future<void> _addMarker(LatLng position) async {
    final newMarker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      icon: _customIcon!,
    );

    setState(() {
      _markers.clear();
      _markers.add(newMarker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Learning Google Maps"),
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      mapType: MapType.hybrid,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      onTap: (LatLng tappedPosition) {
        print(
            "Tapped on: ${tappedPosition.latitude}, ${tappedPosition.longitude}");
        _addMarker(tappedPosition);
      },
      markers: _markers,
      initialCameraPosition: const CameraPosition(
        target: LatLng(11.568265662839597, 104.89206165075304),
        zoom: 15.0,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 16.0,
      left: 16.0,
      right: 16.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchAndNavigate,
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for a location',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15),
                ),
                onSubmitted: (value) {
                  _searchAndNavigate();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAndNavigate() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        Location firstResult = locations.first;
        LatLng searchedLocation =
            LatLng(firstResult.latitude, firstResult.longitude);

        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: searchedLocation,
              zoom: 15.0,
            ),
          ),
        );

        _addMarker(searchedLocation);
      }
    } catch (e) {
      print("Error searching for location: $e");
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo info = await codec.getNextFrame();
    return (await info.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
}
