import 'package:flutter/material.dart';

class DefectReportScreen extends StatelessWidget {
  const DefectReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report defect')),
      body: const Center(child: Text('Defect report form goes here')),
    );
  }
}
