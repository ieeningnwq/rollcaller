import 'package:flutter/material.dart';

class AttendencePage extends StatefulWidget {
  const AttendencePage({super.key});

  @override
  State<StatefulWidget> createState() => _AttendencePageState();
}

class _AttendencePageState extends State<AttendencePage> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Attendence Page'));
  }
}
