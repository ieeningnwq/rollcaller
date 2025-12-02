import 'package:flutter/material.dart';

import '../configs/strings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(KString.homeAppBarTitle)),
      body: const Center(child: Text('Welcome to the Home Page!')),
    );
  }
}
