import 'package:flutter/material.dart';

class BlinkingDotIndicator extends StatefulWidget {
  final double size;
  final Color color;

  BlinkingDotIndicator(
      {@required double this.size, @required Color this.color});

  @override
  _BlinkingDotIndicatorState createState() => _BlinkingDotIndicatorState();
}

class _BlinkingDotIndicatorState extends State<BlinkingDotIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  @override
  void initState() {
    _animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 500));
    _animationController.repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        decoration: new BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.all(
            Radius.circular(
              widget.size * 0.5,
            ),
          ),
        ),
        width: widget.size,
        height: widget.size,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
