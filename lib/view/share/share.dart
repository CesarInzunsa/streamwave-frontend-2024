import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:flutter/material.dart';

class Share {
  static const List<String> titles = ['Home', 'View'];

  static const List<Icon> selectedIcon = [
    Icon(Icons.home),
    Icon(Icons.view_list)
  ];

  static const List<Icon> unselectedIcon = [
    Icon(Icons.home_outlined),
    Icon(Icons.view_list_outlined)
  ];

  static List<SideMenuItem> getDesktopDestinations(sideMenu) {
    return [
      SideMenuItem(
        title: 'Home',
        onTap: (index, _) {
          sideMenu.changePage(index);
        },
        icon: const Icon(Icons.home),
      ),
      SideMenuItem(
        title: 'View',
        onTap: (index, _) {
          sideMenu.changePage(index);
        },
        icon: const Icon(Icons.view_list),
      ),
    ];
  }
}
