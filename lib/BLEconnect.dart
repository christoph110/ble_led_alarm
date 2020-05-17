
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

  // static StreamController<bool> isConnectedStream;
  final StreamController<bool> isConnectedCtrl = StreamController<bool>.broadcast();
  Stream get isConnectedStream => isConnectedCtrl.stream;
  
  Widget withBLEconnected(BuildContext context, {Function onConnect, Function whileConnected, Function returnHandler}) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBlue.instance.state,
      initialData: BluetoothState.unknown,
      builder: (c, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          // return whileConnected();
          return StreamBuilder<bool>(
            stream: isConnectedStream,
            // stream: Stream.periodic(Duration(seconds: 2)).asyncMap((_) => getIsConnected),
            initialData: false,
            builder: (BuildContext c, AsyncSnapshot<bool> snapshot) {
              // showAlert(context, snapshot.data.toString());
              final state = snapshot.data;
              if (state) {
                return whileConnected();
              }
              return connectBLEdevice(
                      context, 
                      onConnect: onConnect(),
                      returnHandler: (returnValue) => returnHandler(returnValue) 
              );
            }
          );
        }
        return BluetoothOffScreen(state: state);
      }
    );
  }


  // Widget bleDeviceState(BuildContext context) {
  //   return StreamBuilder<List<BluetoothDevice>>(
  //     stream: Stream.periodic(Duration(seconds: 1))
  //         .asyncMap((_) => FlutterBlue.instance.connectedDevices),
  //     initialData: [],
  //     builder: (c, snapshot) {
  //       if (snapshot.data.contains(targetDevice)) {
  //         return Icon(Icons.bluetooth_connected);
  //       }
  //       return Icon(Icons.bluetooth_disabled, color: Colors.red);
  //     } 
  //   );
  // }


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


  


  Widget connectBLEdevice(BuildContext context, {Function onConnect, Function returnHandler}) {
    // FlutterBlue.instance.stopScan();
    FlutterBlue.instance.startScan();
    return findDevicesScreen(
            context,
            onConnect: onConnect,
            returnHandler: returnHandler
    );
    // targetDevice = await Navigator.of(context).push(
    //                         MaterialPageRoute(
    //                           builder: (context) => getBLEdevices()
    //                         )
    //                       );
    // return getCharacteristic(context, returnHandler: returnHandler);
  }

  /// discovers the services of the BLE device and starts configuration of the characteristics
  void getCharacteristic(BuildContext context, {Function onConnect, Function returnHandler}) async {
    if (targetDevice == null) return;
    
    List<BluetoothService> serviceList;
    // showAlert(context, "First");
    // await targetDevice.connect();
    // showAlert(context, "Second");
    // serviceList = await targetDevice.discoverServices();
    // showAlert(context, "Third");

    
    Future<List<BluetoothService>> connect() async{
      await targetDevice.connect();
      List<BluetoothService> serviceList = await targetDevice.discoverServices();
      serviceList.forEach((service) {
        if (service.uuid.toString().split("-")[0] == SERVICE_UUID_PREFIX) {
          targetService = service;
          service.characteristics.forEach((characteristic) async {
            showAlert(context, characteristic.uuid.toString());
            if (characteristic.uuid.toString().split("-")[0] == CHARACTERISTIC_UUID_PREFIX) {
              targetCharacteristic = characteristic;
              bool isConnected =  await configureCharacteristics(context, returnHandler: returnHandler)
                .then((isConnected) => onConnect());
              return isConnected;
            }
          });
        }
      });
      return serviceList;
    }
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Connecting"),
          content: FutureBuilder<List<BluetoothService>>(
            future: connect(),
            builder: (context, snapshot) {
              showAlert(context, snapshot.hasData.toString());
              if (snapshot.hasData) {
                
                Navigator.of(context).pop();
                return CircularProgressIndicator();                         
              }
              return CircularProgressIndicator();
            },
          ),
        );
      },
    );
  }


  Future<bool> configureCharacteristics(BuildContext context, {Function returnHandler}) async {
    await targetCharacteristic.setNotifyValue(true);
    dataToSendController = StreamController<List<int>>();
    Stream dataToSendStream = dataToSendController.stream;
    sendSubscription = dataToSendStream.listen((sendData) async {
      sendSubscription.pause();
      await targetCharacteristic.write(sendData).catchError((e) => showAlert(context, e.toString()));      
      sendSubscription.resume();
    });
    readSubscription = targetCharacteristic.value.listen((value) {
      // showAlert(context, "Data received:\n${value.toString()}");
      if (value.length>=2) {
        if (value[value.length-2] == 13 && value[value.length-1] == 10) {
          returnHandler(value.sublist(0, value.length-2));
        }
      }
    });
    return true;
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
    // showAlert(context, "dispatched");
  }

  
  void sendData(BuildContext context, List<int>  data, {bool fastSend: false}) async {
    if (targetCharacteristic == null) return;
    if (fastSend && sendSubscription.isPaused) return;
    dataToSendController.add(data);
  }


  void showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(message),
          actions: <Widget>[
            FlatButton(
              child: new Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


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


  Widget findDevicesScreen(BuildContext context, {Function onConnect, Function returnHandler}) {
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



