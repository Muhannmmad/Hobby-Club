import 'dart:ui';

import 'package:flutter/material.dart';

class ClipRRectButton extends StatelessWidget {
  final VoidCallback onFavoritePressed;
  final VoidCallback onChatPressed;
  final VoidCallback onClosePressed;
  final double buttonSize;

  const ClipRRectButton({
    Key? key,
    required this.onFavoritePressed,
    required this.onChatPressed,
    required this.onClosePressed,
    this.buttonSize = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Button size: $buttonSize");
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        bottomLeft: Radius.circular(30),
      ),
      child: Container(
        width: buttonSize,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 30,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite),
                  color: Colors.white,
                  iconSize: buttonSize / 2,
                  onPressed: onFavoritePressed,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_rounded),
                  color: Colors.white,
                  iconSize: buttonSize / 2,
                  onPressed: onChatPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  iconSize: buttonSize / 2,
                  onPressed: onClosePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
