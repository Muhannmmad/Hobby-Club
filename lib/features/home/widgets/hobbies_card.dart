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
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hobbies.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              final String groupId = hobbies[index].groupId;

              if (groupId != null && groupId.isNotEmpty) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.asset(
                      hobbies[index].image,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      hobbies[index].name,
                      style: const TextStyle(fontSize: 16),
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
