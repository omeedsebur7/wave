import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/features/publish/data/product_publish_service.dart';

/// Marketplace listing form (§4).
class ListProductPage extends StatefulWidget {
  const ListProductPage({super.key});

  @override
  State<ListProductPage> createState() => _ListProductPageState();
}

class _ListProductPageState extends State<ListProductPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '1');

  final _images = <File>[];
  final String _currency = 'IQD';
  bool _publishing = false;
  double? _progress;

  @override
  void dispose() {
    for (final c in [_title, _description, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _priceMinor {
    final parsed = double.tryParse(_price.text.trim()) ?? 0;
    // IQD has no minor unit in practice, so the entered number IS the minor
    // amount. Multiplying by 100 here would charge everyone a hundred times
    // the price.
    final multiplier = Money.decimalsFor(_currency) == 0 ? 1 : 100;
    return (parsed * multiplier).round();
  }

  bool get _canPublish =>
      !_publishing &&
      _title.text.trim().isNotEmpty &&
      _priceMinor > 0 &&
      _images.isNotEmpty;

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      limit: ProductPublishService.maxImages - _images.length,
      imageQuality: 85,
    );
    if (picked.isEmpty || !mounted) return;

    setState(() {
      _images.addAll(
        picked
            .take(ProductPublishService.maxImages - _images.length)
            .map((x) => File(x.path)),
      );
    });
  }

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _progress = 0;
    });

    final result = await getIt<ProductPublishService>().publish(
      title: _title.text,
      description: _description.text,
      priceMinor: _priceMinor,
      currency: _currency,
      stock: int.tryParse(_stock.text.trim()) ?? 1,
      images: _images,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;
    setState(() {
      _publishing = false;
      _progress = null;
    });

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(context, f)))),
      (productId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.listingIsLive),
            action: SnackBarAction(
              // The next useful action, not a dead end. A listing with a Reel
              // behind it sells; one sitting in the grid mostly does not.
              label: context.l10n.makeAReel,
              onPressed: () => context.push(Routes.uploadReel),
            ),
          ),
        );
        context.pushReplacement(Routes.productDetailPath(productId));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return PopScope(
      canPop: !_publishing,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.listAProduct),
          actions: [
            TextButton(
              onPressed: _canPublish ? _publish : null,
              child: Text(context.l10n.publish),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PhotoStrip(
              images: _images,
              onAdd: _images.length >= ProductPublishService.maxImages
                  ? null
                  : _pickImages,
              onRemove: (i) => setState(() => _images.removeAt(i)),
            ),
            const SizedBox(height: 8),
            Text(
              // Says what the first photo is FOR, which changes which one
              // people pick.
              context.l10n.coverPhotoNote(ProductPublishService.maxImages),
              style: context.texts.bodySmall,
            ),

            const SizedBox(height: 24),
            TextField(
              controller: _title,
              enabled: !_publishing,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.l10n.whatIsIt,
                border: const OutlineInputBorder(),
              ),
            ),

            TextField(
              controller: _description,
              enabled: !_publishing,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.description,
                hintText: context.l10n.descriptionHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _price,
                    enabled: !_publishing,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.price,
                      suffixText: _currency,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stock,
                    enabled: !_publishing,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: context.l10n.howMany,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            if (_priceMinor > 0) ...[
              const SizedBox(height: 8),
              Text(
                // Echoes the parsed figure back. A price typed wrong is the
                // most expensive typo on this screen.
                context.l10n.buyersWillSee(
                  context.money(_priceMinor, _currency),
                ),
                style: context.texts.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ],

            if (_progress != null) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(context.l10n.uploadingPhotos,
                  style: context.texts.bodySmall,),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<File> images;
  final VoidCallback? onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + (onAdd == null ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == images.length) {
            return InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius:
                      BorderRadius.circular(WaveSurfaces.radiusCard),
                ),
                child: Icon(Icons.add_a_photo_outlined, color: c.textSecondary),
              ),
            );
          }

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
                child: Image.file(
                  images[i],
                  width: 90,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              if (i == 0)
                PositionedDirectional(
                  bottom: 4,
                  start: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.l10n.cover,
                      style: context.texts.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                top: 2,
                end: 2,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => onRemove(i),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
