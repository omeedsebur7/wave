import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/checkout/domain/entities/delivery_address.dart';

/// Address picker and inline "add new".
Future<DeliveryAddress?> showAddressPicker(
  BuildContext context, {
  required List<DeliveryAddress> addresses,
  String? selectedId,
}) {
  return showModalBottomSheet<DeliveryAddress>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _AddressPickerSheet(addresses: addresses, selectedId: selectedId),
  );
}

class _AddressPickerSheet extends StatefulWidget {
  const _AddressPickerSheet({required this.addresses, this.selectedId});

  final List<DeliveryAddress> addresses;
  final String? selectedId;

  @override
  State<_AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<_AddressPickerSheet> {
  bool _adding = false;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _line = TextEditingController();
  final _landmark = TextEditingController();

  bool get _canSave =>
      _name.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _city.text.trim().isNotEmpty &&
      _line.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _adding = widget.addresses.isEmpty;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _line, _landmark]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // FIXED: Replaced raw EdgeInsets.only with EdgeInsetsDirectional and tokens
      padding: EdgeInsetsDirectional.only(
        start: WaveSpacing.x20,
        end: WaveSpacing.x20,
        top: WaveSpacing.x20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + WaveSpacing.x24,
      ),
      child: _adding ? _buildForm(context) : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.deliverTo, style: context.texts.headline), // FIXED
        const SizedBox(height: WaveSpacing.x12),
        Flexible(
          child: RadioGroup<String>(
            groupValue: widget.selectedId,
            onChanged: _pick,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final address in widget.addresses)
                  RadioListTile<String>(
                    value: address.id,
                    toggleable: true,
                    title: Text(
                      address.recipientName,
                      style: context.texts.label, // FIXED
                    ),
                    subtitle: Text(
                      address.summary,
                      style: context.texts.caption, // FIXED
                    ),
                    contentPadding: EdgeInsetsDirectional.zero, // FIXED
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: WaveSpacing.x8),
        WaveButton( // FIXED: TextButton.icon to WaveButton
          variant: WaveButtonVariant.tertiary,
          icon: Icons.add,
          label: context.l10n.addANewAddress,
          onPressed: () => setState(() => _adding = true),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.newAddress, style: context.texts.headline), // FIXED
          const SizedBox(height: WaveSpacing.x16),
          _Field(
            controller: _name,
            label: context.l10n.whoIsReceiving,
            onChanged: _rebuild,
          ),
          _Field(
            controller: _phone,
            label: context.l10n.phoneForCourier,
            keyboardType: TextInputType.phone,
            forceLtr: true, // FIXED: Explicit LTR for phone numbers in RTL layout
            onChanged: _rebuild,
          ),
          _Field(
            controller: _city,
            label: context.l10n.city,
            onChanged: _rebuild,
          ),
          _Field(
            controller: _line,
            label: context.l10n.addressLine,
            maxLines: 2,
            onChanged: _rebuild,
          ),
          _Field(
            controller: _landmark,
            label: context.l10n.landmarkOptional,
            hint: context.l10n.landmarkHint,
            onChanged: _rebuild,
          ),
          const SizedBox(height: WaveSpacing.x8),
          Text(
            context.l10n.landmarkNote,
            style: context.texts.caption, // FIXED
          ),
          const SizedBox(height: WaveSpacing.x16),
          SizedBox(
            width: double.infinity,
            child: WaveButton( // FIXED: FilledButton to WaveButton
              label: context.l10n.saveAddress,
              expand: true,
              onPressed: _canSave
                  ? () => Navigator.pop(
                        context,
                        DeliveryAddress(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          recipientName: _name.text.trim(),
                          phoneNumber: _phone.text.trim(),
                          city: _city.text.trim(),
                          addressLine: _line.text.trim(),
                          landmark: _landmark.text.trim().isEmpty
                              ? null
                              : _landmark.text.trim(),
                        ),
                      )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _pick(String? id) {
    final chosenId = id ?? widget.selectedId;
    if (chosenId == null) return;

    final chosen = widget.addresses.firstWhere((a) => a.id == chosenId);
    Navigator.pop(context, chosen);
  }

  void _rebuild(String _) => setState(() {});
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.forceLtr = false,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x12), // FIXED
      child: WaveTextField( // FIXED: TextField to WaveTextField
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        forceLtr: forceLtr, // §8.15 compliant
        label: label,
        hint: hint,
      ),
    );
  }
}
