import 'dart:math';
import 'package:flutter/material.dart';


/// A listener which receives an color in int representation. as used
/// by [BarColorPicker.colorListener] and [CircleColorPicker.colorListener].
typedef ColorListener = void Function(HSVColor currentColor);

/// Constant color of thumb shadow
const _kThumbShadowColor = Color(0x44000000);

/// A padding used to calculate bar height(barThumbRadius * 2 - kBarPadding).
const _kBarPadding = 4;


/// A circle palette color picker.
class ColorPicker extends StatefulWidget {
  // radius of the color palette, note that circRadius * 2 is not the final
  // width of this widget, instead is (circRadius + circThumbRadius) * 2.
  final double circRadius;

  /// thumb fill color.
  final Color circThumbColor;

  /// radius of thumb.
  final double circThumbRadius;

  /// width of bar, if this widget is horizontal, than
  /// bar width is this value, if this widget is vertical
  /// bar height is this value
  final double barWidth;

  /// corner radius of the picker bar, for each corners
  final double barCornerRadius;

  /// thumb fill color
  final Color barThumbColor;

  /// radius of thumb
  final double barThumbRadius;

  /// A listener receives color pick events.
  final ColorListener colorListener;

  /// initial color of this color picker.
  final HSVColor initialColor;

  ColorPicker({
    Key key,
    this.circRadius = 120,
    this.circThumbRadius = 8,
    this.circThumbColor = Colors.black,
    this.barWidth = 200,
    this.barCornerRadius = 0.0,
    this.barThumbRadius = 8,
    this.barThumbColor = Colors.black,
    this.initialColor = const HSVColor.fromAHSV(1, 0, 0, 0.5),
    @required this.colorListener
  })
    : assert(circRadius != null),
      assert(circThumbColor != null),
      assert(barWidth != null),
      assert(barCornerRadius != null),
      assert(initialColor != null),
      assert(colorListener != null),
      super(key: key);


  @override
  State<ColorPicker> createState() {
    return _ColorPickerState();
  }

}

class _ColorPickerState extends State<ColorPicker> {
  // Color currentColor;
  
  static const List<Color> circColors = [
    Color(0xffff0000),
    Color(0xffffff00),
    Color(0xff00ff00),
    Color(0xff00ffff),
    Color(0xff0000ff),
    Color(0xffff00ff),
    Color(0xffff0000)
  ];
  static double maxSaturation = 0.5;
  static List<Color> circColorsSaturationOverlay = [
    Color(0xffffffff),
    Color(0xffffffff).withAlpha(255 - (255*maxSaturation).toInt()),
  ];

  double circThumbRadians, circThumbDistanceToCenter;
  double hue, saturation;

  double percent;
  List<Color> barColors;
  double barWidth, barHeight;


  @override
  void initState() {
    super.initState();

    hue = widget.initialColor.hue;
    circThumbRadians = degreesToRadians(240 - hue);
    saturation = widget.initialColor.saturation;
    circThumbDistanceToCenter = saturation * widget.circRadius;
    
    percent = widget.initialColor.value;

    barWidth = widget.barWidth;
    barHeight = widget.barThumbRadius * 2 - _kBarPadding;
    barColors = [
                  Color(0xff000000),
                  HSVColor.fromAHSV(1, hue, saturation*maxSaturation, 1).toColor()
                ];
  }


