import 'package:flutter/material.dart';

class BaseWidget extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const BaseWidget({
    super.key,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
