import 'dart:async';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _Element {
  background,
  backgroundTransparent,
  hours,
  hoursFill,
  minutes,
  minutesFill,
  ampm,
  day,
}

final _lightTheme = {
  _Element.background: Color(0xffcccccc),
  _Element.backgroundTransparent: Color(0x00cccccc),
  _Element.hours: Color(0xffffffff),
  _Element.hoursFill: Color(0xff60a0e0),
  _Element.minutes: Color(0xfff4f4f4),
  _Element.minutesFill: Color(0xff64a2e0),
  _Element.ampm: Color(0xffd4d4d4),
  _Element.day: Color(0xfff6f6f6),
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.backgroundTransparent: Color(0x00000000),
  _Element.hours: Color(0xffffffff),
  _Element.hoursFill: Color(0xff4488ee),
  _Element.minutes: Color(0xfff4f4f4),
  _Element.minutesFill: Color(0xff4080e0),
  _Element.ampm: Color(0xffa0a0a0),
  _Element.day: Color(0xfff6f6f6),
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock>
    with TickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  // Amout of fill for each digit
  List<double> _fills = new List(4);
  // Animation controller for each digit (animates amount of fill changes)
  List<AnimationController> _controllers = new List(4);
  // Animation duration
  Duration _duration = const Duration(seconds: 1);

  @override
  void initState() {
    super.initState();

    // Prepare animation controllers
    for (var i = 0; i < 4; i++) {
      _fills[i] = -1;
      _controllers[i] = new AnimationController(
        value: 0,
        vsync: this,
      )..addListener(() {
          setState(() {});
        });
    }

    // Start
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();

      // Get hours in requested format (12 or 24)
      final hourNum =
          widget.model.is24HourFormat ? _dateTime.hour : _dateTime.hour % 12;
      final hourDiv = widget.model.is24HourFormat
          ? (hourNum > 20 ? 4 : 10)
          : (hourNum > 10 ? 2 : 10);

      // Get amount of fill for each digit
      final fills = [
        (hourNum % 10) / hourDiv,
        (_dateTime.minute / 10).floor() / 6,
        (_dateTime.minute % 10) / 10,
        (_dateTime.second / 10).floor() / 6,
      ];

      // Start animation for digits whose amount of fill has changed
      for (var i = 0; i < 4; i++) {
        if (fills[i] != _fills[i]) {
          _controllers[i]
              .animateTo(fills[i], duration: _duration, curve: Curves.ease);
          _fills[i] = fills[i];
        }
      }

      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get colors for current theme (dark/light)
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;

    // Get hours as string in 12 or 24 hour format
    final is24 = widget.model.is24HourFormat;
    final hour = DateFormat(is24 ? 'HH' : 'hh').format(_dateTime);
    // Get minutes as string
    final minute = DateFormat('mm').format(_dateTime);
    // Get AM/PM string
    final ampm = DateFormat(is24 ? '' : 'a').format(_dateTime);
    // Get full day name in uppercase
    final day = DateFormat('EEEE').format(_dateTime).toUpperCase();

    // Shadows cast by bigger text (hours/minutes digits)
    final shadowsBig = [_getShadow(12, .5)];
    // Shadow cast by smaller text (AM/PM indicator and day name)
    final shadowsSmall = [shadowsBig[0], _getShadow(6, .4)];

    // Text style used to draw hours digits
    final hourStyle = _getStyle(colors[_Element.hours], 500, shadowsBig);
    // Text style used to draw minutes digits
    final minuteStyle = _getStyle(colors[_Element.minutes], 375, shadowsBig);
    // Text style used to draw AM/PM indicator
    final ampmStyle = _getStyle(colors[_Element.ampm], 50, shadowsSmall);
    // Text style used to draw day name
    final dayStyle = _getStyle(colors[_Element.day], 50, shadowsSmall);

    // Day name split into array of latters
    var dayLetters = <Widget>[];
    for (var i = 0; i < day.length; i++) {
      dayLetters.add((Spacer()));
      dayLetters.add(Center(child: Text(day[i], style: dayStyle)));
    }

    // Gradient for hours digits (used to fill digit with blue color)
    final hourGradient =
        _getGradient(colors[_Element.hours], colors[_Element.hoursFill]);
    // Gradient for minutes digits (used to fill digit with blue color)
    final minuteGradient =
        _getGradient(colors[_Element.minutes], colors[_Element.minutesFill]);

    // Gradient rectangles (defines how much is each digit filled)
    final rects = [
      Rect.fromLTWH(0, 479 - 400 * _controllers[0].value, 0, 1),
      Rect.fromLTWH(0, 479 - 400 * _controllers[1].value, 0, 1),
      Rect.fromLTWH(0, 358 - 300 * _controllers[2].value, 0, 1),
      Rect.fromLTWH(0, 358 - 300 * _controllers[3].value, 0, 1)
    ];
    // Gradient shaders (draws digit color/fill)
    final shaders = [
      hourGradient.createShader(rects[0]),
      hourGradient.createShader(rects[1]),
      minuteGradient.createShader(rects[2]),
      minuteGradient.createShader(rects[3]),
    ];

    return FittedBox(
        fit: BoxFit.cover,
        child: Container(
          width: 1000,
          height: 600,
          color: colors[_Element.background],
          child: Center(
            child: Stack(children: <Widget>[
              // Hours (first digit)
              Positioned(
                  left: hour[0] == '1' ? 64 : 40,
                  width: 320,
                  top: 10,
                  child: _getDigit(hour[0], shaders[0], hourStyle)),

              // Hours (second digit)
              Positioned(
                  left: hour[1] == '1' ? 344 : 320,
                  width: 320,
                  top: 10,
                  child: _getDigit(hour[1], shaders[1], hourStyle)),

              // Hours (second digit shade)
              Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-.975, -.35),
                        radius: 1,
                        stops: [0.7, 1],
                        colors: [
                          colors[_Element.backgroundTransparent],
                          colors[_Element.background],
                        ],
                      ),
                    ),
                  )),

              // Minutes (first digit)
              Positioned(
                  left: minute[0] == '1' ? 528 : 510,
                  width: 240,
                  top: 40,
                  child: _getDigit(minute[0], shaders[2], minuteStyle)),

              // Minutes (second digit)
              Positioned(
                  left: minute[1] == '1' ? 738 : 720,
                  width: 240,
                  top: 40,
                  child: _getDigit(minute[1], shaders[3], minuteStyle)),

              // AM/PM
              Positioned(
                  left: 480,
                  width: 100,
                  top: 420,
                  child: Center(child: Text(ampm, style: ampmStyle))),

              // Day name
              Positioned(
                  left: 610,
                  width: 320,
                  top: 420,
                  child: Row(children: dayLetters))
            ]),
          ),
        ));
  }

  Widget _getDigit(String digit, Shader shader, TextStyle style) {
    return ShaderMask(
        shaderCallback: (Rect bounds) {
          return shader;
        },
        child: Center(child: Text(digit, style: style)));
  }

  Gradient _getGradient(Color normalColor, Color fillColor) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[normalColor, fillColor],
    );
  }

  Shadow _getShadow(double radius, double alpha) {
    return Shadow(
      blurRadius: radius,
      color: Colors.black.withOpacity(alpha),
      offset: Offset(0, 0),
    );
  }

  TextStyle _getStyle(Color color, double size, List<Shadow> shadows) {
    return TextStyle(
      color: color,
      fontFamily: 'Arial',
      fontSize: size,
      fontWeight: FontWeight.bold,
      shadows: shadows,
    );
  }
}
