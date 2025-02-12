import 'package:flutter/material.dart';
import 'package:hoppy_club/features/home/repository/hobby.dart';
import 'package:hoppy_club/features/home/screens/groups_page.dart';

class HobbiesCard extends StatelessWidget {
  const HobbiesCard({
    super.key,
    required this.hobbies,
  });

  final List<Hobby> hobbies;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double textSize = screenWidth * 0.045;

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hobbies.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              final String groupId = hobbies[index].groupId;

              if (groupId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupPage(groupId: groupId),
                  ),
                );
              } else {
                debugPrint("Group ID is null or empty for this hobby.");
              }
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      hobbies[index].image,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    width: 220,
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10)),
                    ),
                    child: Text(
                      hobbies[index].name,
                      style: TextStyle(
                        fontSize: textSize,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
