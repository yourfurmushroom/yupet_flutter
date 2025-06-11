import 'package:flutter/material.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String actionName;
  final VoidCallback loginHandler;
  final VoidCallback? backHandler;

  const Navbar({
    super.key,
    required this.actionName,
    required this.loginHandler,
    this.backHandler,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);



  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: backHandler != null ? IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: backHandler,
      ):null,
      title: Text(
        actionName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color.fromRGBO(153, 217, 234, 1),
      actions: [
        IconButton(
          onPressed: loginHandler,
          icon: const Icon(Icons.account_circle),
        ),
      ],
    );
  }
}
