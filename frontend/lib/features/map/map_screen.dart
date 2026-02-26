import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/location_provider.dart';
import '../../providers/search_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _locationDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);
    final searchState   = ref.watch(searchProvider);
    final result        = searchState.result;

    return locationAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Proximity Map')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildMap(context, null, result),
      data: (position) {
        if (position == null && !_locationDialogShown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _locationDialogShown = true);
            showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Location needed'),
                content: const Text(
                  'Enable location permission in Settings to see your position on the map.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          });
        }
        return _buildMap(
          context,
          position != null ? LatLng(position.latitude, position.longitude) : null,
          result,
        );
      },
    );
  }

  Widget _buildMap(BuildContext context, LatLng? position, dynamic result) {
    final initialCamera = CameraPosition(
      target: position ?? const LatLng(0, 0),
      zoom: position != null ? 14 : 2,
    );

    final query = result?.tags.searchQuery as String? ??
        result?.tags.productName as String? ??
        '';

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map fills screen ─────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: initialCamera,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // ── Back button overlay ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FloatingActionButton.small(
                heroTag: 'mapBack',
                backgroundColor: Colors.black54,
                onPressed: () => Navigator.maybePop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          // ── Bottom panel: "Find nearby stores" ─────────────────────────────
          if (result != null && query.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.18,
              minChildSize: 0.12,
              maxChildSize: 0.35,
              builder: (ctx, scrollCtrl) => Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E2E),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Last searched product chip
                    Center(
                      child: Chip(
                        avatar: const Icon(Icons.search, size: 16),
                        label: Text(
                          query,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Find nearby stores button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.store_mall_directory_outlined),
                      label: const Text('Find nearby stores'),
                      onPressed: () => _findNearbyStores(position, query),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _findNearbyStores(LatLng? position, String query) async {
    Uri uri;
    if (position != null) {
      uri = Uri.parse(
        'geo:${position.latitude},${position.longitude}'
        '?q=${Uri.encodeComponent(query)}',
      );
    } else {
      uri = Uri.parse(
        'https://maps.google.com/?q=${Uri.encodeComponent(query)}',
      );
    }

    final canUseGeo = position != null && await canLaunchUrl(uri);
    if (!canUseGeo) {
      uri = Uri.parse(
        'https://maps.google.com/?q=${Uri.encodeComponent(query)}',
      );
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Maps app.')),
        );
      }
    }
  }
}
