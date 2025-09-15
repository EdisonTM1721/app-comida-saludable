// Archivo: presentation/pages/social_media_page.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:emprendedor/presentation/controllers/social_media_controller.dart';
import 'package:emprendedor/data/models/social_media_model.dart';

class SocialMediaPage extends StatelessWidget {
  const SocialMediaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Aquí usamos Consumer para escuchar los cambios en el controlador
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redes Sociales'),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Consumer<SocialMediaController>(
        builder: (context, controller, child) {
          // Lógica de la UI para estados de carga, error y lista vacía.
          if (controller.isLoading && controller.socialMediaList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null) {
            return Center(child: Text(controller.errorMessage!));
          }
          if (controller.socialMediaList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes redes sociales añadidas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pulsa el botón "+" para añadir tu primera red social.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Si hay datos, muestra la lista.
          return ListView.builder(
            itemCount: controller.socialMediaList.length,
            itemBuilder: (context, index) {
              final socialMedia = controller.socialMediaList[index];
              IconData icon;
              switch (socialMedia.name) {
                case 'Facebook':
                  icon = FontAwesomeIcons.facebook;
                  break;
                case 'Instagram':
                  icon = FontAwesomeIcons.instagram;
                  break;
                case 'TikTok':
                  icon = FontAwesomeIcons.tiktok;
                  break;
                default:
                  icon = Icons.public;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(icon, color: Colors.teal),
                  title: Text(socialMedia.name),
                  subtitle: Text(socialMedia.url.isNotEmpty ? socialMedia.url : 'Añadir URL'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editSocialMedia(context, controller, socialMedia);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          controller.deleteSocialMedia(socialMedia.id!);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddOptions(BuildContext context) {
    final controller = context.read<SocialMediaController>();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(FontAwesomeIcons.facebook, color: Colors.blue),
                title: const Text('Facebook'),
                onTap: () {
                  controller.addSocialMedia(SocialMediaModel(name: 'Facebook', url: ''));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.instagram, color: Colors.purple),
                title: const Text('Instagram'),
                onTap: () {
                  controller.addSocialMedia(SocialMediaModel(name: 'Instagram', url: ''));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.tiktok, color: Colors.black),
                title: const Text('TikTok'),
                onTap: () {
                  controller.addSocialMedia(SocialMediaModel(name: 'TikTok', url: ''));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editSocialMedia(BuildContext context, SocialMediaController controller, SocialMediaModel socialMedia) {
    final TextEditingController urlController = TextEditingController(text: socialMedia.url);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Editar URL de ${socialMedia.name}'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://ejemplo.com',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                final updatedSocialMedia = socialMedia.copyWith(url: urlController.text);
                controller.updateSocialMedia(updatedSocialMedia);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}