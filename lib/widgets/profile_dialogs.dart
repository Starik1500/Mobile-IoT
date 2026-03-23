import 'package:flutter/material.dart';
import '../data/hive_auth_repository.dart';
import '../domain/auth_interface.dart';

class ProfileDialogs {
  static void showEditAddressDialog(BuildContext context, User user, VoidCallback onSuccess) {
    final TextEditingController addressController = TextEditingController(text: user.address);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(), title: const Text('Редагувати адресу'),
        content: TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Нова адреса', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('СКАСУВАТИ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              if (addressController.text.isNotEmpty) {
                final updatedUser = User(name: user.name, email: user.email, password: user.password, meters: user.meters, address: addressController.text.trim(), avatarPath: user.avatarPath);
                await authRepository.updateUser(updatedUser);
                onSuccess();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('ЗБЕРЕГТИ'),
          ),
        ],
      ),
    );
  }

  static void showEditNameDialog(BuildContext context, User user, VoidCallback onSuccess) {
    final TextEditingController nameController = TextEditingController(text: user.name);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(), title: const Text('Редагувати ім\'я'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Ваше ім\'я', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('СКАСУВАТИ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.isNotEmpty && !RegExp(r'[0-9]').hasMatch(nameController.text)) {
                final updatedUser = User(name: nameController.text.trim(), email: user.email, password: user.password, meters: user.meters, address: user.address, avatarPath: user.avatarPath);
                await authRepository.updateUser(updatedUser);
                onSuccess();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } else {
                messenger.showSnackBar(const SnackBar(content: Text('Ім\'я не може містити цифри!')));
              }
            },
            child: const Text('ЗБЕРЕГТИ'),
          ),
        ],
      ),
    );
  }

  static void showLogoutDialog(BuildContext context, VoidCallback onLogout) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(), title: const Text('Вихід'),
        content: const Text('Ви впевнені, що хочете вийти з акаунту?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('СКАСУВАТИ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () { Navigator.pop(dialogContext); onLogout(); },
            child: const Text('ВИЙТИ'),
          ),
        ],
      ),
    );
  }
}