import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/location_provider.dart';
import '../../providers/search_provider.dart';

/// Maps a Gemini product category and product name to a specific retail store
/// type that Google Places Text Search can actually find.
///
/// Examples:
///   Electronics / "iPhone case"   → "phone accessories store"
///   Puzzles     / "Rubik's Cube"  → "toy store"
///   Footwear    / "running shoe"  → "shoe store"
String _storeQueryFor(String category, String productName) {
  final cat  = category.toLowerCase().trim();
  final name = productName.toLowerCase().trim();

  // ── Electronics & tech ──────────────────────────────────────────────────
  if (_any(cat, ['mobile', 'phone', 'smartphone', 'iphone', 'android']) ||
      _any(name, ['iphone', 'samsung', 'pixel', 'phone case', 'charger', 'cable'])) {
    return 'mobile phone store';
  }
  if (_any(cat, ['laptop', 'computer', 'pc', 'notebook']) ||
      _any(name, ['laptop', 'notebook', 'macbook', 'thinkpad', 'dell', 'hp laptop'])) {
    return 'computer store';
  }
  if (_any(cat, ['headphone', 'audio', 'earphone', 'speaker']) ||
      _any(name, ['headphone', 'earbuds', 'airpods', 'speaker'])) {
    return 'electronics store';
  }
  if (_any(cat, ['camera', 'photography']) ||
      _any(name, ['camera', 'lens', 'dslr', 'mirrorless'])) {
    return 'camera store';
  }
  if (_any(cat, ['television', 'tv', 'monitor', 'display'])) {
    return 'electronics store';
  }
  if (_any(cat, ['watch', 'smartwatch', 'wearable']) ||
      _any(name, ['watch', 'smartwatch', 'fitbit', 'garmin'])) {
    return 'watch store';
  }
  if (_any(cat, ['electronic', 'gadget', 'tech'])) {
    return 'electronics store';
  }

  // ── Clothing & fashion ──────────────────────────────────────────────────
  if (_any(cat, ['clothing', 'fashion', 'apparel', 'shirt', 'dress', 'jacket',
      'trouser', 'jeans', 'sweater', 'hoodie', 't-shirt'])) {
    return 'clothing store';
  }
  if (_any(cat, ['footwear', 'shoe', 'sneaker', 'boot', 'sandal', 'slipper']) ||
      _any(name, ['shoe', 'sneaker', 'boot', 'slipper', 'sandal'])) {
    return 'shoe store';
  }
  if (_any(cat, ['jewelry', 'jewellery', 'ring', 'necklace', 'bracelet']) ||
      _any(name, ['ring', 'necklace', 'bracelet', 'earring', 'pendant'])) {
    return 'jewelry store';
  }
  if (_any(cat, ['bag', 'handbag', 'backpack', 'purse', 'luggage'])) {
    return 'luggage store';
  }
  if (_any(cat, ['sunglasses', 'eyewear', 'glasses', 'optical'])) {
    return 'optical store';
  }

  // ── Home & furniture ────────────────────────────────────────────────────
  if (_any(cat, ['furniture', 'sofa', 'table', 'chair', 'bed', 'shelf'])) {
    return 'furniture store';
  }
  if (_any(cat, ['home decor', 'decoration', 'interior', 'lamp', 'curtain', 'rug'])) {
    return 'home goods store';
  }
  if (_any(cat, ['kitchenware', 'cookware', 'kitchen', 'appliance']) ||
      _any(name, ['pan', 'pot', 'knife', 'blender', 'microwave', 'kettle'])) {
    return 'kitchen store';
  }
  if (_any(cat, ['bedding', 'pillow', 'mattress', 'duvet', 'linen'])) {
    return 'home goods store';
  }

  // ── Toys & games ────────────────────────────────────────────────────────
  if (_any(cat, ['toy', 'puzzle', 'game', 'lego', 'board game', 'action figure']) ||
      _any(name, ["rubik", 'lego', 'puzzle', 'toy', 'doll', 'board game', 'jigsaw'])) {
    return 'toy store';
  }
  if (_any(cat, ['video game', 'gaming', 'console', 'playstation', 'xbox', 'nintendo'])) {
    return 'video game store';
  }

  // ── Sports & outdoors ───────────────────────────────────────────────────
  if (_any(cat, ['sport', 'fitness', 'exercise', 'gym', 'workout', 'outdoor',
      'camping', 'hiking', 'cycling', 'yoga', 'swimming'])) {
    return 'sporting goods store';
  }

  // ── Beauty & health ─────────────────────────────────────────────────────
  if (_any(cat, ['beauty', 'cosmetic', 'skincare', 'makeup', 'perfume', 'fragrance']) ||
      _any(name, ['lipstick', 'foundation', 'serum', 'moisturizer', 'mascara'])) {
    return 'beauty supply store';
  }
  if (_any(cat, ['health', 'medicine', 'supplement', 'vitamin', 'pharmacy'])) {
    return 'pharmacy';
  }

  // ── Books & stationery ──────────────────────────────────────────────────
  if (_any(cat, ['book', 'stationery', 'office supply', 'pen', 'notebook', 'paper'])) {
    return 'bookstore';
  }

  // ── Food & grocery ──────────────────────────────────────────────────────
  if (_any(cat, ['food', 'grocery', 'beverage', 'snack', 'drink', 'coffee', 'tea'])) {
    return 'grocery store';
  }

  // ── Pet supplies ────────────────────────────────────────────────────────
  if (_any(cat, ['pet', 'dog', 'cat', 'aquarium', 'bird'])) {
    return 'pet store';
  }

  // ── Music ────────────────────────────────────────────────────────────────
  if (_any(cat, ['music', 'musical instrument', 'guitar', 'piano', 'drum'])) {
    return 'music store';
  }

  // ── Art & craft ─────────────────────────────────────────────────────────
  if (_any(cat, ['art', 'craft', 'hobby', 'drawing', 'painting', 'sewing'])) {
    return 'art supply store';
  }

  // ── Automotive ──────────────────────────────────────────────────────────
  if (_any(cat, ['automotive', 'car', 'vehicle', 'motorcycle']) ||
      _any(name, ['car', 'tyre', 'tire', 'lubricant', 'motor oil'])) {
    return 'auto parts store';
  }

  // ── Generic fallback ────────────────────────────────────────────────────
  // Use the category name if short enough for a clear Places query
  if (cat.isNotEmpty && cat.length <= 18 && !cat.contains(' ')) {
    return '$category store';
  }

  // Absolute fallback — just find local shops
  return 'retail store near me';
}

