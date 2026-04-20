import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emprendedor/data/models/entrepreneur/business_profile_model.dart';
import 'package:emprendedor/data/repositories/entrepreneur/business_profile_repository.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final BusinessProfileRepository _repository = BusinessProfileRepository();

  bool _isLoading = true;
  String? _errorMessage;
  BusinessProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _errorMessage = 'Usuario no autenticado.';
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final profile = await _repository.getBusinessProfile(user.uid);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profile = null;
        _errorMessage = 'Error al cargar el perfil.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _profile == null) {
      return RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          children: [
            const SizedBox(height: 250),
            Center(child: Text(_errorMessage!)),
          ],
        ),
      );
    }

    if (_profile == null) {
      return RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          children: const [
            SizedBox(height: 250),
            Center(
              child: Text("No hay datos de perfil disponibles."),
            ),
          ],
        ),
      );
    }

    final profile = _profile!;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (profile.profileImageUrl != null &&
                  profile.profileImageUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(profile.profileImageUrl!),
                )
              else
                const CircleAvatar(
                  radius: 60,
                  child: Icon(Icons.business, size: 60),
                ),
              const SizedBox(height: 16),
              Text(
                profile.name.isNotEmpty ? profile.name : 'Mi Negocio',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildProfileInfoCard(
                icon: Icons.info_outline,
                title: "Descripción",
                content: profile.description,
              ),
              _buildProfileInfoCard(
                icon: Icons.location_on_outlined,
                title: "Dirección",
                content: profile.address,
              ),
              _buildProfileInfoCard(
                icon: Icons.schedule,
                title: "Horarios de Atención",
                content: profile.openingHours,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard({
    required IconData icon,
    required String title,
    required String? content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content != null && content.isNotEmpty
                        ? content
                        : "No especificado",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}