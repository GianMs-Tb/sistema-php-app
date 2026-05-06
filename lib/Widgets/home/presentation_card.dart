import 'package:flutter/material.dart';

/// Tarjeta de presentación que aparece después del login.
class PresentationCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String photoUrl;
  final VoidCallback onOpenFeed;

  const PresentationCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.onOpenFeed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      displayName.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 34),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            Text(
              displayName,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Divider(height: 32),
            const PresentationInfoRow(
              icon: Icons.school_outlined,
              label: 'Programa',
              value: 'Ingeniería Informática',
            ),
            const PresentationInfoRow(
              icon: Icons.phone_android_outlined,
              label: 'Asignatura',
              value: 'Aplicaciones Móviles',
            ),
            const PresentationInfoRow(
              icon: Icons.dynamic_feed_outlined,
              label: 'Proyecto',
              value: 'CRUD de feeds tipo Instagram',
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ir a la lista de feeds'),
                onPressed: onOpenFeed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila reutilizable de información dentro de la tarjeta.
class PresentationInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const PresentationInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
