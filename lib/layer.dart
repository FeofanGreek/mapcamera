import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_gl_example/main.dart';
import 'package:mapbox_gl_example/page.dart';

class LayerPage extends ExamplePage {
  LayerPage() : super(const Icon(Icons.share), 'Layer');

  @override
  Widget build(BuildContext context) => LayerBody();
}

class LayerBody extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LayerState();
}

class LayerState extends State {
  static final LatLng center = const LatLng( 55.603333, 37.851667,);

  late MapboxMapController controller;
  Timer? bikeTimer;
  Timer? filterTimer;
  int filteredId = 0;

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: MapsDemo.ACCESS_TOKEN,
      dragEnabled: false,
      myLocationEnabled: true,
      onMapCreated: _onMapCreated,
      onMapClick: (point, latLong) =>
          print(point.toString() + latLong.toString()),
      onStyleLoadedCallback: _onStyleLoadedCallback,
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 11.0,
      ),
      annotationOrder: const [],
    );
  }

  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;

    controller.onFeatureTapped.add(onFeatureTap);
  }

  void onFeatureTap(dynamic featureId, Point<double> point, LatLng latLng) {
    final snackBar = SnackBar(
      content: Text(
        'Tapped feature with id $featureId',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Theme.of(context).primaryColor,
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _onStyleLoadedCallback() async {
    await controller.addGeoJsonSource("points", _points);
    await controller.addGeoJsonSource("moving", _movingFeature(0));

    //new style of adding sources
    await controller.addSource("fills", GeojsonSourceProperties(data: _fills));

    await controller.addFillLayer(
      "fills",
      "fills",
      FillLayerProperties(fillColor: [
        Expressions.interpolate,
        ['exponential', 0.5],
        [Expressions.zoom],
        11,
        'red',
        18,
        'green'
      ], fillOpacity: 0.4),
      belowLayerId: "water",
      filter: ['==', 'id', filteredId],
    );

    await controller.addLineLayer(
      "fills",
      "lines",
      LineLayerProperties(
          lineColor: Colors.lightBlue.toHexStringRGB(),
          lineWidth: [
            Expressions.interpolate,
            ["linear"],
            [Expressions.zoom],
            11.0,
            2.0,
            20.0,
            10.0
          ]),
    );

    // await controller.addCircleLayer(
    //   "fills",
    //   "circles",
    //   CircleLayerProperties(
    //     circleRadius: 4,
    //     circleColor: Colors.blue.toHexStringRGB(),
    //   ),
    // );

    await controller.addSymbolLayer(
      "points",
      "symbols",
      SymbolLayerProperties(
        iconImage: "{type}-15",
        iconSize: 2,
        iconAllowOverlap: true,
      ),
    );

    await controller.addSymbolLayer(
      "moving",
      "moving",
      SymbolLayerProperties(
        textField: [Expressions.get, "name"],
        textHaloWidth: 1,
        textSize: 10,
        textHaloColor: Colors.white.toHexStringRGB(),
        textOffset: [
          Expressions.literal,
          [0, 2]
        ],
        iconImage: "bicycle-15",
        iconSize: 2,
        iconAllowOverlap: true,
        textAllowOverlap: true,
      ),
      minzoom: 11,
    );

    bikeTimer = Timer.periodic(Duration(milliseconds: 10), (t) {
      controller.setGeoJsonSource("moving", _movingFeature(t.tick / 2000));
    });

    filterTimer = Timer.periodic(Duration(seconds: 3), (t) {
      filteredId = filteredId == 0 ? 1 : 0;
      controller.setFilter('fills', ['==', 'id', filteredId]);
    });
  }

  @override
  void dispose() {
    bikeTimer?.cancel();
    filterTimer?.cancel();
    super.dispose();
  }
}

Map<String, dynamic> _movingFeature(double t) {
  List<double> makeLatLong(double t) {
    final angle = t * 2 * pi;
    const r = 0.025;
    const center_x = 151.1849;
    const center_y = -33.8748;
    return [
      center_x + r * sin(angle),
      center_y + r * cos(angle),
    ];
  }

  return {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "properties": {"name": "POGAČAR Tadej"},
        "id": 10,
        "geometry": {"type": "Point", "coordinates": makeLatLong(t)}
      },
      {
        "type": "Feature",
        "properties": {"name": "VAN AERT Wout"},
        "id": 11,
        "geometry": {"type": "Point", "coordinates": makeLatLong(t + 0.15)}
      },
    ]
  };
}

