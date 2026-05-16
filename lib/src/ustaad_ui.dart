import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'models.dart';
import 'ustaad_state.dart';

class UstaadRouter extends StatelessWidget {
  const UstaadRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();

    if (!state.bootstrapped) {
      return const _LoadingScreen();
    }

    final screen = switch (state.screen) {
      UstaadScreen.gateway => const GatewayScreen(),
      UstaadScreen.commandCenter => const CommandCenterScreen(),
      UstaadScreen.bookings => const BookingsScreen(),
      UstaadScreen.profile => const ProfileScreen(),
      UstaadScreen.selection => const SelectionScreen(),
      UstaadScreen.workflow => const WorkflowScreen(),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: screen,
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class GatewayScreen extends StatefulWidget {
  const GatewayScreen({super.key});

  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen> {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _joinName = TextEditingController();
  final _joinEmail = TextEditingController();
  final _joinPhone = TextEditingController();
  final _joinPassword = TextEditingController();

  bool _creatingAccount = false;
  bool _remember = false;
  bool _obscure = true;
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final savedEmail = context.read<UstaadState>().savedEmail;
    _loginEmail.text = savedEmail;
    _remember = savedEmail.isNotEmpty;
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _joinName.dispose();
    _joinEmail.dispose();
    _joinPhone.dispose();
    _joinPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Stage(
      wideMaxWidth: 1040,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final form = _Panel(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: _creatingAccount ? _joinForm() : _loginForm(),
            ),
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: _ThemeButton(),
                ),
                const SizedBox(height: 12),
                const _BrandHeader(),
                const SizedBox(height: 24),
                form,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: _HeroPanel()),
              const SizedBox(width: 20),
              Expanded(child: form),
            ],
          );
        },
      ),
    );
  }

  Widget _loginForm() {
    final busy = context.watch<UstaadState>().authBusy;
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _loginEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        _PasswordField(
          controller: _loginPassword,
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remember email'),
          value: _remember,
          onChanged: (value) => setState(() => _remember = value),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: busy ? null : _submitLogin,
          child: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('CONTINUE'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : _showResetDialog,
          child: const Text('Forgot password?'),
        ),
        TextButton(
          onPressed:
              busy ? null : () => setState(() => _creatingAccount = true),
          child: const Text('Create a new account'),
        ),
      ],
    );
  }

  Widget _joinForm() {
    final busy = context.watch<UstaadState>().authBusy;
    return Column(
      key: const ValueKey('join'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _joinName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _joinEmail,
          keyboardType: TextInputType.emailAddress,
          decoration:
              InputDecoration(labelText: 'Email', errorText: _emailError),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _joinPhone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone (+92...)',
            errorText: _phoneError,
          ),
        ),
        const SizedBox(height: 12),
        _PasswordField(
          controller: _joinPassword,
          obscure: _obscure,
          onToggle: () => setState(() => _obscure = !_obscure),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: busy ? null : _submitJoin,
          child: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('CREATE ACCOUNT'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed:
              busy ? null : () => setState(() => _creatingAccount = false),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }

  Future<void> _submitLogin() async {
    final email = _loginEmail.text.trim();
    final password = _loginPassword.text.trim();
    if (!_validEmail(email)) {
      _show('Enter a valid email.');
      return;
    }
    if (password.isEmpty) {
      _show('Enter your password.');
      return;
    }

    final ok = await context.read<UstaadState>().signIn(
          email: email,
          password: password,
          remember: _remember,
        );
    if (!mounted || ok) return;
    _show(context.read<UstaadState>().bannerMessage ?? 'Login failed.');
  }

  Future<void> _submitJoin() async {
    final name = _joinName.text.trim();
    final email = _joinEmail.text.trim();
    final phone = _joinPhone.text.trim();
    final password = _joinPassword.text.trim();
    final phoneRegex = RegExp(r'^\+92[0-9]{10}$');

    setState(() {
      _emailError = _validEmail(email) ? null : 'Invalid email';
      _phoneError = phoneRegex.hasMatch(phone) ? null : 'Use +923001234567';
    });

    if (name.isEmpty) {
      _show('Enter your name.');
      return;
    }
    if (_emailError != null || _phoneError != null) return;
    if (password.length < 6) {
      _show('Password must be at least 6 characters.');
      return;
    }

    final ok = await context.read<UstaadState>().join(
          name: name,
          email: email,
          phone: phone,
          password: password,
          remember: _remember,
        );
    if (!mounted || ok) return;
    _show(context.read<UstaadState>().bannerMessage ?? 'Signup failed.');
  }

  bool _validEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showResetDialog() async {
    final email = TextEditingController(text: _loginEmail.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, email.text.trim()),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    email.dispose();
    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    if (!_validEmail(result)) {
      _show('Enter a valid email.');
      return;
    }
    final state = context.read<UstaadState>();
    final ok = await state.resetPassword(result);
    if (!mounted) return;
    _show(state.bannerMessage ??
        (ok ? 'Password reset email sent.' : 'Password reset failed.'));
  }
}

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  final _location = TextEditingController(text: 'G-13, Islamabad');
  final _problem = TextEditingController();

  @override
  void dispose() {
    _location.dispose();
    _problem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final user = state.user;
    final wide = MediaQuery.sizeOf(context).width >= 820;

    return _Stage(
      wideMaxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: user == null ? 'Book a service' : 'Hi ${user.firstName}',
            subtitle: 'Verified services, smart matching, live bookings',
            showNav: true,
          ),
          const SizedBox(height: 16),
          _FeatureStrip(online: state.backendOnline),
          const SizedBox(height: 16),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _requestPanel()),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _quickServices()),
              ],
            )
          else ...[
            _requestPanel(),
            const SizedBox(height: 16),
            _quickServices(),
          ],
        ],
      ),
    );
  }

  Widget _requestPanel() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _location,
            decoration: InputDecoration(
              labelText: 'Location',
              prefixIcon: const Icon(Icons.place),
              suffixIcon: IconButton(
                tooltip: 'Use current location',
                icon: const Icon(Icons.my_location),
                onPressed: () => _location.text = 'Blue Area, Islamabad',
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _problem,
            minLines: 5,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Service request',
              hintText: 'Mujhe kal subah G-13 mein AC technician chahiye',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExampleChip(
                label: 'Kal subah AC',
                onTap: () {
                  _problem.text =
                      'Mujhe kal subah G-13 mein AC technician chahiye';
                },
              ),
              _ExampleChip(
                label: 'Urgent pani leak',
                onTap: () => _problem.text = 'Urgent pani leak in kitchen',
              ),
              _ExampleChip(
                label: 'اے سی ٹھنڈا نہیں',
                onTap: () => _problem.text = 'اے سی ٹھنڈا نہیں ہو رہا',
              ),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.search),
            label: const Text('FIND PROVIDERS'),
          ),
        ],
      ),
    );
  }

  Widget _quickServices() {
    final services = [
      (Icons.ac_unit, 'AC Repair'),
      (Icons.water_drop, 'Plumber'),
      (Icons.electrical_services, 'Electrician'),
      (Icons.cleaning_services, 'Cleaning'),
      (Icons.school, 'Tutor'),
      (Icons.face_retouching_natural, 'Beautician'),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Services',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: services.map((service) {
              return ActionChip(
                avatar: Icon(service.$1, size: 18),
                label: Text(service.$2),
                onPressed: () {
                  _problem.text = 'I need a ${service.$2} expert';
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const _FeatureRow(
            icon: Icons.translate,
            title: 'Multilingual intent',
            subtitle: 'English, Urdu, Roman Urdu',
          ),
          const _FeatureRow(
            icon: Icons.verified_user,
            title: 'Trust score',
            subtitle: 'Reliability, response, reviews',
          ),
          const _FeatureRow(
            icon: Icons.route,
            title: 'Traceable workflow',
            subtitle: 'Find, rank, book, follow up',
          ),
          const _FeatureRow(
            icon: Icons.rate_review,
            title: 'Verified reviews',
            subtitle: 'Read and rate providers',
          ),
          const _FeatureRow(
            icon: Icons.manage_accounts,
            title: 'Profile control',
            subtitle: 'Photo, details, language',
          ),
        ],
      ),
    );
  }

  void _analyze() {
    final problem = _problem.text.trim();
    if (problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the service first.')),
      );
      return;
    }
    context.read<UstaadState>().startAnalysis(problem, _location.text);
  }
}

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final intent = state.intent!;
    final quote = state.quote!;

    return _Stage(
      wideMaxWidth: 1080,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: intent.description,
            subtitle: intent.location,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 16),
          _IntentSummary(intent: intent),
          const SizedBox(height: 12),
          _QuotePanel(quote: quote),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: state.rankedProviders.take(4).map((provider) {
                  return SizedBox(
                    width: wide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth,
                    child: _ProviderCard(
                      provider: provider,
                      best: provider == state.rankedProviders.first,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          _TracePanel(events: state.workflowEvents),
        ],
      ),
    );
  }
}

