import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoppy_club/features/home/widgets/hobbies_card.dart';
import 'package:hoppy_club/features/registeration/screens/login.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';
import 'package:hoppy_club/features/home/repository/hobby.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  String userName = '';

  @override
  void initState() {
    super.initState();
    fetchUserName();
    updateOnesignalID();
  }

  Future<void> updateOnesignalID() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await OneSignal.User.pushSubscription.optIn();
    final userData = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    String currentOnesignalID =
        (userData.data() as Map<String, dynamic>)["onesignalID"] ?? "";
    if (OneSignal.User.pushSubscription.id != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"onesignalID": OneSignal.User.pushSubscription.id});
      print("Updating OnesignalID: ${OneSignal.User.pushSubscription.id}");
    }
    OneSignal.User.pushSubscription.addObserver((state) async {
      if (state.current.id != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"onesignalID": state.current.id});
      }
      print("Updating OnesignalID: ${state.current.id}");
    });
    print("Tst");
  }

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userName = userDoc.data()?['firstName'] ?? 'User';
      });
    } catch (e) {
      debugPrint('Failed to fetch user name: $e');
    }
  }

  void logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isOnline': false,
        });

        await FirebaseAuth.instance.signOut();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } catch (e) {
        debugPrint('Error during logout: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.030,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.spicyRice(
                                fontSize: screenWidth * 0.03,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              '❤️',
                              style: TextStyle(fontSize: screenWidth * 0.03),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Log out',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.logout,
                              color: Colors.black, size: screenWidth * 0.06),
                          onPressed: logout,
                          tooltip: 'Log out',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.00),
              Center(
                child: Text(
                  'Hobby Club',
                  style: GoogleFonts.spicyRice(
                    fontSize: screenWidth * 0.10,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: const Color.fromARGB(205, 67, 7, 82),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              _buildCategoryBox('Indoor Hobbies', screenWidth),
              HobbiesCard(hobbies: indoorHobbies),
              SizedBox(height: screenHeight * 0.02),
              _buildCategoryBox('Outdoor Hobbies', screenWidth),
              HobbiesCard(hobbies: outdoorHobbies),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(selectedIndex: selectedIndex),
      ),
    );
  }

  Widget _buildCategoryBox(String title, double screenWidth) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.040,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
