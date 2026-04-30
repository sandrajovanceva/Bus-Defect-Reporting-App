import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: 'Report a defect',
                    icon: Icons.add_rounded,
                    onPressed: () => context.push(AppRoutes.defectReport),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'My defects',
                    icon: Icons.list_alt_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.push(AppRoutes.myDefects),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
