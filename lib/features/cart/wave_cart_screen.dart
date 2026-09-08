import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';

class WaveCartScreen extends StatefulWidget {
  const WaveCartScreen({super.key});

  @override
  State<WaveCartScreen> createState() => _WaveCartScreenState();
}

class _WaveCartScreenState extends State<WaveCartScreen> {
  final bool _isCartEmpty = true;
  bool _isCheckingOut = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.waveColors;
    final texts = context.texts;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0, 
        backgroundColor: colors.background,
        title: Text(
          'عەرەبانە',
          style: texts.title.copyWith(fontWeight: FontWeight.bold), 
        ),
        centerTitle: true,
      ),
      body: WaveStateView(
        state: _isCartEmpty 
            ? WaveEmpty(
                icon: Icons.shopping_cart_outlined,
                title: 'عەرەبانەکەت بەتاڵە',
                body: 'هێشتا هیچ کاڵایەکت هەڵنەبژاردووە. باشترین ئۆفەرەکان لێرەن!',
                actionLabel: 'گەڕان بەدوای کاڵاکان',
                onAction: () => Navigator.of(context).pop(),
              )
            : const WaveContent(),
        content: _buildCartContent(context),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context) {
    final colors = context.waveColors;
    final texts = context.texts;
    final s = context.spacing;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsetsDirectional.all(s.x16), 
            itemCount: 3,
            separatorBuilder: (_, __) => SizedBox(height: s.x16), 
            itemBuilder: (context, index) {
              return _CartItemTile(index: index);
            },
          ),
        ),
        
        Container(
          padding: EdgeInsetsDirectional.only( 
            top: s.x16,
            start: s.x16,
            end: s.x16,
            bottom: s.x16 + MediaQuery.paddingOf(context).bottom, 
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.05),
                offset: const Offset(0, -4), 
                blurRadius: 12, 
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('کۆی گشتی:', style: texts.title), 
                  Text(
                    '١٣٥,٠٠٠ د.ع', 
                    style: texts.headline.copyWith( 
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: s.x16), 
              SizedBox(
                width: double.infinity,
                child: WaveButton(
                  label: 'پارەدان و کڕین (Checkout)',
                  isLoading: _isCheckingOut,
                  onPressed: () {
                    setState(() => _isCheckingOut = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _isCheckingOut = false);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.waveColors;
    
    return Container(
      height: 96, // FIXED: 96 to 96.0
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Text('کاڵای ژمارە $index', style: context.texts.body), 
      ),
    );
  }
}
