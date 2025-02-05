import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoppy_club/features/registeration/screens/signup.dart';
import 'package:video_player/video_player.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  StartScreenState createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.asset('assets/video.mp4')
      ..initialize().then((_) {
        controller.setLooping(true);
        controller.setVolume(0.0);
        controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const double baseWidth = 375; // Reference mobile width
    final double scaleFactor = screenSize.width / baseWidth;

    return Scaffold(
      body: Stack(
        children: [
          // Background Video
          controller.value.isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),

          // Foreground Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Padding(
                    padding: EdgeInsets.all(16.0 * scaleFactor),
                    child: SizedBox(
                      height: 60 * scaleFactor,
                      width: 60 * scaleFactor,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/icons/Group 3052.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'Hobby Club',
                    style: GoogleFonts.spicyRice(
                      fontSize: 30 * scaleFactor,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: const Color.fromARGB(205, 67, 7, 82),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Subtitle
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0 * scaleFactor),
                    child: Column(
                      children: [
                        Text(
                          "Meet new people around you",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18 * scaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Let's chat, let's enjoy",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20 * scaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Spacer(),

                  // Start Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20 * scaleFactor,
                        vertical: 8 * scaleFactor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: const Color(0xFF431852),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Let's Start",
                      style: TextStyle(
                        fontSize: 20 * scaleFactor,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
