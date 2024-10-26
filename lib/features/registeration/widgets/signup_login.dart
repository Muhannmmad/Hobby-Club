import 'package:flutter/material.dart';

class IconScroller extends StatelessWidget {
  final List<String> assetImages = [
    'assets/google.png',
    'assets/icons/facebook.png',
    'assets/icons/apple-logo.png',
    'assets/icons/whatsapp-logo-4456.png',
  ];

  IconScroller({super.key});

  void handleTap(BuildContext context, int index) {
    switch (index) {
      case 0:
      case 1:
      case 2:
      case 3:
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: assetImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: GestureDetector(
              onTap: () => handleTap(context, index),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Image.asset(
                      assetImages[index],
                      fit: BoxFit.contain,
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
