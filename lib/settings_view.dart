import 'package:easacc_flutter_developer_task/web_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final TextEditingController webLinkController;
  late final GlobalKey<FormState> fromKey = GlobalKey<FormState>();

  final FlutterBlue flutterBlue = FlutterBlue.instance;
  RegExp urlRegExp = RegExp(r'^(https?|ftp):\/\/[^\s\/$.?#].[^\s]*$');
  String? selectedBlue;
  String? selectedWifi;
  bool isBlueLoading = false;
  bool isWifiLoading = false;
  List<BluetoothDevice> devices = [];
  List<WifiNetwork> wifiList = [];
  @override
  void initState() {
    webLinkController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    webLinkController.dispose();

    super.dispose();
  }

  void accessDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth and/or location permissions not granted'),
          content: const Text('Please enable bluetooth and/or location permission to use this feature.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text(
                'Open settings',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> getPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    if (statuses[Permission.bluetooth] != PermissionStatus.granted ||
        statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.location] != PermissionStatus.granted) {
      return false;
    } else {
      return true;
    }
  }

  Future scanForBluetooth() async {
    devices.clear();
    if (isBlueLoading) {
      return;
    }
    isBlueLoading = true;
    setState(() {});

    flutterBlue.startScan(timeout: const Duration(seconds: 10));
    flutterBlue.scanResults.listen((List<ScanResult> scanResults) {
      for (ScanResult result in scanResults) {
        if (!devices.contains(result.device)) {
          devices.add(result.device);
        }
      }
    });
    await Future.delayed(const Duration(seconds: 5));
    await flutterBlue.stopScan();
    isBlueLoading = false;
    setState(() {});
  }

  Future<bool> isBluetoothOn() async {
    if (!await flutterBlue.isOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please turn on the bluetooth"),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    return true;
  }

  Future<bool> isLocationOn() async {
    if (!await Permission.locationWhenInUse.serviceStatus.isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please turn on the Location"),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    return true;
  }

  Future showBluetoothDevices() async {
    if (!await getPermissions()) {
      accessDeniedDialog();
      return;
    }
    if (!await isBluetoothOn()) {
      return;
    }
    if (!await isLocationOn()) {
      return;
    }
    await scanForBluetooth();
  }

  Future<bool> isWifiOn() async {
    if (!await WiFiForIoTPlugin.isEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please turn on the wifi"),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    return true;
  }

  Future searchForWifi() async {
    if (isWifiLoading) {
      return;
    }
    if (!await isWifiOn()) {
      return;
    }
    if (!await Permission.location.request().isGranted) {
      accessDeniedDialog();
      return;
    }

    if (!await isLocationOn()) {
      return;
    }
    isWifiLoading = true;
    wifiList.clear();
    setState(() {});
    final listOfWifi = await WiFiForIoTPlugin.loadWifiList();
    for (final wifi in listOfWifi) {
      if (!wifiList.contains(wifi)) {
        wifiList.add(wifi);
      }
    }
    isWifiLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        title: Text(
          "Welcome ${FirebaseAuth.instance.currentUser!.displayName.toString()}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Form(
          key: fromKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty || value[0] == ' ') {
                              return "Please enter a link";
                            }
                            if (!urlRegExp.hasMatch(webLinkController.text)) {
                              return 'Please enter a valid website link';
                            }
                            return null;
                          },
                          controller: webLinkController,
                          decoration: InputDecoration(
                            hintText: "website link",
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (fromKey.currentState!.validate()) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Webview(
                                        link: webLinkController.text,
                                      )));
                        }
                      },
                      icon: const Icon(
                        Icons.search_rounded,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await showBluetoothDevices();
                          },
                          child: isBlueLoading
                              ? const CircularProgressIndicator(color: Colors.blue)
                              : const Text(
                                  'Scan for bluetooth devices',
                                  style: TextStyle(fontSize: 18, color: Colors.blue),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: devices.isNotEmpty
                            ? DropdownButton<String>(
                                value: devices[0].id.id,
                                isExpanded: true,
                                onChanged: (String? value) {
                                  selectedBlue = value!;
                                  setState(() {});
                                },
                                items: devices
                                    .map<DropdownMenuItem<String>>(
                                      (BluetoothDevice device) => DropdownMenuItem<String>(
                                        value: device.id.id,
                                        child: ListTile(
                                          title: Text(
                                            device.name.isEmpty ? "Unknown device" : device.name,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          subtitle: Text(
                                            device.id.id,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            : const Center(child: Text("No bluetooth devices", style: TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await searchForWifi();
                            } catch (e) {
                              print(e);
                            }
                          },
                          child: isWifiLoading
                              ? const CircularProgressIndicator(color: Colors.blue)
                              : const Text(
                                  'Scan for wifi networks',
                                  style: TextStyle(fontSize: 18, color: Colors.blue),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: wifiList.isNotEmpty
                            ? DropdownButton<String>(
                                value: selectedWifi,
                                isExpanded: true,
                                onChanged: (String? value) {
                                  selectedWifi = value!;
                                  setState(() {});
                                },
                                items: wifiList
                                    .map<DropdownMenuItem<String>>(
                                      (WifiNetwork device) => DropdownMenuItem<String>(
                                        value: device.bssid,
                                        child: Text(
                                          device.ssid.toString(),
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            : const Center(child: Text("No wifi networks found", style: TextStyle(fontSize: 18))),
                      ),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
