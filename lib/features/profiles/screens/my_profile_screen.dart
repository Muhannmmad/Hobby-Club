import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hoppy_club/features/profiles/screens/edit_profile_screen.dart';
import 'package:hoppy_club/shared/widgets/bottom.navigation.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  MyProfileScreenState createState() => MyProfileScreenState();
}

class MyProfileScreenState extends State<MyProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        debugPrint('User document does not exist.');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : userData == null
                ? const Center(child: Text('No profile data found.'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          width: screenWidth * 0.9,
                          height: screenHeight * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: userData!['profileImage'] != null &&
                                    userData!['profileImage'].isNotEmpty
                                ? Image.network(
                                    userData!['profileImage'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/profiles/profile.jpg',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/profiles/profile.jpg',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.05),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor:
                                          (userData?['isOnline'] ?? false)
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Expanded(
                                      child: Text(
                                        '${userData?['firstName'] ?? 'Not provided'} ${userData?['lastName'] ?? ''}, ${userData?['age'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                profileDetail(
                                    Icons.person,
                                    userData?['gender'] ??
                                        'Gender not provided',
                                    screenWidth),
                                profileDetail(
                                  Icons.location_on,
                                  '${userData?['city'] ?? 'City not provided'}, ${userData?['state'] ?? 'State not provided'}, ${userData?['country'] ?? 'Country not provided'}',
                                  screenWidth,
                                ),
                                profileDetail(
                                    Icons.star,
                                    userData?['hobbies'] ??
                                        'Hobbies not provided',
                                    screenWidth),
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  'About Me',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Text(
                                  userData?['about'] ?? 'No details provided.',
                                  style:
                                      TextStyle(fontSize: screenWidth * 0.040),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditProfileScreen(
                                                  userId:
                                                      _auth.currentUser!.uid),
                                        ),
                                      ).then((_) {
                                        fetchUserData();
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30.0),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.04,
                                          vertical: screenHeight * 0.01),
                                    ),
                                    child: Text(
                                      'Edit Profile',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 4),
    );
  }

  Widget profileDetail(IconData icon, String text, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: screenWidth * 0.06),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: screenWidth * 0.045, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
