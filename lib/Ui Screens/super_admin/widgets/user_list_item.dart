import 'package:flutter/material.dart';
import '../models/data_models.dart';

class UserListItem extends StatelessWidget {
  final GenUiEmployee user;
  final void Function(GenUiEmployee) onDelete;
  final void Function(GenUiEmployee) onEdit;

  const UserListItem({
    super.key,
    required this.user,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(user.name[0]),
        ),
        title: Text(user.name),
        subtitle: Text(user.role),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => onEdit(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(user),
            ),
          ],
        ),
      ),
    );
  }
}