final _fills = {
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 0, // web currently only supports number ids
      "properties": <String, dynamic>{'id': 0},
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [151.178099204457737, -33.901517742631846],
            [151.179025547977773, -33.872845324482071],
            [151.147000529140399, -33.868230472039514],
            [151.150838238009328, -33.883172899638311],
            [151.14223647675135, -33.894158309528244],
            [151.155999294764086, -33.904812805307806],
            [151.178099204457737, -33.901517742631846]
          ],
          // [
          //   [151.162657925954278, -33.879168932438581],
          //   [151.155323416087612, -33.890737666431583],
          //   [151.173659690754278, -33.897637567778119],
          //   [151.162657925954278, -33.879168932438581]
          // ]
        ]
      }
    },
    {
      "type": "Feature",
      "id": 1,
      "properties": <String, dynamic>{'id': 1},
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          // [
          //   [151.18735077583878, -33.891143558434102],
          //   [151.197374605989864, -33.878357032551868],
          //   [151.213021560372084, -33.886475683791488],
          //   [151.204953599518745, -33.899463918807818],
          //   [151.18735077583878, -33.891143558434102]
          // ],
          [
            [38.966667, 54.616667, ],
            [39.033333, 54.666667, ],
            [39.916667, 54.8, ],
            [40.0, 54.75, ],
            [40.166667, 54.733333, ],
            [40.166667, 54.733333, ],
            [40.150803, 54.768534, ],
            [40.124861, 54.802875, ],
            [40.092787, 54.835456, ],
            [40.054922, 54.865917, ],
            [40.011674, 54.893917, ],
            [39.963515, 54.919146, ],
            [39.910974, 54.94132, ],
            [39.854633, 54.960193, ],
            [39.795118, 54.975552, ],
            [39.733093, 54.987224, ],
            [39.669255, 54.99508, ],
            [39.604319, 54.99903, ],
            [39.539015, 54.99903, ],
            [39.474079, 54.99508, ],
            [39.410241, 54.987224, ],
            [39.348216, 54.975552, ],
            [39.288701, 54.960193, ],
            [39.23236, 54.94132, ],
            [39.179819, 54.919146, ],
            [39.13166, 54.893917, ],
            [39.088412, 54.865917, ],
            [39.050547, 54.835456, ],
            [39.018473, 54.802875, ],
            [38.992531, 54.768534, ],
            [38.972994, 54.732814, ],
            [38.960059, 54.696109, ],
            [38.953851, 54.658824, ],
            [38.95442, 54.621368, ],
            [38.961741, 54.584152, ],
            [38.975715, 54.547581, ],
            [38.996173, 54.512055, ],
            [39.022876, 54.477959, ],
            [39.033333, 54.466667, ],
            [38.966667, 54.616667, ]
          ],
          [
            [37.851667, 55.603333, ],
            [37.966667, 55.616667, ],
            [38.25, 55.583333, ],
            [39.066667, 55.466667, ],
            [39.3, 55.458333, ],
            [39.466667, 55.216667, ],
            [38.646667, 55.058333, ],
            [38.186667, 55.346667, ],
            [38.0, 55.491667, ],
            [37.851667, 55.603333, ]

          ]
        ]
      }
    }
  ]
};

const _points = {
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 2,
      "properties": {
        "type": "restaurant",
      },
      "geometry": {
        "type": "Point",
        "coordinates": [151.184913929732943, -33.874874486427181]
      }
    },
    {
      "type": "Feature",
      "id": 3,
      "properties": {
        "type": "airport",
      },
      "geometry": {
        "type": "Point",
        "coordinates": [151.215730044667879, -33.874616048776858]
      }
    },
    {
      "type": "Feature",
      "id": 4,
      "properties": {
        "type": "bakery",
      },
      "geometry": {
        "type": "Point",
        "coordinates": [151.228803547973598, -33.892188026142584]
      }
    },
    {
      "type": "Feature",
      "id": 5,
      "properties": {
        "type": "college",
      },
      "geometry": {
        "type": "Point",
        "coordinates": [151.186470299174118, -33.902781145804774]
      }
    }
  ]
};
