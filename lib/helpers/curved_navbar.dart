import 'package:flutter/material.dart';
import 'package:adhd_tracker/ui/representation/mood/mood_chart.dart';
import 'package:adhd_tracker/utils/color.dart';
import 'package:provider/provider.dart';
import 'package:adhd_tracker/ui/home/record/medication.dart';
import 'package:adhd_tracker/ui/home/record/symptom.dart';

class CustomCurvedNavigationBar extends StatelessWidget {
  const CustomCurvedNavigationBar({
    super.key,
    required this.items,
    required this.onTap,
    this.selectedColor = AppTheme.upeiRed,
    this.unselectedColor = Colors.black,
    this.currentIndex = 0,
  }) : assert(
          items.length == 4,
          'The correct functioning of this widget depends on its items being exactly 4',
        );

  final List<CurvedNavigationBarItem> items;
  final ValueChanged<int>? onTap;
  final Color unselectedColor;
  final Color selectedColor;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      
      height: 80,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background with curved navigation
          Positioned(
            bottom: 0,
            left: 0,
            child: SizedBox(
              width: size.width,
              height: 70,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: _CurvedPainter(),
                    size: Size(size.width, 80),
                  ),
                  SizedBox(
                    height: 90,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        items.length,
                        (index) {
                          final item = items[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: (index == 0 || index == 3) ? 20.0 : 0,
                            ),
                            child: IconButton(
                              onPressed: () => onTap?.call(index),
                              color: index == currentIndex
                                  ? selectedColor
                                  : unselectedColor,
                              icon: Icon(
                                index == currentIndex
                                    ? item.selectedIconData ?? item.iconData
                                    : item.iconData,
                              ),
                            ),
                          );
                        },
                      )..insert(2, SizedBox(width: size.width * 0.20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Centered Add Button with original styling
          Positioned(
            top: -5, // Adjusted to prevent cutting off
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(180)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.upeiRed.withOpacity(0.4),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SymptomLogging(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.upeiRed,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    elevation: 4,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedNavigationBarItem {
  final IconData iconData;
  final IconData? selectedIconData;

  CurvedNavigationBarItem({required this.iconData, this.selectedIconData});
}

class _CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, -30);
    path.quadraticBezierTo(size.width * 0.20, 0, size.width * 0.35, 0);
    path.quadraticBezierTo(size.width * 0.40, 0, size.width * 0.40, 20);
    path.arcToPoint(Offset(size.width * 0.60, 20),
        radius: const Radius.elliptical(6, 4), clockwise: false);
    path.quadraticBezierTo(size.width * 0.60, 0, size.width * 0.65, 0);
    path.quadraticBezierTo(size.width * 0.80, 0, size.width, -30);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, -30);
    canvas.drawShadow(path, Colors.black, 5, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}