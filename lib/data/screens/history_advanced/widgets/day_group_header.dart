import 'package:flutter/material.dart';
import 'package:uconnect/provider/color_provider.dart';

class DayGroupHeader extends StatefulWidget {
  final String dayKey;
  final int eventCount;
  final ColorProvider colorProvider;

  const DayGroupHeader({
    Key? key,
    required this.dayKey,
    required this.eventCount,
    required this.colorProvider,
  }) : super(key: key);

  @override
  _DayGroupHeaderState createState() => _DayGroupHeaderState();
}

class _DayGroupHeaderState extends State<DayGroupHeader> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.colorProvider.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.colorProvider.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: widget.colorProvider.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  widget.dayKey,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.colorProvider.primaryColor,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.colorProvider.secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.eventCount} eventos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: widget.colorProvider.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}










