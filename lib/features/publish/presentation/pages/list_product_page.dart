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
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/publish/data/product_publish_service.dart';

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
            WaveButton(
              variant: WaveButtonVariant.tertiary,
              size: WaveButtonSize.sm,
              label: context.l10n.publish,
              isLoading: _publishing,
              onPressed: _canPublish ? _publish : null,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsetsDirectional.all(WaveSpacing.x20),
          children: [
            _PhotoStrip(
              images: _images,
              onAdd: _images.length >= ProductPublishService.maxImages
                  ? null
                  : _pickImages,
              onRemove: (i) => setState(() => _images.removeAt(i)),
            ),
            const SizedBox(height: WaveSpacing.x8),
            Text(
              context.l10n.coverPhotoNote(ProductPublishService.maxImages),
              style: context.texts.caption,
            ),

            const SizedBox(height: WaveSpacing.x24),
            WaveTextField(
              controller: _title,
              enabled: !_publishing,
              label: context.l10n.whatIsIt,
              onChanged: (_) => setState(() {}),
            ),
            
            const SizedBox(height: WaveSpacing.x16),
            WaveTextField(
              controller: _description,
              enabled: !_publishing,
              maxLines: 4,
              label: context.l10n.description,
              hint: context.l10n.descriptionHint,
            ),

            const SizedBox(height: WaveSpacing.x16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: WaveTextField(
                    controller: _price,
                    enabled: !_publishing,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    forceLtr: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    label: context.l10n.price,
                    hint: _currency, 
                  ),
                ),
                const SizedBox(width: WaveSpacing.x12),
                Expanded(
                  child: WaveTextField(
                    controller: _stock,
                    enabled: !_publishing,
                    keyboardType: TextInputType.number,
                    forceLtr: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    label: context.l10n.howMany,
                  ),
                ),
              ],
            ),

            if (_priceMinor > 0) ...[
              const SizedBox(height: WaveSpacing.x8),
              Text(
                context.l10n.buyersWillSee(
                  context.money(_priceMinor, _currency),
                ),
                style: context.texts.caption.copyWith(color: c.textSecondary),
              ),
            ],

            if (_progress != null) ...[
              const SizedBox(height: WaveSpacing.x24),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: WaveSpacing.x8),
              Text(context.l10n.uploadingPhotos,
                  style: context.texts.caption,),
            ],

            const SizedBox(height: WaveSpacing.x40),
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
    final s = context.surfaces;

    return SizedBox(
      height: 110, // FIXED
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + (onAdd == null ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(width: WaveSpacing.x8),
        itemBuilder: (context, i) {
          if (i == images.length) {
            return InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(s.radiusCard),
              child: Container(
                width: 90, // FIXED
                decoration: BoxDecoration(
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(s.radiusCard),
                ),
                child: Icon(Icons.add_a_photo_outlined, color: c.textSecondary),
              ),
            );
          }

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(s.radiusCard),
                child: Image.file(
                  images[i],
                  width: 90, // FIXED
                  height: 110, // FIXED
                  fit: BoxFit.cover,
                ),
              ),
              if (i == 0)
                PositionedDirectional(
                  bottom: WaveSpacing.x4,
                  start: WaveSpacing.x4,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: WaveSpacing.x8,
                      vertical: WaveSpacing.x4,
                    ),
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(6), // FIXED
                    ),
                    child: Text(
                      context.l10n.cover,
                      style: context.texts.caption.copyWith(
                        color: c.onScrim, // FIXED
                        fontSize: 10, // FIXED
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                top: WaveSpacing.x4,
                end: WaveSpacing.x4,
                child: Material(
                  color: c.scrim, // FIXED
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => onRemove(i),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(WaveSpacing.x4), // FIXED
                      child: Icon(Icons.close, size: 14, color: c.onScrim), // FIXED
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
