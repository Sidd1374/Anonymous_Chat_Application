import 'package:flutter/material.dart';
import 'package:veil_chat_application/models/user_model.dart' as mymodel;

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _chatWithOppositeGender = false;
  bool _showProfilePhotoToStrangers = false;
  bool _showProfilePhotoToFriends = false;
  bool _chatOnlyWithVerifiedUsers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat Preferences',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Chat only with opposite gender'),
                value: _chatWithOppositeGender,
                activeColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _chatWithOppositeGender = value;
                  });
                },
              ),
              // the age range selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Row(
                  children: [
                    const Text(
                      'Chat only with people of age ',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Min',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (value) {
                          // handle min age change
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('to'),
                    ),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Max',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (value) {
                          // handle max age change
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // the switch for showing profile photo to strangers and friends
              SwitchListTile(
                title: const Text('Show Profile photo to strangers'),
                value: _showProfilePhotoToStrangers,
                activeColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _showProfilePhotoToStrangers = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Show Profile photo to friends'),
                value: _showProfilePhotoToFriends,
                activeColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _showProfilePhotoToFriends = value;
                  });
                },
              ),
              // the switch for chatting only with verified users
              SwitchListTile(
                title: const Text('Chat only with Lvl 2 verified users'),
                value: _chatOnlyWithVerifiedUsers,
                activeColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Theme.of(context).colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _chatOnlyWithVerifiedUsers = value;
                  });
                },
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}

// class _SettingsPageState extends State<SettingsPage> {
//   mymodel.User? user;

//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//   }

