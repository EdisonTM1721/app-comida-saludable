import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SocialMediaPage');

// Global variables to be used in the app, these are provided by the canvas environment.
// ignore: non_constant_identifier_names
const String __app_id = String.fromEnvironment("APP_ID", defaultValue: "default-app-id");
// ignore: non_constant_identifier_names
const String __initial_auth_token = String.fromEnvironment("INITIAL_AUTH_TOKEN", defaultValue: "");

class SocialMediaPage extends StatefulWidget {
  const SocialMediaPage({super.key});

  @override
  State<SocialMediaPage> createState() => _SocialMediaPageState();
}

class _SocialMediaPageState extends State<SocialMediaPage> {
  final List<Map<String, dynamic>> _socialMedia = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeAppAndLoadData();
  }

  Future<void> _initializeAppAndLoadData() async {
    try {
      if (__initial_auth_token.isNotEmpty) {
        await _auth.signInWithCustomToken(__initial_auth_token);
        _userId = _auth.currentUser!.uid;
        _logger.info('User authenticated successfully. User ID: $_userId');
        _listenToSocialMediaChanges();
      } else {
        _logger.severe('Initial auth token is empty. Cannot authenticate.');
      }
    } on Exception catch (e) {
      _logger.severe('Firebase authentication error: $e');
    }
  }

  void _listenToSocialMediaChanges() {
    if (_userId == null) {
      _logger.warning('User ID is null. Cannot listen to social media changes.');
      return;
    }
    final docRef = _firestore.collection('artifacts').doc(__app_id).collection('users').doc(_userId);
    docRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data.containsKey('socialMedia')) {
          try {
            final socialMediaList = List<Map<String, dynamic>>.from(data['socialMedia']);
            setState(() {
              _socialMedia.clear();
              _socialMedia.addAll(socialMediaList);
            });
            _logger.info('Social media data loaded successfully from Firestore.');
          } catch (e) {
            _logger.severe('Error decoding social media data: $e');
          }
        }
      } else {
        setState(() {
          _socialMedia.clear();
        });
        _logger.info('No social media data found for this user.');
      }
    });
  }

  Future<void> _saveSocialMedia() async {
    if (_userId == null) {
      _logger.warning('User ID is null. Cannot save social media.');
      return;
    }
    try {
      final docRef = _firestore.collection('artifacts').doc(__app_id).collection('users').doc(_userId);
      await docRef.set({'socialMedia': _socialMedia}, SetOptions(merge: true));
      _logger.info('Social media data saved successfully to Firestore.');
    } on Exception catch (e) {
      _logger.severe('Error saving social media data: $e');
    }
  }

  void _addSocialMedia(String platform) {
    setState(() {
      _socialMedia.add({'name': platform, 'url': ''});
    });
    _saveSocialMedia();
  }

  void _showAddOptions(BuildContext context) {
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
                  _addSocialMedia('Facebook');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.instagram, color: Colors.purple),
                title: const Text('Instagram'),
                onTap: () {
                  _addSocialMedia('Instagram');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.tiktok, color: Colors.black),
                title: const Text('TikTok'),
                onTap: () {
                  _addSocialMedia('TikTok');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editSocialMedia(int index, String currentUrl) {
    final TextEditingController urlController = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar URL de ${_socialMedia[index]['name']}'),
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                setState(() {
                  _socialMedia[index]['url'] = urlController.text;
                });
                _saveSocialMedia();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteSocialMedia(int index) {
    setState(() {
      _socialMedia.removeAt(index);
    });
    _saveSocialMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redes Sociales'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddOptions(context),
                icon: const Icon(Icons.add),
                label: const Text('Añadir Red Social'),
              ),
              const SizedBox(height: 16),
              if (_socialMedia.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _socialMedia.length,
                  itemBuilder: (context, index) {
                    final item = _socialMedia[index];
                    IconData icon;
                    switch (item['name']) {
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
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(icon, color: Colors.teal),
                        title: Text(item['name']),
                        subtitle: Text(item['url'] ?? 'Añadir URL'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editSocialMedia(index, item['url'] ?? '');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteSocialMedia(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                const Center(
                  child: Text(
                    'Aquí se gestionarán las redes sociales',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
