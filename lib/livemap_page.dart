import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'schedulepage.dart';
import 'settings_page.dart';

class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  LatLng _truckLocation = const LatLng(14.5547, 121.0244); // Default location
  String _driverName = "Loading...";
  String _driverNo = "Loading...";
  bool _isMapMinimized = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _fetchDriverData();
    _setupLocationListener();
  }
  
  void _fetchDriverData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _driverName = data['fullName'] ?? "Driver";
            _driverNo = data['driverId'] ?? "Driver ID";
            
            // Check if location field exists before accessing it
            if (data.containsKey('location')) {
              var locationData = data['location'];
              if (locationData != null) {
                double lat = locationData['latitude'] ?? _truckLocation.latitude;
                double lng = locationData['longitude'] ?? _truckLocation.longitude;
                _truckLocation = LatLng(lat, lng);
              }
            }
            
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "User data not found";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "User not authenticated";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching driver data: $e");
      setState(() {
        _errorMessage = "Error loading data";
        _isLoading = false;
      });
    }
  }
  
  void _setupLocationListener() {
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          
          // Check if location field exists
          if (data.containsKey('location')) {
            var locationData = data['location'];
            if (locationData != null) {
              double lat = locationData['latitude'] ?? _truckLocation.latitude;
              double lng = locationData['longitude'] ?? _truckLocation.longitude;
              
              setState(() {
                _truckLocation = LatLng(lat, lng);
              });
              
              // Optionally move map to new location
              _mapController.move(_truckLocation, _mapController.camera.zoom);
            }
          }
        }
      }, onError: (error) {
        print("Error in location listener: $error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchDriverData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header matching the SchedulePage
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E40AF),
                  Color(0xFF3B82F6),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Driver No. $_driverNo",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isMapMinimized = !_isMapMinimized;
                        });
                      },
                      icon: Icon(
                        _isMapMinimized ? Icons.expand : Icons.minimize,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Live Map",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Map using the LiveMapWidget
          Expanded(
            child: Stack(
              children: [
                LiveMapWidget(
                  truckLocation: _truckLocation,
                  mapController: _mapController,
                  isMinimized: _isMapMinimized,
                ),
                
                // Map controls positioned inside the map
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _buildMapControl(Icons.add, () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        );
                      }),
                      const SizedBox(height: 8),
                      _buildMapControl(Icons.remove, () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        );
                      }),
                      const SizedBox(height: 8),
                      _buildMapControl(Icons.my_location, () {
                        _mapController.move(_truckLocation, 12.0);
                      }),
                    ],
                  ),
                ),
                
                // Legend positioned inside the map
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Legend",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 8),
                        LegendItem(
                          color: Color(0xFF10B981),
                          label: "Available Ports",
                        ),
                        LegendItem(
                          color: Color(0xFF3B82F6),
                          label: "Destination",
                        ),
                        LegendItem(
                          color: Color(0xFFF59E0B),
                          label: "Your Location",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context, 2),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: const Color(0xFF3B82F6),
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SchedulePage()),
              );
              break;
            case 2:
              // Already on Live Map page
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Live Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class MapMarker extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const MapMarker({
    super.key,
    required this.label,
    required this.color,
    this.icon = Icons.location_on,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Icon(
          icon,
          color: color,
          size: 24,
        ),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      )
    );
  }
}

class LiveMapWidget extends StatelessWidget {
  final LatLng? truckLocation;
  final MapController? mapController;
  final bool isMinimized;
  final double height;

  const LiveMapWidget({
    super.key,
    this.truckLocation,
    this.mapController,
    this.isMinimized = false,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng portA = const LatLng(14.5995, 120.9842); // Manila Port
    final LatLng portB = const LatLng(10.3157, 123.8854); // Cebu Port
    final LatLng currentTruckLocation = truckLocation ?? const LatLng(14.5547, 121.0244);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isMinimized ? 200 : MediaQuery.of(context).size.height - 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0), // Remove border radius for full-width
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentTruckLocation,
            initialZoom: 10.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.cargo_app',
              maxNativeZoom: 19,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: portA,
                  width: 80,
                  height: 80,
                  child: const MapMarker(
                    label: "Port A",
                    color: Color(0xFF10B981),
                  ),
                ),
                Marker(
                  point: portB,
                  width: 80,
                  height: 80,
                  child: const MapMarker(
                    label: "Port B",
                    color: Color(0xFF3B82F6),
                  ),
                ),
                Marker(
                  point: currentTruckLocation,
                  width: 80,
                  height: 80,
                  child: const MapMarker(
                    label: "Truck Location",
                    color: Color(0xFFF59E0B),
                    icon: Icons.local_shipping,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}