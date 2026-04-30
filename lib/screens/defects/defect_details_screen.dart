import 'package:flutter/material.dart';

class DefectDetailsScreen extends StatelessWidget {
  const DefectDetailsScreen({super.key, required this.defectId});

  final String defectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Defect #$defectId')),
      body: Center(child: Text('Details for defect $defectId')),
    );
  }
}
