
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';


class BLEconnect {

  static const String SERVICE_UUID_PREFIX = "0000ffe0";
  static const String CHARACTERISTIC_UUID_PREFIX = "0000ffe1";
  static BluetoothDevice targetDevice;
  static BluetoothService targetService;
  static BluetoothCharacteristic targetCharacteristic;

  static StreamController<List<int>> dataToSendController;
  static StreamSubscription sendSubscription;
  static StreamSubscription readSubscription;

  final StreamController<bool> isConnectedCtrl = StreamController<bool>.broadcast();
  Stream get isConnectedStream => isConnectedCtrl.stream;
  
  Widget withBLEconnected(BuildContext context, {Function onConnect, Function whileConnected, Function returnHandler, Function errorHandler}) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBlue.instance.state,
      initialData: BluetoothState.unknown,
      builder: (c, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          return StreamBuilder<bool>(
            stream: isConnectedStream,
            initialData: false,
            builder: (BuildContext c, AsyncSnapshot<bool> snapshot) {
              final state = snapshot.data;
              if (state) {
                return whileConnected();
              }
              return connectBLEdevice(
                      context, 
                      onConnect: onConnect,
                      returnHandler: (returnValue) => returnHandler(returnValue),
                      errorHandler: errorHandler
              );
            }
          );
        }
        return BluetoothOffScreen(state: state);
      }
    );
  }


  Widget bleDeviceState(BuildContext context) {
    return StreamBuilder<BluetoothDeviceState>(
      // stream: Stream.periodic(Duration(milliseconds: 500))
      //     .asyncMap((_) => FlutterBlue.instance.connectedDevices),
      // initialData: [],
      stream: targetDevice.state,
      initialData: BluetoothDeviceState.disconnected,
      builder: (c, snapshot) {
        // if (snapshot.data.contains(targetDevice)) {
        if (snapshot.data == BluetoothDeviceState.connected) {
          return Icon(Icons.bluetooth_connected);
        }
        return Icon(Icons.bluetooth_disabled, color: Colors.red);
      } 
    );
  }


  Widget withBLEdeviceConnected(BuildContext context, {Widget whileDisconnected}) {
    return StreamBuilder<BluetoothDeviceState>(
      stream: targetDevice.state,
      initialData: BluetoothDeviceState.disconnected,
      builder: (c, snapshot) {
        if (snapshot.data == BluetoothDeviceState.disconnected) {
          return whileDisconnected;
        }
        return null;
      } 
    );
  }


  // bool isConnected(BuildContext context) {
  //   bool isConnected;
  //   Stream.periodic(Duration(seconds: 1))
  //         .asyncMap((_) => FlutterBlue.instance.connectedDevices)
  //         .listen((devices) => isConnected = devices.contains(targetDevice));
  //   return isConnected;
  // }


  // Widget getBLEdevices() {
  //   FlutterBlue.instance.startScan();
  //   return FindDevicesScreen();
  // }


  


  Widget connectBLEdevice(BuildContext context, {Function onConnect, Function returnHandler, Function errorHandler}) {
    // FlutterBlue.instance.stopScan();
    FlutterBlue.instance.startScan();
    return findDevicesScreen(
            context,
            onConnect: onConnect,
            returnHandler: returnHandler,
            errorHandler: errorHandler
    );
    // targetDevice = await Navigator.of(context).push(
    //                         MaterialPageRoute(
    //                           builder: (context) => getBLEdevices()
    //                         )
    //                       );
    // return getCharacteristic(context, returnHandler: returnHandler);
  }


  /// discovers the services of the BLE device and starts configuration of the characteristics
  void getCharacteristic(BuildContext context, {Function onConnect, Function returnHandler, Function errorHandler}) async {
    if (targetDevice == null) return;
    bool connected;
    Future<bool> connect() async{
      await targetDevice.connect();
      // connected = true;
      List<BluetoothService> serviceList = await targetDevice.discoverServices().catchError((e) => errorHandler(e));
      serviceList.forEach((service) {
        if (service.uuid.toString().split("-")[0] == SERVICE_UUID_PREFIX) {
          targetService = service;
          service.characteristics.forEach((characteristic) {
            if (characteristic.uuid.toString().split("-")[0] == CHARACTERISTIC_UUID_PREFIX) {
              targetCharacteristic = characteristic;
            }
          });
        }
      });
      if (targetCharacteristic != null) {
        connected = await configureCharacteristics(context, returnHandler: returnHandler, errorHandler: errorHandler);
        onConnect();
        return connected;
      } else {
        return false;
      }
      
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Connecting"),
          content: FutureBuilder<bool>(
            future: connect(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                Navigator.of(context).pop();
                isConnectedCtrl.sink.add(true);
                return CircularProgressIndicator();                         
              }
              return CircularProgressIndicator();
            },
          ),
        );
      },
    );
  }


  Future<bool> configureCharacteristics(BuildContext context, {Function returnHandler, Function errorHandler}) async {
    await targetCharacteristic.setNotifyValue(true).catchError((e) => errorHandler(e));
    dataToSendController = StreamController<List<int>>();
    Stream dataToSendStream = dataToSendController.stream;
    sendSubscription = dataToSendStream.listen((sendData) async {
      sendSubscription.pause();
      await targetCharacteristic.write(sendData).catchError((e) => errorHandler(e));      
      sendSubscription.resume();
    });
    readSubscription = targetCharacteristic.value.listen((value) {
      if (value.length>=2) {
        if (value[value.length-2] == 13 && value[value.length-1] == 10) {
          returnHandler(value.sublist(0, value.length-2));
        }
      }
    });
    return true;
  }


  void sendData(BuildContext context, List<int>  data, {bool fastSend: false, Function errorHandler}) async {
    if (targetCharacteristic == null) return;
    if (fastSend && sendSubscription.isPaused) return;
    dataToSendController.add(data);
  }


  void disconnectBLEdevice(BuildContext context) async {
    await targetDevice.disconnect();
    targetDevice = null;
    targetService = null;
    targetCharacteristic = null;
    readSubscription.cancel();
    sendSubscription.cancel();
    dataToSendController.close();
    isConnectedCtrl.sink.add(false);
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


  Widget scanResultTile(BuildContext context, ScanResult result, Function onTap) {
    Text subtitle;
    if(!result.advertisementData.connectable) {
      subtitle = Text("not connectable", style: Theme.of(context).textTheme.caption);
    }
    return StreamBuilder<BluetoothDeviceState>(
        stream: result.device.state,
        initialData: BluetoothDeviceState.disconnected,
        builder: (c, snapshot) => FlatButton(
          child: ListTile(
            title: Text(
              result.device.name.length > 0 ? result.device.name : result.device.id.toString(),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: subtitle,
            leading: Text(result.rssi.toString()),
          ),    
          onPressed: result.advertisementData.connectable ? onTap : null,
          color: Colors.blue,
          textColor: Colors.white,
          padding: EdgeInsets.all(8.0),     
        )
    );
  }


  Widget findDevicesScreen(BuildContext context, {Function onConnect, Function returnHandler, Function errorHandler}) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Device'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<List<BluetoothDevice>>(
              stream: Stream.periodic(Duration(seconds: 1))
                  .asyncMap((_) => FlutterBlue.instance.connectedDevices),
              initialData: [],
              builder: (c, snapshot) => Column(
                children: snapshot.data
                  .map((d) => ListTile(
                      title: d.name.length > 0 ? Text(d.name) : Text(d.id.toString()),
                      subtitle: Text("Connected"),
                      trailing: RaisedButton(
                        child: Text("DISCONNECT"),
                        color: Colors.black,
                        textColor: Colors.white,
                        onPressed: () {
                          disconnectBLEdevice(context);
                        }
                      ),
                    )
                  ).toList(),
              ),
            ),
            StreamBuilder<List<ScanResult>>(
              stream: FlutterBlue.instance.scanResults,
              initialData: [],
              builder: (context, snapshot) {
                return Column(
                children: snapshot.data
                  .map((result) => scanResultTile(
                      context, 
                      result,
                      // () => Navigator.of(context).pop(result.device),
                      () {
                        FlutterBlue.instance.stopScan();
                        targetDevice = result.device;
                        getCharacteristic(
                              context,
                              returnHandler: returnHandler,
                              onConnect: onConnect,
                              errorHandler: errorHandler
                        );
                      }
                      
                    ),
                  ).toList(),
                );
              }
            )
          ],
        ),
      )
    );
  }

}


class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}



