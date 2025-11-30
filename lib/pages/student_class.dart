import 'package:flutter/material.dart';

class StudentClassPage extends StatefulWidget {
  const StudentClassPage({super.key});

  @override
  State<StatefulWidget> createState() => _StudentClassState();
}

class _StudentClassState extends State<StudentClassPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Class Page')),
      body: const Center(child: Text('Welcome to the Student Class Page!')),
    );
  }
}