class WorkflowScreen extends StatelessWidget {
  const WorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    final provider = state.selectedProvider!;
    final booking = state.latestBooking;
    final eta = booking?.etaMinutes ?? etaMinutesFor(provider);
    final saving = state.bookingBusy;

    return _Stage(
      wideMaxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: saving ? 'Confirming booking' : 'Booking confirmed',
            subtitle: 'ETA: $eta minutes',
            leading: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 18),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      saving ? Icons.sync : Icons.check,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    provider.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('${provider.role} - ${provider.rating} rating'),
                ),
                const SizedBox(height: 14),
                _ContactBar(
                  phone: booking?.providerPhone ?? provider.phone,
                  whatsapp: booking?.providerWhatsapp ?? provider.whatsapp,
                ),
                const SizedBox(height: 12),
                _StatusTile(
                  icon: Icons.calendar_month,
                  title: booking?.slotLabel ?? provider.nextSlot,
                  subtitle: booking?.confirmationMessage ??
                      'Confirmed for the selected slot.',
                ),
                const SizedBox(height: 10),
                _StatusTile(
                  icon: Icons.notifications_active,
                  title: 'Smart follow-up',
                  subtitle: 'Reminder and review prompt are ready.',
                ),
                if (state.bannerMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.bannerMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _TracePanel(
                  events: state.workflowEvents,
                  initiallyExpanded: false,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: booking == null
                            ? null
                            : () => _showReviewDialog(
                                  context,
                                  providerId: booking.providerId,
                                  providerName: booking.providerName,
                                  bookingId: booking.id,
                                ),
                        icon: const Icon(Icons.star),
                        label: const Text('Review'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.read<UstaadState>().openBookings(),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Bookings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    return _Stage(
      wideMaxWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: 'Bookings',
            subtitle: 'Status, contacts, reviews',
            leading: IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 16),
          if (state.bookings.isEmpty)
            _EmptyState(
              icon: Icons.receipt_long,
              title: 'No bookings yet',
              actionLabel: 'Book a service',
              onAction: () => context.read<UstaadState>().openHome(),
            )
          else
            ...state.bookings.map((booking) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BookingCard(booking: booking),
              );
            }),
        ],
      ),
    );
  }
}

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

    return _Stage(
      wideMaxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AppBarLine(
            title: 'Profile',
            subtitle: user.email,
            leading: IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.read<UstaadState>().openHome(),
            ),
            showNav: true,
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      _Avatar(url: user.avatarUrl, size: 96),
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
                            child: Text('Urdu'),
                          ),
                          DropdownMenuItem(
                            value: 'Roman Urdu',
                            child: Text('Roman Urdu'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _language = value);
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
                  icon: const Icon(Icons.save),
                  label: const Text('SAVE PROFILE'),
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
      contentType: picked.mimeType ?? _contentTypeFor(picked.name),
    );
    if (!mounted) return;
    _show(appState.bannerMessage ??
        (ok ? 'Profile photo updated.' : 'Photo upload failed.'));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _show('Enter your name.');
      return;
    }
    final ok = await context.read<UstaadState>().saveProfile(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
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

class _Stage extends StatelessWidget {
  const _Stage({
    required this.child,
    this.wideMaxWidth = 520,
  });

  final Widget child;
  final double wideMaxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 760 ? 28.0 : 16.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wideMaxWidth),
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: horizontal, vertical: 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarLine extends StatelessWidget {
  const _AppBarLine({
    required this.title,
    required this.subtitle,
    this.leading,
    this.showNav = false,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final bool showNav;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (showNav && state.isSignedIn) ...[
          IconButton(
            tooltip: 'Bookings',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.read<UstaadState>().openBookings(),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.read<UstaadState>().openProfile(),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<UstaadState>().signOut(),
          ),
        ],
        const _ThemeButton(),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.handyman, size: 58, color: ustaadSecondary),
        const SizedBox(height: 12),
        Text(
          'USTAAD',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Smart home services',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handyman, size: 46, color: ustaadSecondary),
              Spacer(),
              _ThemeButton(),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'USTAAD',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Book trusted services from one natural-language request.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          const _FeatureRow(
            icon: Icons.translate,
            title: 'English, Urdu, Roman Urdu',
            subtitle: 'Understands real customer wording',
          ),
          const _FeatureRow(
            icon: Icons.auto_awesome,
            title: 'Smart provider ranking',
            subtitle: 'Trust, distance, price, response',
          ),
          const _FeatureRow(
            icon: Icons.cloud_done,
            title: 'Supabase connected',
            subtitle: 'Auth, bookings, profile, reviews',
          ),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.translate, '3 languages'),
      (Icons.verified, 'Trust score'),
      (Icons.schedule, 'Live status'),
      (Icons.rate_review, 'Reviews'),
      (
        online ? Icons.cloud_done : Icons.cloud_off,
        online ? 'Supabase live' : 'Demo data'
      ),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Chip(
          avatar: Icon(item.$1, size: 16),
          label: Text(item.$2),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UstaadState>();
    return IconButton(
      tooltip: 'Switch theme',
      onPressed: () => context.read<UstaadState>().toggleTheme(),
      icon: Icon(state.isDark ? Icons.dark_mode : Icons.wb_sunny_outlined),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Password',
        suffixIcon: IconButton(
          tooltip: obscure ? 'Show password' : 'Hide password',
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    );
  }
}

class _QuotePanel extends StatelessWidget {
  const _QuotePanel({required this.quote});

  final QuoteEstimate quote;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Expanded(child: _QuoteText(label: 'Base', value: quote.basePrice)),
          Expanded(
            child: _QuoteText(label: 'Distance', value: quote.distancePrice),
          ),
          Expanded(
            child: _QuoteText(
              label: 'Total',
              value: quote.total,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteText extends StatelessWidget {
  const _QuoteText({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final int value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Text(
          'Rs. $value',
          style: TextStyle(
            color: highlight ? Theme.of(context).colorScheme.primary : null,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.bolt, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _IntentSummary extends StatelessWidget {
  const _IntentSummary({required this.intent});

  final ServiceIntent intent;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Service', intent.role),
      ('Time', intent.timeLabel),
      ('Language', intent.language),
      ('Confidence', '${(intent.confidence * 100).round()}%'),
    ];

    return _Panel(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          return Chip(
            label: Text('${item.$1}: ${item.$2}'),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }
}

class _TracePanel extends StatelessWidget {
  const _TracePanel({
    required this.events,
    this.initiallyExpanded = true,
  });

  final List<WorkflowEvent> events;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return _Panel(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: initiallyExpanded,
        title: const Text(
          'Workflow trace',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text('Understand -> find -> rank -> book'),
        children: events.map((event) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text('${event.step}: ${event.agentName}'),
            subtitle: Text('${event.message}\nTool: ${event.toolName}'),
            isThreeLine: true,
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

class _ProviderCard extends StatefulWidget {
  const _ProviderCard({
    required this.provider,
    required this.best,
  });

  final UstaadProviderProfile provider;
  final bool best;

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UstaadState>().loadReviews(widget.provider.id);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.id != widget.provider.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<UstaadState>().loadReviews(widget.provider.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final score = (provider.score.clamp(0, 100)).toDouble() / 100;
    final reviews =
        context.watch<UstaadState>().providerReviews[provider.id] ?? const [];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.best) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Best match'),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              _Avatar(url: provider.avatarUrl, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text('${provider.role} - ${provider.distanceKm} km'),
                    Text('${provider.rating} rating - Rs. ${provider.price}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(provider.nextSlot),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(
            provider.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricChip(
                icon: Icons.timer,
                label: '${provider.responseTimeMinutes} min',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: provider.verified ? Icons.verified : Icons.info,
                label: provider.verified ? 'Verified' : 'New',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ContactBar(phone: provider.phone, whatsapp: provider.whatsapp),
          const SizedBox(height: 10),
          _ReviewsPreview(providerId: provider.id, reviews: reviews),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.read<UstaadState>().bookProvider(provider),
            icon: const Icon(Icons.calendar_month),
            label: const Text('Book slot'),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final BookingRecord booking;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(url: booking.providerAvatarUrl, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text('${booking.serviceRole} - Rs. ${booking.quoteTotal}'),
                  ],
                ),
              ),
              _StatusChip(label: booking.statusLabel, status: booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.problemText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          _StatusTile(
            icon: Icons.calendar_month,
            title: booking.slotLabel,
            subtitle: booking.location,
          ),
          const SizedBox(height: 10),
          _ContactBar(
            phone: booking.providerPhone,
            whatsapp: booking.providerWhatsapp,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: booking.status == 'completed'
                    ? null
                    : () => context
                        .read<UstaadState>()
                        .updateBookingStatus(booking, 'completed'),
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete'),
              ),
              OutlinedButton.icon(
                onPressed: booking.status == 'cancelled'
                    ? null
                    : () => context
                        .read<UstaadState>()
                        .updateBookingStatus(booking, 'cancelled'),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => _showReviewDialog(
                  context,
                  providerId: booking.providerId,
                  providerName: booking.providerName,
                  bookingId: booking.id,
                ),
                icon: const Icon(Icons.star),
                label: const Text('Review'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewsPreview extends StatelessWidget {
  const _ReviewsPreview({
    required this.providerId,
    required this.reviews,
  });

  final String providerId;
  final List<ReviewRecord> reviews;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(
        reviews.isEmpty ? 'Reviews' : 'Reviews (${reviews.length})',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: reviews.isEmpty
          ? const Text('No reviews yet')
          : Text(_stars(_averageRating(reviews))),
      children: [
        if (reviews.isEmpty)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.rate_review),
            title: Text('Be the first to review'),
          )
        else
          ...reviews.take(3).map((review) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _Avatar(url: review.customerAvatarUrl, size: 36),
              title: Text(
                  '${_stars(review.rating.toDouble())}  ${review.customerName}'),
              subtitle: Text(review.comment),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _showReviewDialog(
              context,
              providerId: providerId,
              providerName: 'provider',
            ),
            icon: const Icon(Icons.add_comment),
            label: const Text('Add review'),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  const _ContactBar({
    required this.phone,
    required this.whatsapp,
  });

  final String phone;
  final String whatsapp;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ContactChip(
          icon: Icons.phone,
          label: phone.isEmpty ? 'Phone pending' : phone,
          value: phone,
        ),
        _ContactChip(
          icon: Icons.chat,
          label: whatsapp.isEmpty ? 'WhatsApp pending' : whatsapp,
          value: whatsapp,
        ),
      ],
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: value.isEmpty
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact copied.')),
                );
              }
            },
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      'completed' => Colors.green,
      'cancelled' => Colors.redAccent,
      'en_route' => scheme.primary,
      _ => scheme.secondary,
    };
    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _AvatarFallback(size: size);
    }
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _AvatarFallback(size: size);
        },
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person),
    );
  }
}

Future<void> _showReviewDialog(
  BuildContext context, {
  required String providerId,
  required String providerName,
  String? bookingId,
}) async {
  final comment = TextEditingController();
  var rating = 5;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final busy = context.watch<UstaadState>().reviewBusy;
          return AlertDialog(
            title: Text('Review $providerName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return ChoiceChip(
                      selected: rating == value,
                      label: Text('$value'),
                      avatar: const Icon(Icons.star, size: 16),
                      onSelected: (_) => setState(() => rating = value),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Review',
                    hintText: 'Share your experience',
                  ),
                ),
                if (busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final ok =
                            await context.read<UstaadState>().submitReview(
                                  providerId: providerId,
                                  rating: rating,
                                  comment: comment.text,
                                  bookingId: bookingId,
                                );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, ok);
                        }
                      },
                child: const Text('Post'),
              ),
            ],
          );
        },
      );
    },
  );
  comment.dispose();
  if (context.mounted && result == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review posted.')),
    );
  }
}

String _stars(double rating) {
  final rounded = rating.round().clamp(1, 5);
  return '${'★' * rounded}${'☆' * (5 - rounded)}';
}

double _averageRating(List<ReviewRecord> reviews) {
  if (reviews.isEmpty) return 0;
  final total = reviews.fold<int>(0, (sum, review) => sum + review.rating);
  return total / reviews.length;
}

String _contentTypeFor(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
