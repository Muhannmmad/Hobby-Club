import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoppy_club/config/config.dart';
import 'package:hoppy_club/features/registeration/screens/signup.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  StartScreenState createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen> {
  late VideoPlayerController controller;
  String selectedLanguage = 'English'; // Default language

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.asset('assets/videos/video.mp4')
      ..initialize().then((_) {
        controller.setLooping(true);
        controller.setVolume(0.0);
        controller.play();

        setState(() {});
      });
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveLanguagePreference(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 100,
                      width: 100,
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
                      textStyle: Theme.of(context).textTheme.displayLarge,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: const Color.fromARGB(205, 67, 7, 82),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Subtitle
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Text(
                          "Meet new people around you",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Let's chat, let's enjoy",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Language Dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButton<String>(
                      value: selectedLanguage,
                      icon: const Icon(Icons.language, color: Colors.white),
                      dropdownColor: darkpurble,
                      style: const TextStyle(color: Colors.white),
                      underline: Container(), // Removes the underline
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedLanguage = newValue;
                          });
                          _saveLanguagePreference(newValue);
                        }
                      },
                      items: <String>['English', 'German', 'Arabic']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),

                  const Spacer(),

                  // Start Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: darkpurble,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Let's Start",
                      style: TextStyle(
                        fontSize: 20,
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
