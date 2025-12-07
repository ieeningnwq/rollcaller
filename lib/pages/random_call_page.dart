import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/random_caller_provider.dart';
import '../widgets/random_caller_call_widget.dart';
import '../widgets/random_caller_info_widget.dart';

class RandomCallPage extends StatefulWidget {
  const RandomCallPage({super.key});

  @override
  State<RandomCallPage> createState() => _RandomCallPageState();
}

class _RandomCallPageState extends State<RandomCallPage> {

  @override
  Widget build(BuildContext context) {
    return Consumer<RandomCallerProvider>(
      builder: (context, randomCallerProvider, child) {
        return Column(
          children: [
            RandomCallerInfoWidget(),
            RandomCallerCallWidget(),
          ],
        );
      },
    );
    // return RandomCallerInfoWidget();
  }
}
