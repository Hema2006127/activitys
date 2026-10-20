import 'package:flutter/material.dart';

/// مفتاح الـ Scaffold الرئيسي (اللي فيه الـ Drawer والـ Bottom Bar).
/// كل تاب جواه Scaffold خاص بيه، فـ Scaffold.of(context) بيلاقي الداخلي اللي مالوش Drawer —
/// عشان كده زرار القائمة لازم يفتح الـ Drawer عن طريق المفتاح ده.
final mainScaffoldKey = GlobalKey<ScaffoldState>();

void openMainDrawer() => mainScaffoldKey.currentState?.openDrawer();