/// Returns true if [text] contains any of [keywords].
bool _any(String text, List<String> keywords) =>
    keywords.any((k) => text.contains(k));

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _locationDialogShown = false;

  // Places state
  Set<Marker>  _markers          = {};
  bool         _isLoadingPlaces  = false;
  int          _placeCount       = -1; // -1 = not yet searched

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

    // Display label: show product name so user knows what they last searched
    final displayQuery = result?.tags.productName ?? result?.tags.searchQuery ?? '';

    // Places query: map category + productName to a specific retail store type.
    // This beats sending the raw search query to Google Places.
    final placesQuery = _storeQueryFor(
      result?.tags.category ?? '',
      result?.tags.productName ?? '',
    );

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map fills screen ───────────────────────────────────────
          GoogleMap(
            initialCameraPosition: initialCamera,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (ctrl) {
              if (!_mapController.isCompleted) _mapController.complete(ctrl);
            },
          ),

          // ── Back button overlay ───────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'mapBack',
                    backgroundColor: Colors.black54,
                    onPressed: () => Navigator.maybePop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  // "View Results" button — shown when user came from a search
                  if (result != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FloatingActionButton.extended(
                        heroTag: 'mapResults',
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: const Text('Results',
                            style: TextStyle(fontSize: 13)),
                        onPressed: () => context.push('/results'),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Bottom panel ──────────────────────────────────────────────────
          if (result != null && displayQuery.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.20,
              minChildSize: 0.12,
              maxChildSize: 0.45,
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
                          displayQuery,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Place count badge (after search)
                    if (_placeCount == 0)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Center(
                          child: Text(
                            'No stores found nearby.',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      )
                    else if (_placeCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Center(
                          child: Text(
                            '$_placeCount store${_placeCount == 1 ? '' : 's'} found nearby',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                    // Find nearby stores button
                    ElevatedButton.icon(
                      icon: _isLoadingPlaces
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.store_mall_directory_outlined),
                      label: Text(_isLoadingPlaces
                          ? 'Searching…'
                          : 'Find nearby stores'),
                      onPressed: _isLoadingPlaces
                          ? null
                          : () => _loadNearbyPlaces(position, placesQuery),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadNearbyPlaces(LatLng? position, String query) async {
    if (_isLoadingPlaces) return;
    setState(() {
      _isLoadingPlaces = true;
      _markers = {};
      _placeCount = -1;
    });

    try {
      final places = await ApiClient.instance.getNearbyPlaces(
        query: query,
        lat: position?.latitude,
        lng: position?.longitude,
      );

      final newMarkers = <Marker>{};
      for (final p in places) {
        final lat = (p['lat'] as num?)?.toDouble();
        final lng = (p['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final id = MarkerId(p['placeId'] as String? ?? '$lat,$lng');
        newMarkers.add(
          Marker(
            markerId: id,
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: p['name'] as String? ?? 'Store',
              snippet: p['address'] as String? ?? '',
            ),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _placeCount = newMarkers.length;
          _isLoadingPlaces = false;
        });

        // Zoom to fit all markers if we found any
        if (newMarkers.isNotEmpty && _mapController.isCompleted) {
          final ctrl = await _mapController.future;
          if (newMarkers.length == 1) {
            ctrl.animateCamera(
              CameraUpdate.newLatLngZoom(newMarkers.first.position, 15),
            );
          } else {
            final lats = newMarkers.map((m) => m.position.latitude);
            final lngs = newMarkers.map((m) => m.position.longitude);
            ctrl.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(lats.reduce((a, b) => a < b ? a : b),
                      lngs.reduce((a, b) => a < b ? a : b)),
                  northeast: LatLng(lats.reduce((a, b) => a > b ? a : b),
                      lngs.reduce((a, b) => a > b ? a : b)),
                ),
                80,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load nearby stores: $e')),
        );
      }
    }
  }
}
