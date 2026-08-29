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
          // RadioGroup owns the selection and the callback; the tiles below
          // carry only their own value. That is the whole shape of the
          // migration away from the deprecated per-tile groupValue/onChanged,
          // which Flutter removes after 3.32.
          //
          // The callback receives the selected ID rather than the address
          // object, so the address is looked up rather than captured from the
          // loop. Slightly more code, but it is now impossible for a tile to
          // pop with an address other than the one whose value was selected —
          // the closure-capture version had no such guarantee, it just
          // happened to be written correctly.
          child: RadioGroup<String>(
            groupValue: widget.selectedId,
            onChanged: _pick,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final address in widget.addresses)
                  RadioListTile<String>(
                    value: address.id,
                    // toggleable is what makes the ALREADY-SELECTED row
                    // tappable. See _pick below for why that matters and how
                    // the resulting null is interpreted.
                    toggleable: true,
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

  /// Confirms an address and closes the sheet.
  ///
  /// [id] is null when the user tapped the row that was ALREADY selected.
  ///
  /// That case is the whole reason `toggleable: true` is set on the tiles.
  /// Without it, RadioListTile only fires onChanged when `!checked` — so
  /// opening this sheet, seeing your current address, and tapping it to
  /// confirm did nothing at all. The sheet just sat there. That behaviour
  /// predates the RadioGroup migration; it was inherited from the original
  /// per-tile version and was never right, it simply went unnoticed because
  /// the obvious test is "tap a DIFFERENT address", which always worked.
  ///
  /// `toggleable` normally means "tap the selected option to clear it", and
  /// null is normally "nothing is selected now". Here there is no such thing
  /// as clearing — a checkout sheet with no delivery address chosen is not a
  /// state this screen can produce or represent — so null is read as
  /// "reaffirmed the current one", which is exactly what the tap meant.
  ///
  /// The defensive null-check on `selectedId` is for the case that cannot
  /// currently happen but would be silent if it ever did: toggleable firing
  /// with nothing previously selected. Returning early leaves the sheet open
  /// rather than popping with a wrong address.
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