  @override
  Widget build(BuildContext context) {
    final double circRadius = widget.circRadius;
    final double circThumbRadius = widget.circThumbRadius;

    // compute circThumb center coordinate
    double circThumbCenterX = circRadius +
      circThumbDistanceToCenter * sin(circThumbRadians);
    double circThumbCenterY = circRadius +
      circThumbDistanceToCenter * cos(circThumbRadians);

    // build thumb widget
    Widget circThumb = Positioned(
      left: circThumbCenterX,
      top: circThumbCenterY,
      child: Container(
        width: circThumbRadius * 2,
        height: circThumbRadius * 2,
        decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _kThumbShadowColor,
              spreadRadius: 2,
              blurRadius: 3,
            )
          ],
          color: widget.circThumbColor,
          borderRadius: BorderRadius.all(Radius.circular(circThumbRadius))
        ),
      )
    );

    final double barThumbRadius = widget.barThumbRadius;
    // compute barThumb coordinate
    double barThumbLeft = barWidth * percent;

    // build thumb
    Widget barThumb = Positioned(
      left: barThumbLeft,
      child: Container(
        width: barThumbRadius * 2,
        height: barThumbRadius * 2,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _kThumbShadowColor,
              spreadRadius: 2,
              blurRadius: 3,
            )
          ],
          color: widget.barThumbColor,
          borderRadius: BorderRadius.all(Radius.circular(barThumbRadius))
        ),
      )
    );

    // build frame
    double frameWidth, frameHeight;
    frameWidth = barWidth + barThumbRadius * 2;
    frameHeight = barThumbRadius * 2;
    Widget frame = SizedBox(width: frameWidth, height: frameHeight);

    // build content
    Gradient gradient;
    double left, top;
    gradient = LinearGradient(colors: barColors);
    left = barThumbRadius;
    top = (barThumbRadius * 2 - barHeight) / 2;

    Widget content = Positioned(
      left: left,
      top: top,
      child: Container(
        width: barWidth,
        height: barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(widget.barCornerRadius)),
          gradient: gradient
        ),
      ),
    );

    return Scaffold(
      body:  Align(
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            Container(
              width: 150,
              height: 34,
              color: HSVColor.fromAHSV(1, hue, saturation*maxSaturation, percent).toColor(),
              alignment: Alignment.center,
              child: Text(HSVColor.fromAHSV(1, hue, saturation*maxSaturation, percent)
                          .toColor()
                          .value
                          .toRadixString(16)
                          .toUpperCase()),
            ),
            Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) => handleTouchCirc(details.localPosition, context),
              onPanStart: (details) => handleTouchCirc(details.localPosition, context),
              onPanUpdate: (details) => handleTouchCirc(details.localPosition, context),
              child: Stack(
                children: <Widget>[
                  SizedBox(
                    width: (circRadius + circThumbRadius) * 2,
                    height: (circRadius + circThumbRadius) * 2
                  ),
                  // Ground colors of the circular color picker
                  Positioned(
                    left: circThumbRadius,
                    top: circThumbRadius,
                    child: Container(
                      width: circRadius * 2,
                      height: circRadius * 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(circRadius)),
                        gradient: SweepGradient(colors: circColors, transform: GradientRotation(pi/6))
                      ),
                    ),
                  ),
                  // Overlay for HSV saturation 
                  Positioned(
                    left: circThumbRadius,
                    top: circThumbRadius,
                    child: Container(
                      width: circRadius * 2,
                      height: circRadius * 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(circRadius)),
                        gradient: RadialGradient(colors: circColorsSaturationOverlay)
                      ),
                    ),
                  ),
                  circThumb,
                  Text([
                      (hue~/2),
                      (255 * saturation).toInt(),
                      (255 * percent).toInt()
                    ].toString()
                  )
                ],
              ),
            ),
            Spacer(),
            GestureDetector(
              onPanDown: (details) => handleTouchBar(details.localPosition, context),
              onPanStart: (details) => handleTouchBar(details.localPosition, context),
              onPanUpdate: (details) => handleTouchBar(details.localPosition, context),
              child: Stack(children: [frame, content, barThumb]),
            ),
            Spacer()
          ]
        )
      )
    );
  }


  /// calculate colors picked from palette and update our states.
  void handleTouchCirc(Offset localPosition, BuildContext context) {
    final double centerX = (widget.circRadius + widget.circThumbRadius);
    final double centerY = (widget.circRadius + widget.circThumbRadius);
    final double deltaX = localPosition.dx - centerX;
    final double deltaY = localPosition.dy - centerY;
    circThumbDistanceToCenter = sqrt(deltaX * deltaX + deltaY * deltaY);
    circThumbDistanceToCenter = min(circThumbDistanceToCenter, widget.circRadius);
    circThumbRadians = atan2(deltaX, deltaY);
    hue = 240 - radiansToDegrees(circThumbRadians);
    if (hue < 0) hue = 360 + hue;
    saturation = min(max(0.0, circThumbDistanceToCenter/widget.circRadius), 1); 

    widget.colorListener(HSVColor.fromAHSV(1, hue, saturation, percent));
    setState(() {
      barColors = [
                    Color(0xff000000),
                    HSVColor.fromAHSV(1, hue, saturation*maxSaturation, 1).toColor()
                  ];
    });
  }


  /// calculate colors picked from palette and update our states.
  void handleTouchBar(Offset localPosition, BuildContext context) {
    percent = (localPosition.dx - widget.barThumbRadius) / barWidth;
    percent = min(max(0.0, percent), 1.0);
    widget.colorListener(HSVColor.fromAHSV(1, hue, saturation, percent));
  }
  

  /// convert an angle value from radian to degree representation.
  double radiansToDegrees(double radians) {
    return (radians + pi) / pi * 180;
  }


  /// convert an angle value from degree to radian representation.
  double degreesToRadians(double degrees) {
    return degrees / 180 * pi - pi;
  }

}