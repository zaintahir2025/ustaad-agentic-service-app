import 'package:flutter/material.dart';
import '../theme/ustaad_theme.dart';
import '../widgets/primitives/primitives.dart';

/// Interactive Demo Gallery presenting the Modern Desi Professional Design System primitives.
class DesignSystemGalleryScreen extends StatelessWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UstaadColors.background,
      appBar: AppBar(
        title: Text(
          'Ustaad Design System',
          style: UstaadTypography.h3(color: UstaadColors.textPrimary),
        ),
        backgroundColor: UstaadColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: UstaadColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildSectionHeader('Modern Desi Professional', 'Phase 1 Primitive Catalog'),
                  const SizedBox(height: 8),
                  Text(
                    'Built with Emerald #0F6E56, Warm Amber #F5A623, and Warm Cream #FAFAF7 neutrals. Fully accessible (WCAG AA) with 48dp min tap targets.',
                    style: UstaadTypography.bodyMedium(),
                  ),
                  const SizedBox(height: 24),

                  // 1. Color Palette Tokens
                  _buildCategoryCard(
                    title: '1. Color System',
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildColorPill('Primary', UstaadColors.primary, Colors.white),
                        _buildColorPill('Gradient End', UstaadColors.primaryLight, Colors.white),
                        _buildColorPill('Accent Amber', UstaadColors.accent, Colors.black),
                        _buildColorPill('Background', UstaadColors.background, UstaadColors.textPrimary),
                        _buildColorPill('Surface', UstaadColors.surface, UstaadColors.textPrimary),
                        _buildColorPill('Border', UstaadColors.border, UstaadColors.textPrimary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Buttons Primitive
                  _buildCategoryCard(
                    title: '2. UstaadButton Primitives (Min 48dp Tap Target)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: UstaadButton(
                                label: 'Primary Emerald',
                                icon: const Icon(Icons.flash_on_rounded, size: 18, color: Colors.white),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: UstaadButton(
                                label: 'Secondary',
                                variant: UstaadButtonVariant.secondary,
                                icon: const Icon(Icons.calendar_today_rounded, size: 16, color: UstaadColors.primary),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: UstaadButton(
                                label: 'Ghost Action',
                                variant: UstaadButtonVariant.ghost,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: UstaadButton(
                                label: 'Danger Button',
                                variant: UstaadButtonVariant.danger,
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: UstaadButton(
                                label: 'Loading State',
                                isLoading: true,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: UstaadButton(
                                label: 'Disabled State',
                                onPressed: null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Cards Primitive
                  _buildCategoryCard(
                    title: '3. UstaadCard (Subtle Tinted Shadows & Scale Animation)',
                    child: Column(
                      children: [
                        UstaadCard(
                          onTap: () {},
                          leftAccentColor: UstaadColors.primary,
                          child: Row(
                            children: [
                              const UstaadAvatar(
                                name: 'Ahmed Electrician',
                                isOnline: true,
                                showOnlineBadge: true,
                                isVerified: true,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Ahmed Khan', style: UstaadTypography.h4()),
                                        const SizedBox(width: 6),
                                        UstaadBadge.verified(),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Master Electrician • G-13, Islamabad', style: UstaadTypography.bodySmall()),
                                  ],
                                ),
                              ),
                              Text('PKR 700', style: UstaadTypography.labelLarge(color: UstaadColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Inputs Primitive
                  _buildCategoryCard(
                    title: '4. UstaadInput (RTL-Aware, Floating Label & Errors)',
                    child: Column(
                      children: [
                        const UstaadInput(
                          label: 'Service Requirement',
                          hintText: 'e.g. AC repair urgently in Gulberg III',
                          prefixIcon: Icon(Icons.search_rounded, color: UstaadColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const UstaadInput(
                          label: 'Mobile Number',
                          hintText: '0300 1234567',
                          errorText: 'Enter a valid Pakistani mobile number',
                          prefixIcon: Icon(Icons.phone_iphone_rounded, color: UstaadColors.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Chips Primitive
                  _buildCategoryCard(
                    title: '5. UstaadChip Primitives',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        UstaadChip(
                          label: 'Electrician ⚡',
                          isSelected: true,
                          onTap: () {},
                        ),
                        UstaadChip(
                          label: 'Plumber 🚰',
                          isSelected: false,
                          count: 14,
                          onTap: () {},
                        ),
                        UstaadChip(
                          label: 'AC Repair ❄️',
                          isSelected: false,
                          onTap: () {},
                        ),
                        UstaadChip(
                          label: 'Carpenter 🔨',
                          isSelected: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Badges & Trust Signals
                  _buildCategoryCard(
                    title: '6. UstaadBadge (Authentic Trust Signals)',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        UstaadBadge.verified(),
                        UstaadBadge.topRated(),
                        UstaadBadge.backgroundChecked(),
                        const UstaadBadge(
                          label: 'High Urgency',
                          variant: UstaadBadgeVariant.error,
                          icon: Icons.timer_rounded,
                        ),
                        const UstaadBadge(
                          label: 'En Route',
                          variant: UstaadBadgeVariant.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7. Avatars
                  _buildCategoryCard(
                    title: '7. UstaadAvatar (Scales, Online Dots & Verified Rings)',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        UstaadAvatar(name: 'Ali Raza', size: UstaadAvatarSize.sm),
                        UstaadAvatar(name: 'Kamran Ali', size: UstaadAvatarSize.md, isOnline: true, showOnlineBadge: true),
                        UstaadAvatar(name: 'Zubair Electrician', size: UstaadAvatarSize.lg, isOnline: true, showOnlineBadge: true, isVerified: true),
                        UstaadAvatar(name: 'Ustaad Tariq', size: UstaadAvatarSize.xl, isVerified: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 8. Bilingual Typography
                  _buildCategoryCard(
                    title: '8. Bilingual Typography (English + Urdu Nastaliq 1.8 Line-Height)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plus Jakarta Sans Heading (32px Bold)', style: UstaadTypography.h1()),
                        const SizedBox(height: 6),
                        Text('Inter Body text with 1.5 line height for high legibility across Android and iOS.', style: UstaadTypography.bodyMedium()),
                        const UstaadDivider(label: 'اردو نستعلیق'),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'استاد — پاکستان کی قابلِ اعتماد گھریلو سروسز',
                                style: UstaadTypography.urduHeading(),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ہماری ایپ کے ذریعے مصدقہ الیکٹریشن، پلمبر اور اے سی ٹیکنیشن چند منٹوں میں اپنے گھر بلائیں۔',
                                style: UstaadTypography.urduBody(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: UstaadTypography.h2(color: UstaadColors.primary)),
        const SizedBox(height: 4),
        Text(subtitle, style: UstaadTypography.labelMedium()),
      ],
    );
  }

  Widget _buildCategoryCard({required String title, required Widget child}) {
    return UstaadCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: UstaadTypography.h4(color: UstaadColors.primaryDark)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildColorPill(String name, Color color, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: UstaadRadius.borderSm,
        border: Border.all(color: UstaadColors.border),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: textCol,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
