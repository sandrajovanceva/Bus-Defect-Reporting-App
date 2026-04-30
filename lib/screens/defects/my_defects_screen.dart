import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_routes.dart';

class MyDefectsScreen extends StatelessWidget {
  const MyDefectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final placeholderIds = ['1', '2', '3'];

    return Scaffold(
      appBar: AppBar(title: const Text('My defects')),
      body: ListView.separated(
        itemCount: placeholderIds.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final id = placeholderIds[index];
          return ListTile(
            title: Text('Defect #$id'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.defectDetails(id)),
          );
        },
      ),
    );
  }
}
