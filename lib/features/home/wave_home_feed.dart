import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_product_card.dart';
import 'package:wave/design_system/components/wave_skeletons.dart'; 
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/design_system/components/wave_text_field.dart';

class WaveHomeFeed extends StatefulWidget {
  const WaveHomeFeed({super.key});

  @override
  State<WaveHomeFeed> createState() => _WaveHomeFeedState();
}

class _WaveHomeFeedState extends State<WaveHomeFeed> {
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.waveColors;
    final texts = context.texts;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.background,
        centerTitle: false,
        title: Text(
          'WAVE',
          style: texts.headline.copyWith( // FIXED: headlineMedium -> headline
            color: colors.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined, color: colors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: WaveStateView(
        state: _isError ? WaveViewState.error : WaveViewState.content,
        onErrorRetry: _fetchData,
        content: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric( // FIXED
                horizontal: WaveSpacing.x16,
                vertical: WaveSpacing.x8,
              ),
              sliver: SliverToBoxAdapter(
                child: WaveTextField(
                  hint: 'بگەڕێ بۆ نموونە "iPhone 15"...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (val) {},
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric( // FIXED
                horizontal: WaveSpacing.x16,
                vertical: WaveSpacing.x16,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'نوێترین کاڵاکان',
                  style: texts.title.copyWith(fontWeight: FontWeight.bold), // FIXED: titleLarge -> title
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: WaveSpacing.x16), // FIXED
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: WaveSpacing.x16,
                  crossAxisSpacing: WaveSpacing.x16,
                  childAspectRatio: 0.62, 
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_isLoading) {
                      return WaveSkeletons.productCard(context);
                    }
                    
                    return WaveProductCard(
                      productId: 'product_$index', 
                      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=600&auto=format&fit=crop', 
                      title: 'بیستۆکی بێوایەر - جۆری نایاب بە دەنگی بەرز',
                      priceMinor: 45000, 
                      originalPriceMinor: 60000, 
                      onTap: () {},
                    );
                  },
                  childCount: 6,
                ),
              ),
            ),
            
            const SliverPadding(
              padding: EdgeInsetsDirectional.only(bottom: WaveSpacing.x40), // FIXED
            ),
          ],
        ),
      ),
    );
  }
}
