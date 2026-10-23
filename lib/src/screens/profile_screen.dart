import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';
import '../ustaad_state.dart';
import '../widgets/common_widgets.dart';
import 'command_center_screen.dart';
import 'gateway_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _bio = TextEditingController();
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    final user = context.read<UstaadState>().user;
    if (user != null) {
      _name.text = user.name;
      _phone.text = user.phone ?? '';
      _city.text = user.city;
      _address.text = user.address;
      _bio.text = user.bio;
      _language = user.preferredLanguage;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final user = state.user;
    if (user == null) {
      return const GatewayScreen();
    }

    return Stage(
      wideMaxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBarLine(
            title: AppLocalizations.of(context)?.profile ?? 'Profile',
            subtitle: user.email,
            leading: IconButton(
              tooltip: AppLocalizations.of(context)?.home ?? 'Home',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 16),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Avatar(url: user.avatarUrl, size: 96),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          tooltip: 'Change photo',
                          onPressed: state.profileBusy ? null : _pickPhoto,
                          icon: state.profileBusy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SecurityPanel(
                  email: user.email,
                  sessionExpiresAt: state.sessionExpiresAt,
                  rememberedEmail: state.savedEmail.isNotEmpty,
                ),
                const SizedBox(height: 18),
                SavedProvidersPanel(providers: state.savedProviders),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _city,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _language,
                        decoration: const InputDecoration(
                          labelText: 'Language',
                          prefixIcon: Icon(Icons.translate),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'English',
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: 'Urdu',
                            child: Text('اردو (Urdu)'),
                          ),
                          DropdownMenuItem(
                            value: 'Roman Urdu',
                            child: Text('Roman Urdu'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _language = value);
                            context.read<UstaadState>().setLanguage(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bio,
                  minLines: 3,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: state.profileBusy ? null : _save,
                  icon: state.profileBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    state.profileBusy
                        ? 'Saving profile...'
                        : (AppLocalizations.of(context)?.saveProfile ??
                            'Save profile'),
                  ),
                ),
                if (state.bannerMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    state.bannerMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final appState = context.read<UstaadState>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 84,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final ok = await appState.uploadProfilePhoto(
      bytes: bytes,
      fileName: picked.name,
      contentType: picked.mimeType ?? contentTypeFor(picked.name),
    );
    if (!mounted) return;
    _show(appState.bannerMessage ??
        (ok ? 'Profile photo updated.' : 'Photo upload failed.'));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _show('Enter your name.');
      return;
    }
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && phone.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      _show('Please enter a valid phone number (at least 10 digits).');
      return;
    }
    final ok = await context.read<UstaadState>().saveProfile(
          name: name,
          phone: phone,
          city: _city.text.trim().isEmpty ? 'Islamabad' : _city.text.trim(),
          address: _address.text.trim(),
          preferredLanguage: _language,
          bio: _bio.text.trim(),
        );
    if (!mounted) return;
    _show(context.read<UstaadState>().bannerMessage ??
        (ok ? 'Profile updated.' : 'Profile could not be saved.'));
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class SecurityPanel extends StatelessWidget {
  const SecurityPanel({
    super.key,
    required this.email,
    required this.sessionExpiresAt,
    required this.rememberedEmail,
  });

  final String email;
  final DateTime? sessionExpiresAt;
  final bool rememberedEmail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.security ?? 'Security',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Chip(
                avatar: const Icon(Icons.verified_user, size: 16),
                label: Text(
                  AppLocalizations.of(context)?.protected ?? 'Protected',
                ),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: scheme.primary.withValues(alpha: 0.42)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SecurityStatusRow(
            icon: Icons.alternate_email,
            label: 'Account',
            value: email,
          ),
          SecurityStatusRow(
            icon: Icons.timer,
            label: 'Session',
            value: sessionExpiresAt == null
                ? 'Managed by Firebase Auth'
                : 'Refreshes until ${shortDateTime(sessionExpiresAt!)}',
          ),
          SecurityStatusRow(
            icon: rememberedEmail ? Icons.mark_email_read : Icons.privacy_tip,
            label: 'Remember email',
            value: rememberedEmail ? 'Enabled on this device' : 'Off',
          ),
        ],
      ),
    );
  }
}

class SavedProvidersPanel extends StatelessWidget {
  const SavedProvidersPanel({super.key, required this.providers});

  final List<UstaadProviderProfile> providers;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const InlineEmpty(
        icon: Icons.bookmark_border,
        text: 'Saved providers will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Saved providers',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        ...providers.take(3).map((provider) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ProviderListTile(provider: provider),
          );
        }),
      ],
    );
  }
}

class SecurityStatusRow extends StatelessWidget {
  const SecurityStatusRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
