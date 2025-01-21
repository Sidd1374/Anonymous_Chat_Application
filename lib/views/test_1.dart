// import 'home/home_page.dart';
// import 'package:chat_application/main.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../core/app_theme.dart';
// import '../views/entry/register_page.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({Key? key}) : super(key: key);
//
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isPasswordVisible = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final themeChanger = context.watch<ThemeChanger>(); // Access ThemeChanger
//
//     // Determine the appropriate logo based on the theme
//     final String logoPath = context.watch<ThemeChanger>().currentTheme == AppTheme.lightTheme
//         ? 'assets/logo/icon-black-no-bg.png'
//         : 'assets/logo/icon-no-bg-white.png';
//
//     return WillPopScope(
//       onWillPop: () async {
//         // will pop Animation
//         final shouldPop = await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Exit App'),
//             content: const Text('Are you sure you want to exit?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('No'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text('Yes'),
//               ),
//             ],
//           ),
//         );
//         return shouldPop ?? false;
//       },
//       child: Scaffold(
//         // Scaffold
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Image.asset(
//                     logoPath,
//                     height: 25.sp,
//                     width: 30.sp,
//                   ),
//                   const SizedBox(width: 10),
//                 ],
//               ),
//               IconButton(
//                 icon: Icon(
//                   themeChanger.currentTheme == AppTheme.lightTheme
//                       ? Icons.dark_mode
//                       : Icons.light_mode,
//                   color: Theme.of(context).iconTheme.color,
//                 ),
//                 onPressed: () {
//                   if (themeChanger.currentTheme == AppTheme.lightTheme) {
//                     themeChanger.setTheme(AppTheme.darkTheme);
//                   } else {
//                     themeChanger.setTheme(AppTheme.lightTheme);
//                   }
//                 },
//               ),
//             ],
//           ),
//           backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
//         ),
//         body: SingleChildScrollView(
//           // body components
//           child: Center(
//             child: Padding(
//               padding: EdgeInsets.all(16.0.w),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     SizedBox(height: 80.h),
//                     Image.asset(
//                       logoPath,
//                       height: 80.sp,
//                       width: 80.sp,
//                     ),
//                     SizedBox(height: 20.h),
//                     Text(
//                       "Welcome!",
//                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 28.sp,
//                       ),
//                     ),
//                     SizedBox(height: 10.h),
//                     Text(
//                       "Sign in to your account",
//                       style: Theme.of(context).textTheme.bodyMedium,
//                     ),
//                     SizedBox(height: 40.h),
//                     SizedBox(
//                       width: 350.w,
//                       height: 50.h,
//                       child: TextFormField(
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor:
//                           Theme.of(context).inputDecorationTheme.fillColor,
//                           labelText: "Email",
//                           border: Theme.of(context).inputDecorationTheme.border,
//                           prefixIcon: Icon(Icons.email,
//                               color: Theme.of(context).primaryColor),
//                           contentPadding: EdgeInsets.symmetric(
//                               vertical: 10.h, horizontal: 15.w),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your email';
//                           }
//                           if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
//                               .hasMatch(value)) {
//                             return 'Enter a valid email';
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                     SizedBox(height: 10.h),
//                     SizedBox(
//                       width: 350.w,
//                       height: 50.h,
//                       child: TextFormField(
//                         obscureText: !_isPasswordVisible,
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor:
//                           Theme.of(context).inputDecorationTheme.fillColor,
//                           labelText: "Password",
//                           border: Theme.of(context).inputDecorationTheme.border,
//                           prefixIcon: Icon(Icons.lock,
//                               color: Theme.of(context).primaryColor),
//                           suffixIcon: IconButton(
//                             icon: Icon(
//                               _isPasswordVisible
//                                   ? Icons.visibility
//                                   : Icons.visibility_off,
//                               color: Theme.of(context).primaryColor,
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 _isPasswordVisible = !_isPasswordVisible;
//                               });
//                             },
//                           ),
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your password';
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: TextButton(
//                         onPressed: () {
//                           // Handle forget password logic
//                           print('Forgot Password Pressed');
//                         },
//                         child: Text(
//                           "Forgot Password?",
//                           style: TextStyle(
//                               fontSize: 12.sp,
//                               color: Theme.of(context).primaryColor),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 30.h),
//                     ElevatedButton(
//                       onPressed: () {
//                         // if (_formKey.currentState!.validate()) {
//                         //   print('Logged in successfully');
//                         // }
//                         Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
//                       },
//                       style: ElevatedButton.styleFrom(
//                         minimumSize: Size(150.w, 40.h),
//                         backgroundColor: Theme.of(context).primaryColor,
//                       ),
//                       child: Text(
//                         "Continue",
//                         style: TextStyle(fontSize: 16.sp),
//                       ),
//                     ),
//                     SizedBox(height: 20.h),
//                     Row(
//                       children: [
//                         Expanded(child: Divider(thickness: 1)),
//                         Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 10.w),
//                           child: Text(
//                             "or",
//                             style: TextStyle(fontSize: 14.sp),
//                           ),
//                         ),
//                         Expanded(child: Divider(thickness: 1)),
//                       ],
//                     ),
//                     SizedBox(height: 20.h),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 0.0,horizontal: 30.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           OutlinedButton(
//                             onPressed: () {
//                               Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()),
//                               );
//                             },
//
//                             style: OutlinedButton.styleFrom(
//                               shape: const CircleBorder(),
//                               side: BorderSide(color : Theme.of(context).primaryColor, width: 2),
//                               padding: const EdgeInsets.all(16),
//                             ),
//                             child: Image.asset(
//                               logoPath,
//                               height: 30,
//                               width: 30,
//                             ),
//                           ),
//                           // const SizedBox(height: 50),
//                           OutlinedButton(
//                             onPressed: () {
//                               print('Continue with Google');
//                             },
//                             style: OutlinedButton.styleFrom(
//                               shape: const CircleBorder(),
//                               side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
//                               padding: const EdgeInsets.all(16),
//                             ),
//                             child: Image.asset(
//                               "assets/logo/Google_logo.png",
//                               height: 30,
//                               width: 30,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
