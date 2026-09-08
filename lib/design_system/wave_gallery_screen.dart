import 'package:flutter/material.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_skeleton.dart';
import 'package:wave/design_system/components/wave_text_field.dart';

class WaveGalleryScreen extends StatelessWidget {
  const WaveGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.waveColors;
    final texts = context.texts;
    final s = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('WAVE Design System'),
        elevation: 0,
        backgroundColor: colors.surface,
      ),
      body: ListView(
        padding: EdgeInsetsDirectional.all(s.x24),
        children: [
          const _SectionTitle(title: '١. فۆنتەکان (Typography)'),
          Text('سەرناوی گەورە (Headline)', style: texts.headline),
          Text('سەرناوی مامناوەند (Title Large)', style: texts.title),
          Text('دەقی ئاسایی (Body Medium)', style: texts.body),
          Text(
            '١٥٠,٠٠٠ د.ع (نرخ - Tabular)', 
            style: texts.title.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: s.x32),
          const _SectionTitle(title: '٢. دوگمەکان (Buttons)'),
          WaveButton(
            label: 'دوگمەی سەرەکی (Primary)',
            onPressed: () {},
          ),
          SizedBox(height: s.x16),
          WaveButton(
            label: 'دوگمەی لاوەکی (Secondary)',
            variant: WaveButtonVariant.secondary,
            onPressed: () {},
          ),
          SizedBox(height: s.x16),
          WaveButton(
            label: 'لە کاتی لۆدینگ (Loading)',
            isLoading: true,
            onPressed: () {},
          ),
          SizedBox(height: s.x16),
          WaveButton(
            label: 'سڕینەوەی کاڵا (Destructive)',
            variant: WaveButtonVariant.destructive,
            icon: Icons.delete_outline,
            onPressed: () {},
          ),

          SizedBox(height: s.x32),
          const _SectionTitle(title: '٣. خانەی نووسین (Text Fields)'),
          const WaveTextField(
            label: 'ناوی تەواو',
            hint: 'ناوی خۆت بنووسە',
            prefixIcon: Icons.person_outline,
          ),
          SizedBox(height: s.x16),
          const WaveTextField(
            label: 'ژمارەی مۆبایل',
            hint: '0750...',
            enabled: false,
            prefixIcon: Icons.phone_android_rounded,
          ),

          SizedBox(height: s.x32),
          const _SectionTitle(title: '٤. لۆدینگی ئێسکەپەیکەر (Skeletons)'),
          Row(
            children: [
              WaveSkeleton(
                width: s.x48, 
                height: s.x48, 
                radius: s.x24,
              ),
              SizedBox(width: s.x16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WaveSkeleton(width: s.x64 * 2, height: s.x16),
                  SizedBox(height: s.x8),
                  WaveSkeleton(width: s.x64, height: s.x12),
                ],
              ),
            ],
          ),
          SizedBox(height: s.x16),
          WaveSkeleton(
            width: double.infinity,
            height: s.x64 * 2,
            radius: context.surfaces.radiusCard,
          ),
          
          SizedBox(height: s.x48),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.x16),
      child: Text(
        title,
        style: context.texts.title.copyWith(
          color: context.waveColors.accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
