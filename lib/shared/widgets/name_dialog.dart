import 'package:flutter/material.dart';

Future<String?> promptName(BuildContext context,
        {required String title, String? initial, String hint = 'Название', bool url = false}) =>
    showDialog<String>(
        context: context, builder: (_) => _NameDialog(title: title, initial: initial, hint: hint, url: url));

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, this.initial, required this.hint, required this.url});
  final String title, hint;
  final String? initial;
  final bool url;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.isNotEmpty) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _c,
          autofocus: true,
          textCapitalization: widget.url ? TextCapitalization.none : TextCapitalization.sentences,
          keyboardType: widget.url ? TextInputType.url : TextInputType.text,
          decoration: InputDecoration(hintText: widget.hint),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(onPressed: _submit, child: const Text('Сохранить')),
        ],
      );
}
