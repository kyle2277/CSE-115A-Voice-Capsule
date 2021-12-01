import 'package:flutter/material.dart';

/*
 * Miscellaneous UI widgets used on various pages
 */

// Styled header
class Header extends StatelessWidget {
  const Header(this.heading);
  final String heading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      heading,
      style: const TextStyle(fontSize: 24),
    ),
  );
}

// Styled button
class StyledButton extends StatelessWidget {
  const StyledButton({required this.child, required this.onPressed});
  final Widget child;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).primaryColor)),
    onPressed: onPressed,
    child: child,
  );
}