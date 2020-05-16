
import 'package:flutter/material.dart';
import 'dart:async';
import 'color_picker.dart';
import 'BLEconnect.dart';
// import 'BLEconnectEmulator.dart';  // use this package instead when debugging with emulated device where BLE functionality is not available


void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        selectedRowColor: Colors.red

      ),
      home: MyHomePage(title: ' Chaciáoafl Demo Home Page'),
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {

  var alarmList = new List();
  BLEconnect bleConnect = new BLEconnect();
  HSVColor currentColor = HSVColor.fromAHSV(1, 0, 1, 1);
  
  // these following command indices have in accordance with the BLE device
  var sendCommands = {
    "set_BLE_DateTime":      0,
    "set_BLE_Color":         1,
    "get_BLE_Color":         2,
    "get_BLE_Alarms":        3,
    "set_BLE_Alarms":        4,   
  };
  var receiveCommands = {
      "set_Android_Color":   0,
      "set_Android_Alarms":  1,   
  };


  void syncDateTimeWithBLEdevice() {
    var currDt = DateTime.now();
    List<int> sendBytes = [
      sendCommands["set_BLE_DateTime"],
      currDt.year % 100,
      currDt.month,
      currDt.day,
      currDt.hour,
      currDt.minute,
      currDt.second,
    ];
    bleConnect.sendData(context, sendBytes);
  }


  void directLightChangeEvent(HSVColor returnColor) {
    setState(() {
      currentColor = returnColor;
    });
    List<int> sendBytes = [
      sendCommands["set_BLE_Color"],
      currentColor.hue ~/ 2,                      // HSV hue downscaled to 0-180 units to fit in 1 byte
      (255 * currentColor.saturation).toInt(),    // HSV saturation 0-255 
      (255 * currentColor.value).toInt(),         // HSV value 0-255
    ];
    bleConnect.sendData(context, sendBytes, fastSend: true);
  }


  void getCurrentColor() {
    List<int> sendBytes = [
      sendCommands["get_BLE_Color"]
    ];
    bleConnect.sendData(context, sendBytes);
  }


  void getAlarmList() {
    List<int> sendBytes = [
      sendCommands["get_BLE_Alarms"]
    ];
    bleConnect.sendData(context, sendBytes);
  }


  void alarmListChangeEvent(VoidCallback fn) {
    setState(() {
        fn();
    });
    List<int> alarmData =  alarmsToData();
    List<int> sendBytes = [sendCommands["set_BLE_Alarms"], alarmData.length] + alarmData;
    // showAlert(context, sendBytes.toString());
    bleConnect.sendData(context, sendBytes);
  }


  List<int> alarmsToData() {
    List<int> output = [];
    alarmList.forEach((alarm) {
      int alarmData = alarm["alarmState"] ? 1 : 0;        // add on-off state
      alarmData = (alarmData << 1) + (alarm["repeatState"] ? 1 : 0);           // add repeat state
      alarm["weekdays"].forEach((key, value) {
        alarmData = (alarmData << 1) + (value ? 1 : 0);   // add repeat weekdays
      });
      alarmData = (alarmData << 5) + int.parse((alarm["alarmTime"].split(":"))[0]); // add alarm hour
      alarmData = (alarmData << 6) + int.parse((alarm["alarmTime"].split(":"))[1]); // add alarm min
      alarmData = (alarmData << 4) + 0;   //   4 bits remaining for additional information

      // splitting the data into 3 bytes and saving to list
      output.add((alarmData >> 16) & 255);                                      
      output.add((alarmData >> 8) & 255);                                      
      output.add(alarmData & 255);                                      
    });

    return output;
  }


  void returnHandler(List<int> returnValue) {
    // showAlert(context, "Data received:\n${returnValue.toString()}");
    if      (returnValue[0] == receiveCommands["set_Android_Color"])    setCurrentColor(returnValue);
    else if (returnValue[0] == receiveCommands["set_Android_Alarms"])   setAlarmList(returnValue);
  }


  void setCurrentColor(List<int> returnValue) {
    setState(() {
      currentColor = HSVColor.fromAHSV(
        1,                                  // alpha set to 1
        returnValue[1].toDouble() * 2,      // hue on BLE is scaled down from 0-360 to 0-180 to fit in 1 byte
        returnValue[2].toDouble() / 255,    // saturation on BLE is scaled to 0-255
        returnValue[3].toDouble() / 255,    // value on BLE is scaled to 0-255
      );
    });
    // showAlert(context, "color received");
  }

  
  void setAlarmList(List<int> returnValue) {
    alarmList = [];
    for (int idx = 1; idx < returnValue.length; idx = idx + 3) {
      int alarmData = (returnValue[idx] << 16) + (returnValue[idx + 1] << 8) + returnValue[idx + 2];
      var alarmInfo = {
        "alarmTime":  ((alarmData >> 10) & 31).toString().padLeft(2,'0') + ":" + ((alarmData >> 4) & 63).toString().padLeft(2,'0'),
        "alarmState": ((alarmData >> 23) & 1) == 1,
        "repeatState": ((alarmData >> 22) & 1) == 1,
        "weekdays": {
          "Mon": ((alarmData >> 21) & 1) == 1,
          "Tue": ((alarmData >> 20) & 1) == 1,
          "Wed": ((alarmData >> 19) & 1) == 1,
          "Thu": ((alarmData >> 18) & 1) == 1,
          "Fri": ((alarmData >> 17) & 1) == 1,
          "Sat": ((alarmData >> 16) & 1) == 1,
          "Sun": ((alarmData >> 15) & 1) == 1,
        },
        "mode" : (alarmData & 63),    // 4 bits remaining for additional information
      };
      setState(() => alarmList.add(alarmInfo));
    }
  }


  Row getWeekDayRow(int index) {
    Row weekDayRow = Row(
      children: [
        Spacer(),
        for (var weekDayEntry in alarmList[index]["weekdays"].entries) 
            buildWeekDayButton(
              index,
              weekDayEntry.key.toString(),
              weekDayEntry.value
            ),
        Spacer(),
      ],
    );
    return weekDayRow;
  }


  Widget buildWeekDayButton(int index, String weekday, bool state) {
    Widget weekDayButton = Container(
      margin: const EdgeInsets.all(3.0),
      width: 36.0,
      height: 36.0,
      child: FlatButton(
        color: alarmList[index]["weekdays"][weekday] ? Colors.blue : Colors.grey,
        textColor: Colors.white,
        disabledColor: Colors.grey,
        disabledTextColor: Colors.black,
        padding: EdgeInsets.all(0.0),
        splashColor: Colors.blueAccent,
        onPressed: () {
          alarmListChangeEvent(() {
            alarmList[index]["weekdays"][weekday] = !state;
            if (!(alarmList[index]["weekdays"].values.contains(true))) {
              alarmList[index]["repeatState"] = false;
            }
          });
        },
        child: Text(
          weekday,
          style: TextStyle(fontSize: 12.0),
        ),
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(20.0),
        ),
      ),
    );

    return weekDayButton;
  }


  Column buildAlarm(int index) {
    Column alarmElem = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Switch(
              value: alarmList[index]["alarmState"], 
              onChanged: (bool value) {alarmListChangeEvent(() => alarmList[index]["alarmState"] = value);},
            ),
            IconButton(
              icon: Icon(Icons.replay),
              color:  alarmList[index]["repeatState"] ? Colors.lightBlue : Colors.grey,
              onPressed: () {
                alarmListChangeEvent(() {            
                  if (!(alarmList[index]["weekdays"].values.contains(true))) {
                    // if no weekdays are selected => select all of them
                    alarmList[index]["weekdays"] = alarmList[index]["weekdays"].map((key, value) => MapEntry(key, true));
                  }
                  alarmList[index]["repeatState"] = !alarmList[index]["repeatState"];
                });
              },    
            ),
            Expanded(
              child: FlatButton(
                color: Colors.white,
                textColor: Colors.black,
                disabledColor: Colors.grey,
                disabledTextColor: Colors.black,
                padding: EdgeInsets.all(0.0),
                splashColor: Colors.blueAccent,
                onPressed: () => setAlarmTime(index),
                child: Text(
                  alarmList[index]["alarmTime"],
                  style: TextStyle(fontSize: 12.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Spacer(),
            IconButton(
              icon: Icon(Icons.delete),
              color: Colors.lightBlue,
              onPressed: ()  => confirmAlarmDelete(index),
            ),
          ],
        ),
        
        if(alarmList[index]["repeatState"]) getWeekDayRow(index),

        // For Debug purposes only:
        // Text(
        //   alarmList[index].toString(),
        //   textAlign: TextAlign.left,
        // ),

      ],
    );
    return alarmElem;
  }


  Future<void> setAlarmTime(int index) async {
    TimeOfDay initTime;
    try {
      String alarmTime = alarmList[index]["alarmTime"];
      initTime = TimeOfDay(
        hour: int.parse(alarmTime.split(":")[0]),
        minute: int.parse(alarmTime.split(":")[1])
      );
    } catch(e) {
      initTime = TimeOfDay.now();
    }
    final TimeOfDay pickedTime = await showTimePicker(
      context: context,
      initialTime: initTime,
      builder: (BuildContext context, Widget child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child,
        );
      },
    );
    if (pickedTime != null) {
      if(index >= alarmList.length) addDefaultAlarm();
      alarmListChangeEvent(() {
        alarmList[index]["alarmTime"] = "${pickedTime.hour.toString().padLeft(2,'0')}:${pickedTime.minute.toString().padLeft(2,'0')}";
        }
      );
    }
  }


  void addDefaultAlarm({List<int> init = const []}) {
    var alarmInfo = {
      "alarmTime": "01:00",
      "alarmState": true,
      "repeatState": false,
      "weekdays": {
        "Mon": true,
        "Tue": true,
        "Wed": true,
        "Thu": true,
        "Fri": true,
        "Sat": true,
        "Sun": true,
      },
      "mode": 0,  // 4 bits remaining for additional information
    };
    setState(() => alarmList.add(alarmInfo));
  }

 
  void confirmAlarmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("This is a question"),
          content: new Text("Do you really want to delete this alarm?"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("Delete"),
              onPressed:  () {
                alarmListChangeEvent(() {
                    alarmList.removeAt(index);
                    Navigator.of(context).pop();
                  }
                );
              },
            ),
          ],
        );
      },
    );
  }


  Widget tabView(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: AppBar(
            bottom: PreferredSize(
              preferredSize: Size.fromWidth(50),
              child: Row(
                children: <Widget>[
                  TabBar(
                    isScrollable: true,
                    tabs: <Widget>[
                      Tab(
                        icon: Icon(Icons.access_alarm),
                      ),
                      Tab(
                        icon: Icon(Icons.wb_sunny),
                      ),
                    ],
                  ),
                  Spacer(),
                  SizedBox(
                    width: 70,
                    child: FlatButton(
                      child: Text("Disconnect"),
                      onPressed: () => BLEconnect.disconnectBLEdevice(context),
                      // child: bleConnect.bleDeviceState(context),
                      // onPressed: () async {
                      //   bleConnect.connectBLEdevice(
                      //     context, 
                      //     returnHandler: (returnValue) => returnHandler(returnValue) 
                      //   )
                      //   .then((isConnected) {
                      //     if (isConnected) {
                      //       syncDateTimeWithBLEdevice();
                      //       getCurrentColor();
                      //       getAlarmList();
                      //     }
                      //   });
                      // },
                    )
                  )
                ],
              ) 
            )
          )  
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[
            alarmListScreen(context),
            directLight(context),
          ]
        )
      )
    );
  }


  Widget alarmListScreen(BuildContext context) {
    return Scaffold(
      body: 
        ListView.builder(
          itemCount: this.alarmList.length,
          itemBuilder: (context, index) => this.buildAlarm(index)
        ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            Spacer(),
            Container(
              margin: const EdgeInsets.all(10.0),
              width: 48.0,
              height: 48.0,
              child: FloatingActionButton(
                onPressed: () {
                  if (alarmList.length < 6) setAlarmTime(alarmList.length);
                  else showAlert(context, "You can create only up to 6 alarms.");
                },
                tooltip: 'Add alarm',
                child: Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget directLight(BuildContext context) {
    return ColorPicker(
      barCornerRadius: 10,
      initialColor: currentColor,
      colorListener: (HSVColor returnColor) => directLightChangeEvent(returnColor),
    );
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


  @override
  Widget build(BuildContext context) {
    return bleConnect.withBLEconnected(
      context,
      onConnect: () {
        syncDateTimeWithBLEdevice();
        getCurrentColor();
        getAlarmList();
      },
      whileConnected: () => tabView(context),
      returnHandler: (returnValue) => returnHandler(returnValue) 
      );
  }
}

