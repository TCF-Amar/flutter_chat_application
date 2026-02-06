// import 'package:flutter/material.dart';
// import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

// /// Stylish bottom navigation bar for the app
// class AppBottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//   final List<BottomBarItem> items;
//   final Color? backgroundColor;
//   final bool hasNotch;
//   final double elevation;
//   final double iconSize;

//   const AppBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     required this.items,
//     this.backgroundColor,
//     this.hasNotch = true,
//     this.elevation = 8,
//     this.iconSize = 24,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return StylishBottomBar(
//       option: AnimatedBarOptions(
//         iconSize: iconSize,
//         barAnimation: BarAnimation.fade,
//         iconStyle: IconStyle.animated,
//         opacity: 0.3,
//       ),
//       items: items,
//       hasNotch: hasNotch,
//       fabLocation: StylishBarFabLocation.center,
//       currentIndex: currentIndex,
//       onTap: onTap,
//       backgroundColor: backgroundColor ?? Colors.white,
//       elevation: elevation,
//     );
//   }

//   /// Create default bottom bar items for chat app
//   static List<BottomBarItem> defaultItems({
//     Color? selectedColor,
//     Color? unselectedColor,
//   }) {
//     final selected = selectedColor ?? Colors.deepPurple;
//     final unselected = unselectedColor ?? Colors.grey;

//     return [
//       BottomBarItem(
//         icon: const Icon(Icons.chat_bubble_outline),
//         selectedIcon: const Icon(Icons.chat_bubble),
//         selectedColor: selected,
//         unSelectedColor: unselected,
//         title: const Text('Chats'),
//       ),
//       BottomBarItem(
//         icon: const Icon(Icons.notifications_rounded),
//         selectedIcon: const Icon(Icons.notifications_sharp),
//         selectedColor: selected,
//         unSelectedColor: unselected,
//         title: const Text('Notification'),
//       ),
//       BottomBarItem(
//         icon: const Icon(Icons.people_outline),
//         selectedIcon: const Icon(Icons.people),
//         selectedColor: selected,
//         unSelectedColor: unselected,
//         title: const Text('Contacts'),
//       ),
//       BottomBarItem(
//         icon: const Icon(Icons.call_outlined),
//         selectedIcon: const Icon(Icons.call),
//         selectedColor: selected,
//         unSelectedColor: unselected,
//         title: const Text('Calls'),
//       ),
//       BottomBarItem(
//         icon: const Icon(Icons.person_outline),
//         selectedIcon: const Icon(Icons.person),
//         selectedColor: selected,
//         unSelectedColor: unselected,
//         title: const Text('Profile'),
//       ),
//     ];
//   }
// }