//   Future<void> _loadUser() async {
//     final loadedUser = await mymodel.User.getFromPrefs();
//     setState(() {
//       user = loadedUser;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return user == null
//         ? const Center(child: CircularProgressIndicator())
//         : SingleChildScrollView(
//             child: Column(
//               children: [
//                 Container(
//                   width: 428,
//                   height: 926,
//                   clipBehavior: Clip.antiAlias,
//                   decoration: ShapeDecoration(
//                     color: const Color(0xFFF1E5DD),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     shadows: [
//                       BoxShadow(
//                         color: const Color(0x19000000),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                         spreadRadius: 5,
//                       )
//                     ],
//                   ),
//                   child: Stack(
//                     children: [
//                       Positioned(
//                         left: 62,
//                         top: 30,
//                         child: Text(
//                           'Settings',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 24,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 29,
//                         child: Container(width: 32, height: 32, child: Stack()),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 249,
//                         child: Text(
//                           'Chat Preferences',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 18,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 300,
//                         child: Text(
//                           'Chat only with opposite gender',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 16,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 350,
//                         top: 291,
//                         child: Container(
//                           width: 60,
//                           height: 36,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 left: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 60,
//                                   height: 36,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFFFF2EA),
//                                     shape: RoundedRectangleBorder(
//                                       side: BorderSide(
//                                         width: 1,
//                                         color: const Color(0xFFF1E5DD),
//                                       ),
//                                       borderRadius: BorderRadius.circular(200),
//                                     ),
//                                     shadows: [
//                                       BoxShadow(
//                                         color: Color(0x19000000),
//                                         blurRadius: 10,
//                                         offset: Offset(0, 4),
//                                         spreadRadius: 0,
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 28.50,
//                                 top: 4.50,
//                                 child: Container(
//                                   width: 27,
//                                   height: 27,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFFF964B),
//                                     shape: OvalBorder(),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 346,
//                         child: Text(
//                           'Chat only with people of age ',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 16,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 320,
//                         top: 346,
//                         child: Text(
//                           'to',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 16,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 246,
//                         top: 337,
//                         child: Container(
//                           width: 60,
//                           height: 36,
//                           decoration: ShapeDecoration(
//                             color: const Color(0xFFFFF2EA),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(200),
//                             ),
//                             shadows: [
//                               BoxShadow(
//                                 color: Color(0x19000000),
//                                 blurRadius: 10,
//                                 offset: Offset(0, 4),
//                                 spreadRadius: 0,
//                               )
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 258,
//                         top: 341,
//                         child: SizedBox(
//                           width: 36,
//                           height: 29,
//                           child: Text(
//                             '18',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: const Color(0xFFFF964B),
//                               fontSize: 16,
//                               fontFamily: 'Inter',
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 350,
//                         top: 337,
//                         child: Container(
//                           width: 60,
//                           height: 36,
//                           decoration: ShapeDecoration(
//                             color: const Color(0xFFFFF2EA),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(200),
//                             ),
//                             shadows: [
//                               BoxShadow(
//                                 color: Color(0x19000000),
//                                 blurRadius: 10,
//                                 offset: Offset(0, 4),
//                                 spreadRadius: 0,
//                               )
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 362,
//                         top: 341,
//                         child: SizedBox(
//                           width: 36,
//                           height: 29,
//                           child: Text(
//                             '30',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: const Color(0xFFFF964B),
//                               fontSize: 16,
//                               fontFamily: 'Inter',
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 392,
//                         child: Text(
//                           'Show your Profile photo to strangers',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 16,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 350,
//                         top: 383,
//                         child: Container(
//                           width: 60,
//                           height: 36,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 left: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 60,
//                                   height: 36,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFFFF2EA),
//                                     shape: RoundedRectangleBorder(
//                                       side: BorderSide(
//                                         width: 1,
//                                         color: const Color(0xFFF1E5DD),
//                                       ),
//                                       borderRadius: BorderRadius.circular(200),
//                                     ),
//                                     shadows: [
//                                       BoxShadow(
//                                         color: Color(0x19000000),
//                                         blurRadius: 10,
//                                         offset: Offset(0, 4),
//                                         spreadRadius: 0,
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 4.50,
//                                 top: 4.50,
//                                 child: Container(
//                                   width: 27,
//                                   height: 27,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFF1E5DD),
//                                     shape: OvalBorder(),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 438,
//                         child: Text(
//                           'Show your Profile photo to friends',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 16,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 350,
//                         top: 429,
//                         child: Container(
//                           width: 60,
//                           height: 36,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 left: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 60,
//                                   height: 36,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFFFF2EA),
//                                     shape: RoundedRectangleBorder(
//                                       side: BorderSide(
//                                         width: 1,
//                                         color: const Color(0xFFF1E5DD),
//                                       ),
//                                       borderRadius: BorderRadius.circular(200),
//                                     ),
//                                     shadows: [
//                                       BoxShadow(
//                                         color: Color(0x19000000),
//                                         blurRadius: 10,
//                                         offset: Offset(0, 4),
//                                         spreadRadius: 0,
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 28.50,
//                                 top: 4.50,
//                                 child: Container(
//                                   width: 27,
//                                   height: 27,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFFF964B),
//                                     shape: OvalBorder(),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 484,
//                         child: Text(
//                           'Chat only with Lvl 2 verified users',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 16,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 350,
//                         top: 475,
//                         child: Container(
//                           width: 60,
//                           height: 36,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 left: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 60,
//                                   height: 36,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFFFF2EA),
//                                     shape: RoundedRectangleBorder(
//                                       side: BorderSide(
//                                         width: 1,
//                                         color: const Color(0xFFF1E5DD),
//                                       ),
//                                       borderRadius: BorderRadius.circular(200),
//                                     ),
//                                     shadows: [
//                                       BoxShadow(
//                                         color: Color(0x19000000),
//                                         blurRadius: 10,
//                                         offset: Offset(0, 4),
//                                         spreadRadius: 0,
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 4.50,
//                                 top: 4.50,
//                                 child: Container(
//                                   width: 27,
//                                   height: 27,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFF1E5DD),
//                                     shape: OvalBorder(),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 541,
//                         child: Text(
//                           'App Settings',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 18,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 592,
//                         child: Text(
//                           'Dark Theme',
//                           style: TextStyle(
//                             color: const Color(0xFF282725),
//                             fontSize: 16,
//                             fontFamily: 'Inter',
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 350,
//                         top: 583,
//                         child: Container(
//                           width: 60,
//                           height: 36,
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 left: 0,
//                                 top: 0,
//                                 child: Container(
//                                   width: 60,
//                                   height: 36,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFFFF2EA),
//                                     shape: RoundedRectangleBorder(
//                                       side: BorderSide(
//                                         width: 1,
//                                         color: const Color(0xFFF1E5DD),
//                                       ),
//                                       borderRadius: BorderRadius.circular(200),
//                                     ),
//                                     shadows: [
//                                       BoxShadow(
//                                         color: Color(0x19000000),
//                                         blurRadius: 10,
//                                         offset: Offset(0, 4),
//                                         spreadRadius: 0,
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 4.50,
//                                 top: 4.50,
//                                 child: Container(
//                                   width: 27,
//                                   height: 27,
//                                   decoration: ShapeDecoration(
//                                     color: const Color(0xFFF1E5DD),
//                                     shape: OvalBorder(),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 629,
//                         child: SizedBox(
//                           width: 392,
//                           height: 36,
//                           child: Text(
//                             'Terms and Conditions',
//                             style: TextStyle(
//                               color: const Color(0xFF282725),
//                               fontSize: 16,
//                               fontFamily: 'Inter',
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 675,
//                         child: SizedBox(
//                           width: 392,
//                           height: 36,
//                           child: Text(
//                             'Privacy Policy',
//                             style: TextStyle(
//                               color: const Color(0xFF282725),
//                               fontSize: 16,
//                               fontFamily: 'Inter',
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 721,
//                         child: SizedBox(
//                           width: 392,
//                           height: 36,
//                           child: Text(
//                             'About',
//                             style: TextStyle(
//                               color: const Color(0xFF282725),
//                               fontSize: 16,
//                               fontFamily: 'Inter',
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         left: 18,
//                         top: 89,
//                         child: Container(
//                           width: 392,
//                           height: 130,
//                           clipBehavior: Clip.antiAlias,
//                           decoration: ShapeDecoration(
//                             color: const Color(0xFFFFF2EA),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             shadows: [
//                               BoxShadow(
//                                 color: Color(0x19000000),
//                                 blurRadius: 10,
//                                 offset: Offset(0, 4),
//                                 spreadRadius: 0,
//                               )
//                             ],
//                           ),
//                           child: Stack(
//                             children: [
//                               Positioned(
//                                 left: 249,
//                                 top: 15,
//                                 child: Text(
//                                   user?.fullName.isNotEmpty == true
//                                       ? user!.fullName
//                                       : 'No Name',
//                                   textAlign: TextAlign.right,
//                                   style: const TextStyle(
//                                     color: Color(0xFF282725),
//                                     fontSize: 28,
//                                     fontFamily: 'Inter',
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 354,
//                                 top: 54,
//                                 child: Text(
//                                   '', // Add age if available
//                                   textAlign: TextAlign.right,
//                                   style: const TextStyle(
//                                     color: Color(0xFF282725),
//                                     fontSize: 18,
//                                     fontFamily: 'Inter',
//                                     fontWeight: FontWeight.w300,
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 302,
//                                 top: 54,
//                                 child: Text(
//                                   '', // Add gender if available
//                                   textAlign: TextAlign.right,
//                                   style: const TextStyle(
//                                     color: Color(0xFF282725),
//                                     fontSize: 18,
//                                     fontFamily: 'Inter',
//                                     fontWeight: FontWeight.w300,
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 190,
//                                 top: 98,
//                                 child: Text(
//                                   'Click here to see your profile',
//                                   textAlign: TextAlign.right,
//                                   style: TextStyle(
//                                     color: const Color(0xFF282725),
//                                     fontSize: 14,
//                                     fontFamily: 'Inter',
//                                     fontWeight: FontWeight.w300,
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 214,
//                                 top: 22,
//                                 child: Container(
//                                     width: 20, height: 20, child: Stack()),
//                               ),
//                               Positioned(
//                                 left: 15,
//                                 top: 15,
//                                 child: Container(
//                                   width: 100,
//                                   height: 100,
//                                   decoration: ShapeDecoration(
//                                     image: DecorationImage(
//                                       image: user?.profilePic != null &&
//                                               user!.profilePic.isNotEmpty
//                                           ? NetworkImage(user!.profilePic)
//                                           : const NetworkImage(
//                                               "https://placehold.co/100x100"),
//                                       fit: BoxFit.cover,
//                                     ),
//                                     shape: const OvalBorder(
//                                       side: BorderSide(
//                                         width: 2,
//                                         color: Color(0xFFFF964B),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//   }
// }
