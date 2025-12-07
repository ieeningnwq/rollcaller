import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/random_caller_provider.dart';
import '../widgets/random_caller_call_widget.dart';
import '../widgets/random_caller_info_widget.dart';
import '../widgets/student_score_widget.dart';

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
        return Expanded(
          child: SingleChildScrollView(
            child:Column(
                children: [
                  RandomCallerInfoWidget(),
                  RandomCallerCallWidget(),
                  StudentScoreWidget(),
                ],
            ),
          ),
        );
      },
    );
    // return RandomCallerInfoWidget();
  }
}
