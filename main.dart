import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';


void main() => runApp(new SvancyApp());

class SvancyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Svancy Settings',
      theme: new ThemeData(
        //primarySwatch: Colors.blue,
       primaryColor: new Color.fromRGBO(1, 68, 33, 1.0)
      ),
      home: new SettingsPage(title: 'Svancy Settings',apiRoot: 'http://192.168.1.1'),
    );
  }
}

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.title, this.apiRoot}) : super(key: key);
  final String title;
  final String apiRoot;

  @override
  _SettingsPageState createState() => new _SettingsPageState();
}

enum ResultStatus {
  settingsuccess,
  validationfail,
  submitsuccess,
  failure,
  loading,
}


class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  List<String> _colors = <String>['', 'red', 'green', 'blue', 'orange'];
  String _color = '';

  List<String> _distlist = <String>['','1', '2', '3', '4', '5', '6', '7', '8'];
  String _dist = '';

  List<String> _photolist = <String>['','1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  String _photo = '';

  List<String> _twplist = <String>['','1', '2', '3', '4', '5', '6', '7','8','9','10'];
  String _twp = '';

  List<String> _twrlist = <String>['','10', '20', '30', '40', '50', '60', '70', '80', '90', '100', '110', '120'];
  String _twr = '';

  //bool _datecheck = false; //checkbox to sync svancy time to mobile time
  bool _eepromcheck = false; //save setting in RTC eeprom
  ResultStatus _status;

  String timedisplay = 'Time Not Available';


  Future getSettings() async {
    /*var response = await http.get(
        Uri.encodeFull("https://api.github.com/users"),
        headers: {"Accept": "application/json"}); */
    try {
      var response = await http.get('${widget.apiRoot}/sg');

      if (response.statusCode != 200) {
        setState(() {
          _status = ResultStatus.failure;
        });
      } else {
        setState(() {
          _status = ResultStatus.settingsuccess;

          //decoding of response is at two places settingsuccess and submitsuccess
          var settingdata = json.decode(response.body);

          _dist = settingdata['p'][0].toString();
          _photo = settingdata['p'][1].toString();
          _twp = settingdata['p'][2].toString();
          _twr = settingdata['p'][3].toString();

          if (settingdata['p'][4] == 1)
            _eepromcheck = true;
          else
            _eepromcheck = false;

          timedisplay = settingdata['t'][0].toString().padLeft(2, '0') + ':' +
              settingdata['t'][1].toString().padLeft(2, '0') + ':' +
              settingdata['t'][2].toString().padLeft(2, '0') +
              ' - ' +
              settingdata['t'][3].toString().padLeft(2, '0') + '/' +
              settingdata['t'][4].toString().padLeft(2, '0') + '/' +
              settingdata['t'][5].toString();
        });
      }
    } catch (e) {
      setState(() {
        _status = ResultStatus.failure;
      });
    };

  }


  @override
  void initState() {
    _status = null;
    //var response1 = http.get('${widget.apiRoot}/sg');
    this.getSettings();
  }



    Future submit_settings() async {
    if (_dist == '' || _photo == '' || _twp == '' || _twr == ''){
      setState(() {
        _status = ResultStatus.validationfail;
      });
      return;
    }

    setState(() {
      _status = ResultStatus.loading;
    });

    try {
      //format parameters string ddppttTTT

      String distsend = _dist.padLeft(2,'0'); //dd
      String photosend = _photo.padLeft(2,'0'); //pp
      String twpsend = _twp.padLeft(2,'0');  //tt
      String twrsend = _twr.padLeft(3,'0'); //TTT

      String eepromsend = 'F';
      if (_eepromcheck)
        eepromsend = 'T';

      var response;

      if(_eepromcheck)
        response = await http.get('${widget.apiRoot}/sp$distsend$photosend$twpsend$twrsend$eepromsend');
      else
        response = await http.get('${widget.apiRoot}/sp$distsend$photosend$twpsend$twrsend');

      //format date string ddmmyyyy
      //if (_datecheck) {

      String day = (new DateFormat.d().format(new DateTime.now())).padLeft(2,'0');
      String month = (new DateFormat.M().format(new DateTime.now())).padLeft(2,'0');
      String year = new DateFormat.y().format(new DateTime.now());

      String hour = (new DateFormat.H().format(new DateTime.now())).padLeft(2,'0');
      String min = (new DateFormat.m().format(new DateTime.now())).padLeft(2,'0');
      String sec = (new DateFormat.s().format(new DateTime.now())).padLeft(2,'0');

      int dow = new DateTime.now().weekday;

      response = await http.get('${widget.apiRoot}/sd$dow$day$month$year');
      //sleep(const Duration(microseconds: 100));
      response = await http.get('${widget.apiRoot}/st$hour$min$sec');
      //}

      if (response.statusCode != 200) {
        setState(() {
          _status = ResultStatus.failure;
        });

             } else {
        setState(() {

          _status = ResultStatus.submitsuccess;

          //decoding of response is at two places settingsuccess and submitsuccess
          var settingdata = json.decode(response.body);

          _dist = settingdata['p'][0].toString();
          _photo = settingdata['p'][1].toString();
          _twp = settingdata['p'][2].toString();
          _twr = settingdata['p'][3].toString();

          if(settingdata['p'][4] == 1)
             _eepromcheck = true;
          else
            _eepromcheck = false;

          timedisplay = settingdata['t'][0].toString().padLeft(2,'0')+':'+
              settingdata['t'][1].toString().padLeft(2,'0')+':'+
              settingdata['t'][2].toString().padLeft(2,'0')+
              ' - '+
              settingdata['t'][3].toString().padLeft(2,'0')+'/'+
              settingdata['t'][4].toString().padLeft(2,'0')+'/'+
              settingdata['t'][5].toString();

        });
      }
    } catch (e) {
      setState(() {
        _status = ResultStatus.failure;
      });
    };
  }


  Widget buildTimeContent(BuildContext context) {

    return new InputDecorator(
      decoration: const InputDecoration(
        icon: const Icon(Icons.hourglass_empty),
        labelText: 'Current Time in Svnacy',
      ),
      child: new Text(
        timedisplay,
        //style: new TextStyle(color: Colors.red),
      ),
    );
  }

  Widget buildResponseContent(BuildContext context) {
    if (_status != null) {
      switch (_status) {
        case ResultStatus.validationfail:
          return new Center(
            child: new Text(
              'Setting Cannot be Blank, Please Check...',
              style: new TextStyle(color: Colors.red),
            ),
          );
        case ResultStatus.settingsuccess:
          return new Center(
            child: new Text(
              'Current Settings of Svancy',
              style: new TextStyle(color: Colors.green),
            ),
          );
        case ResultStatus.submitsuccess:
          return new Center(
            child: new Text(
              'Successfully Saved to Svancy',
              style: new TextStyle(color: Colors.green),
            ),
          );

        case ResultStatus.failure:
          return new Center(
            child: new Text(
              'Cannot Connect to Svancy.. Check WiFi',
              style: new TextStyle(color: Colors.red),
            ),
          );
        case ResultStatus.loading:
          return new Center(
            child: new Text('Connecting to Svancy...'),
          );
      }
    }

    return new Container();
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new SafeArea(
          top: false,
          bottom: false,
          child: new Form(
              key: _formKey,
              autovalidate: true,
              child: new ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: <Widget>[
                  new InputDecorator(
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.directions_run),
                      hintText: 'Distance (ft) Between Svancy and Animal',
                      labelText: 'Distance (ft)',
                    ),
                    //isEmpty: _dist == '3',
                    child: new DropdownButtonHideUnderline(
                      child: new DropdownButton<String>(
                        value: _dist,
                        isDense: true,
                        onChanged: (String newValue) {
                          setState(() {
                            _dist = newValue;
                          });
                        },
                        items: _distlist.map((String value) {
                          return new DropdownMenuItem<String>(
                            value: value,
                            child: new Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  new InputDecorator(
                      decoration: const InputDecoration(
                        icon: const Icon(Icons.camera_alt),
                        hintText: 'Number of Photos to be taken',
                        labelText: 'Number of Photos',
                      ),
                      //isEmpty: _photo == '',
                      child: new DropdownButtonHideUnderline(
                          child: new DropdownButton<String>(
                            value: _photo,
                            isDense: true,
                            onChanged: (String newValue) {
                              setState(() {
                                _photo = newValue;
                              });
                            },
                            items: _photolist.map((String value) {
                              return new DropdownMenuItem<String>(
                                value: value,
                                child: new Text(value),
                              );
                            }).toList(),
                          ),
                      ),
                  ),

                  new InputDecorator(
                      decoration: const InputDecoration(
                        icon: const Icon(Icons.timelapse),
                        hintText: 'Time To Wait Between Photos',
                        labelText: 'Time Between Photos (secs)',
                      ),
                      //isEmpty: _twp == '',
                      child: new DropdownButtonHideUnderline(
                          child: new DropdownButton<String>(
                            value: _twp,
                            isDense: true,
                            onChanged: (String newValue) {
                              setState(() {
                                _twp = newValue;
                              });
                            },
                            items: _twplist.map((String value) {
                              return new DropdownMenuItem<String>(
                                value: value,
                                child: new Text(value),
                              );
                            }).toList(),
                          ),
                      ),
                  ),

                  new InputDecorator(
                      decoration: const InputDecoration(
                        icon: const Icon(Icons.av_timer),
                        hintText: 'Time To Wait Between Next Detection',
                        labelText: 'Re-Detection Timer (secs)',
                      ),
                      //isEmpty: _twr == '',
                      child: new DropdownButtonHideUnderline(
                          child: new DropdownButton<String>(
                            value: _twr,
                            isDense: true,
                            onChanged: (String newValue) {
                              setState(() {
                                _twr = newValue;
                              });
                            },
                            items: _twrlist.map((String value) {
                              return new DropdownMenuItem<String>(
                                value: value,
                                child: new Text(value),
                              );
                            }).toList(),
                          ),
                      ),
                  ),

                  buildTimeContent(context),

                  /*new Row(
                    children: <Widget>[
                      new Checkbox(value: _datecheck, onChanged: (bool value){
                        setState(() {
                          _datecheck = value;
                        });
                      }),
                      new Text('Set Svancy Time to Mobile Time'),
                    ],
                  ), */
                  new Center(
                    child: new Text(
                      'Svancy Time will sync with Mobile Time',
                      style: new TextStyle(color: Colors.green),
                    ),
                  ),

                  new Row(
                    children: <Widget>[
                      new Checkbox(value: _eepromcheck, onChanged: (bool value){
                        setState(() {
                          _eepromcheck = value;
                        });
                      }),
                      new Text('Save Settings After Poweroff'),
                    ],
                  ),

                  new Container(
                      padding: const EdgeInsets.only(left: 40.0, top: 20.0),
                      child: new RaisedButton(
                          color: new Color.fromRGBO(1, 68, 33, 0.9),
                          child: const Text('Save'),
                          textColor: Colors.white,
                          onPressed: () =>submit_settings(),
                      )
                  ),
                  new SizedBox(height: 10.0),
                  buildResponseContent(context),

                ],
              ))),
    );
  }
}