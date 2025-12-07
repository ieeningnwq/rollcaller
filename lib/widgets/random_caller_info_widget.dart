// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../models/random_caller_model.dart';
// import '../providers/random_caller_provider.dart';
// import '../utils/random_caller_dao.dart';
// import 'random_caller_add_edit_dialog.dart';
// import 'random_caller_view_dialog.dart';

// class RandomCallerInfoWidget extends StatefulWidget {
//   const RandomCallerInfoWidget({super.key});

//   @override
//   State<RandomCallerInfoWidget> createState() => _RandomCallerInfoWidgetState();
// }

// class _RandomCallerInfoWidgetState extends State<RandomCallerInfoWidget> {
//   // 当前选中的点名器
//   int? _selectedCallerId;
//   // 点名器名称控制器
//   final TextEditingController _randomCallerNameController =
//       TextEditingController();
//   // 点名器备注控制器
//   final TextEditingController _notesController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return _buildRandomCallerInfoWidget();
//   }

//   Container _buildRandomCallerInfoWidget() {
//     return Container(
//       margin: const EdgeInsets.all(10.0),
//       padding: const EdgeInsets.all(14.0),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12.0),
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withAlpha(10),
//             blurRadius: 10.0,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // 顶部标题和管理链接
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 '选择点名器',
//                 style: TextStyle(
//                   fontSize: 18.0,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//               Spacer(),
//               _buildViewIconButton(),
//               _buildAddIconButton(),
//               _buildEditIconButton(),
//               _buildDeleteIconButton(),
//             ],
//           ),
//           const SizedBox(height: 8),
//           _buildDropdownButton(),
//         ],
//       ),
//     );
//   }

//   IconButton _buildDeleteIconButton() {
//     return IconButton(
//       onPressed: () {
//         // 删除点名器功能
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text('确认删除'),
//               content: const Text('确定要删除选中的点名器吗？'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('取消'),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     await RandomCallerDao().deleteRandomCaller(
//                       _selectedCallerId!,
//                     );
//                     if (context.mounted) {
//                       Provider.of<RandomCallerProvider>(
//                         context,
//                         listen: false,
//                       ).removeRandomCaller(_selectedCallerId!);
//                       setState(() {
//                         _selectedCallerId = null;
//                       });
//                       Navigator.of(context).pop();
//                     }
//                   },
//                   child: const Text('删除'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//       icon: const Icon(Icons.delete, color: Colors.red),
//     );
//   }

//   FutureBuilder<List<RandomCallerModel>> _buildDropdownButton() {
//     return FutureBuilder(
//       future: RandomCallerDao().getAllRandomCallers(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('No random callers found.'));
//         } else {
//           final randomCallers = snapshot.data!;
//           for (var randomCaller in randomCallers) {
//             Provider.of<RandomCallerProvider>(
//               context,
//               listen: false,
//             ).updateRandomCallerWithoutNotify(randomCaller);
//           }
//           if (_selectedCallerId == null) {
//             _selectedCallerId = randomCallers.first.id;
//             Provider.of<RandomCallerProvider>(
//               context,
//               listen: false,
//             ).setCurrentSelectedCallerWithoutNotify(_selectedCallerId!);
//           }

//           return DropdownButtonFormField<int>(
//             initialValue: _selectedCallerId,
//             decoration: InputDecoration(
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8.0),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8.0),
//                 borderSide: BorderSide(color: Colors.grey.shade300),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8.0),
//                 borderSide: const BorderSide(color: Colors.blue),
//               ),
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 12.0,
//                 vertical: 10.0,
//               ),
//             ),
//             items: randomCallers.map((RandomCallerModel randomCaller) {
//               return DropdownMenuItem<int>(
//                 value: randomCaller.id,
//                 child: Text(randomCaller.randomCallerName),
//               );
//             }).toList(),
//             onChanged: (newValue) {
//               if (newValue != null) {
//                 setState(() {
//                   _selectedCallerId = newValue;
//                 });
//                 Provider.of<RandomCallerProvider>(
//                   context,
//                   listen: false,
//                 ).setCurrentSelectedCaller(newValue);
//               }
//             },
//             style: const TextStyle(fontSize: 16.0, color: Colors.black),
//             dropdownColor: Colors.white,
//             icon: const Icon(Icons.arrow_drop_down),
//             iconSize: 24.0,
//             iconEnabledColor: Colors.grey,
//           );
//         }
//       },
//     );
//   }

//   IconButton _buildEditIconButton() {
//     return IconButton(
//       onPressed: () {
//         // 编辑点名器功能
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return RandomCallerAddEditDialog(
//               title: '修改点名器',
//               randomCaller: Provider.of<RandomCallerProvider>(
//                 context,
//                 listen: false,
//               ).randomCallers[_selectedCallerId!]!,
//               randomCallerNameController: _randomCallerNameController,
//               notesController: _notesController,
//             );
//           },
//         );
//       },
//       icon: const Icon(Icons.edit, color: Colors.blue),
//     );
//   }

//   IconButton _buildAddIconButton() {
//     return IconButton(
//       onPressed: () => {
//         // 新增点名器功能
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return RandomCallerAddEditDialog(
//               title: '添加点名器',
//               randomCaller: RandomCallerModel(
//                 id: -1,
//                 classId: -1,
//                 randomCallerName: '',
//                 isDuplicate: 0,
//                 isArchive: 0,
//                 notes: '',
//                 created: DateTime.now(),
//               ),
//               randomCallerNameController: _randomCallerNameController,
//               notesController: _notesController,
//             );
//           },
//         ),
//       },
//       icon: Icon(Icons.add, color: Colors.green),
//     );
//   }

//   @override
//   void dispose() {
//     _randomCallerNameController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   IconButton _buildViewIconButton() {
//     return IconButton(
//       onPressed: () {
//         // 查看点名器功能
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return RandomCallerViewDialog(
//               randomCaller: Provider.of<RandomCallerProvider>(
//                 context,
//                 listen: false,
//               ).randomCallers[_selectedCallerId!]!,
//             );
//           },
//         );
//       },
//       icon: const Icon(Icons.remove_red_eye, color: Colors.grey),
//     );
//   }
// }
