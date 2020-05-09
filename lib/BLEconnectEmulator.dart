// This package contains dummy classes to BLEconnect.dart that maintain 
// the functionality of the main.dart file in an environment where BLE 
// is not available 


import 'package:flutter/material.dart';


class BLEconnect {

  // final String SERVICE_UUID_PREFIX = "0000ffe0";
  // final String CHARACTERISTIC_UUID_PREFIX = "0000ffe1";
  // BluetoothDevice targetDevice;
  // BluetoothService targetService;
  // BluetoothCharacteristic targetCharacteristic;


  Widget withBLEon(BuildContext context, Function func) {
    return func();
    // return StreamBuilder<BluetoothState>(
    //   stream: FlutterBlue.instance.state,
    //   initialData: BluetoothState.unknown,
    //   builder: (c, snapshot) {
    //     final state = snapshot.data;
    //     if (state == BluetoothState.on) {
    //       return func();
    //     }
    //     return BluetoothOffScreen(state: state);
    //   }
    // );
  }


  Widget bleDeviceState(BuildContext context) {
    return Icon(Icons.bluetooth_disabled, color: Colors.red);
    // return StreamBuilder<List<BluetoothDevice>>(
    //   stream: Stream.periodic(Duration(seconds: 1))
    //       .asyncMap((_) => FlutterBlue.instance.connectedDevices),
    //   initialData: [],
    //   builder: (c, snapshot) {
    //     if (snapshot.data.contains(targetDevice)) {
    //       return Icon(Icons.bluetooth_connected);
    //     }
    //     return Icon(Icons.bluetooth_disabled, color: Colors.red);
    //   } 
    // );
  }



  Widget getBLEdevices() {
    // FlutterBlue.instance.startScan();
    return FindDevicesScreen();
  }

  Future<bool>  connectBLEdevice(BuildContext context, var device) async {
    return true;
  // void connectBLEdevice(BuildContext context, BluetoothDevice device) {
  //   FlutterBlue.instance.stopScan();
  //   targetDevice = device;
  //   discoverServices(context);
  }


  // void discoverServices(BuildContext context) async{
  //   if (targetDevice == null) return;
  //   List<BluetoothService> serviceList;
  //   Future<List<BluetoothService>> connect() async{
  //     await targetDevice.connect();
  //     serviceList = await targetDevice.discoverServices();
  //     serviceList.forEach((service) {
  //       if (service.uuid.toString().split("-")[0] == SERVICE_UUID_PREFIX) {
  //         targetService = service;
  //         service.characteristics.forEach((characteristic) async {
  //           if (characteristic.uuid.toString().split("-")[0] == CHARACTERISTIC_UUID_PREFIX) {
  //             targetCharacteristic = characteristic;
  //           }
  //         });
  //       }
  //     });
  //     return serviceList;
  //   }
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: new Text("Connecting"),
  //         content: FutureBuilder<List<BluetoothService>>(
  //           future: connect(),
  //           builder: (context, snapshot) {
  //                           if (snapshot.hasData) {
  //                             Navigator.of(context).pop();
  //                             return CircularProgressIndicator();           
  //             }
  //             return CircularProgressIndicator();
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }


  void sendData(BuildContext context, List<int> data, Function func) async {
    List<int> dummyReturnValue = [0,0,0,0];
    func(dummyReturnValue);
    // if (targetCharacteristic == null) return;
    // targetCharacteristic.value.listen((value) {
    //   if (value.length>=2) {
    //     if (value[value.length-2] == 13 && value[value.length-1] == 10) {
    //       func(value.sublist(0, value.length-2));
    //       targetCharacteristic.setNotifyValue(false);
    //     }
    //   }
    // });
    // await targetCharacteristic.setNotifyValue(true);
    // List<int> bytes = utf8.encode(data);
    // await targetCharacteristic.write(bytes).catchError((e) => showAlert(context, e.toString()));
  }


  // void showAlert(BuildContext context, String message) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: new Text(message),
  //         actions: <Widget>[
  //           FlatButton(
  //             child: new Text("OK"),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

}


// class BluetoothOffScreen extends StatelessWidget {
//   const BluetoothOffScreen({Key key, this.state}) : super(key: key);

//   final BluetoothState state;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.lightBlue,
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             Icon(
//               Icons.bluetooth_disabled,
//               size: 200.0,
//               color: Colors.white54,
//             ),
//             Text(
//               'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
//               style: Theme.of(context)
//                   .primaryTextTheme
//                   .subtitle1
//                   .copyWith(color: Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


class FindDevicesScreen extends StatelessWidget {

  // Widget scanResultTile(BuildContext context, ScanResult result, Function onTap) {
  //   Text subtitle;
  //   if(!result.advertisementData.connectable) {
  //     subtitle = Text("not connectable", style: Theme.of(context).textTheme.caption);
  //   }
  //   return StreamBuilder<BluetoothDeviceState>(
  //       stream: result.device.state,
  //       initialData: BluetoothDeviceState.disconnected,
  //       builder: (c, snapshot) => FlatButton(
  //         child: ListTile(
  //           title: Text(
  //             result.device.name.length > 0 ? result.device.name : result.device.id.toString(),
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //           subtitle: subtitle,
  //           leading: Text(result.rssi.toString()),
  //         ),    
  //         onPressed: result.advertisementData.connectable ? onTap : null,
  //         color: Colors.blue,
  //         textColor: Colors.white,
  //         padding: EdgeInsets.all(8.0),     
  //       )
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Device (emulated)'),
      ),
      // appBar: AppBar(
      //   title: Text('Select Device'),
      // ),
      // body: SingleChildScrollView(
      //   child: Column(
      //     children: <Widget>[
      //       StreamBuilder<List<BluetoothDevice>>(
      //         stream: Stream.periodic(Duration(seconds: 1))
      //             .asyncMap((_) => FlutterBlue.instance.connectedDevices),
      //         initialData: [],
      //         builder: (c, snapshot) => Column(
      //           children: snapshot.data
      //             .map((d) => ListTile(
      //                 title: d.name.length > 0 ? Text(d.name) : Text(d.id.toString()),
      //                 subtitle: Text("Connected"),
      //                 trailing: RaisedButton(
      //                   child: Text("DISCONNECT"),
      //                   color: Colors.black,
      //                   textColor: Colors.white,
      //                   onPressed: () {
      //                     d.disconnect();
      //                   }
      //                 ),
      //               )
      //             ).toList(),
      //         ),
      //       ),
      //       StreamBuilder<List<ScanResult>>(
      //         stream: FlutterBlue.instance.scanResults,
      //         initialData: [],
      //         builder: (context, snapshot) {
      //           return Column(
      //           children: snapshot.data
      //             .map((result) => scanResultTile(
      //                 context, 
      //                 result,
      //                 () => Navigator.of(context).pop(result.device),
      //               ),
      //             ).toList(),
      //           );
      //         }
      //       )
      //     ],
      //   ),
      // )
    );
  }

}
