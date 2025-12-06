import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/random_caller_model.dart';
import '../providers/random_caller_provider.dart';
import '../utils/random_caller_dao.dart';
import '../widgets/random_caller_add_edit_dialog.dart';
import '../widgets/random_caller_info_widget.dart';

class RandomCallPage extends StatefulWidget {
  const RandomCallPage({super.key});

  @override
  State<RandomCallPage> createState() => _RandomCallPageState();
}

class _RandomCallPageState extends State<RandomCallPage> {


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RandomCallerInfoWidget(),
      ],
    );
    // return RandomCallerInfoWidget();
  }







  
}
