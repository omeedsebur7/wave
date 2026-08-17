import 'package:flutter/material.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/features/checkout/domain/entities/delivery_address.dart';

/// Address picker and inline "add new".
///
/// Adding an address is inline rather than a separate route on purpose: pushing
/// a full page mid-checkout is where people leave.
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
    // Straight into the form when there is nothing to pick from — an empty
    // list with an "Add" button is one pointless tap.
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: _adding ? _buildForm(context) : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.deliverTo, style: context.texts.headlineMedium),
        const SizedBox(height: 12),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final address in widget.addresses)
                RadioListTile<String>(
                  value: address.id,
                  groupValue: widget.selectedId,
                  onChanged: (_) => Navigator.pop(context, address),
                  title: Text(
                    address.recipientName,
                    style: context.texts.labelMedium,
                  ),
                  subtitle: Text(
                    address.summary,
                    style: context.texts.bodySmall,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _adding = true),
          icon: const Icon(Icons.add),
          label: Text(context.l10n.addANewAddress),
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
          Text(context.l10n.newAddress, style: context.texts.headlineMedium),
          const SizedBox(height: 16),
          _Field(
            controller: _name,
            label: context.l10n.whoIsReceiving,
            onChanged: _rebuild,
          ),
          _Field(
            controller: _phone,
            label: context.l10n.phoneForCourier,
            keyboardType: TextInputType.phone,
            // Phone numbers stay LTR even in an RTL layout.
            textDirection: TextDirection.ltr,
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
          const SizedBox(height: 8),
          Text(
            context.l10n.landmarkNote,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
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
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              child: Text(context.l10n.saveAddress),
            ),
          ),
        ],
      ),
    );
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
    this.textDirection,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: textDirection,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
