import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../currency.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../ustaad_state.dart';
import 'common_widgets.dart';

class ProviderCard extends StatefulWidget {
  const ProviderCard({
    super.key,
    required this.provider,
    required this.best,
  });

  final UstaadProviderProfile provider;
  final bool best;

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
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
  void didUpdateWidget(covariant ProviderCard oldWidget) {
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
    final state = context.watch<UstaadState>();
    final saved = state.isSavedProvider(provider.id);
    final score = (provider.score.clamp(0, 100)).toDouble() / 100;
    final reviews = state.providerReviews[provider.id] ?? const [];
    final activeOffer = state.activeOffer;
    final priceDiff = provider.price - activeOffer;
    final isBelowOrEqual = priceDiff <= 0;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.best)
                Chip(
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    AppLocalizations.of(context)?.bestMatch ?? 'Best match',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isBelowOrEqual
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isBelowOrEqual
                        ? const Color(0xFF10B981).withValues(alpha: 0.35)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBelowOrEqual ? Icons.check_circle : Icons.swap_horiz,
                      size: 14,
                      color: isBelowOrEqual
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isBelowOrEqual
                          ? (priceDiff < 0
                              ? 'Offer matched (-${formatPkr(-priceDiff)})'
                              : 'Exact offer match')
                          : 'Counter: +${formatPkr(priceDiff)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isBelowOrEqual
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF065F46))
                            : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Stack(
                children: [
                  Avatar(url: provider.avatarUrl, size: 56),
                  if (provider.verified)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 11,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${provider.role} • ${provider.distanceKm} km',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${provider.rating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatPkr(provider.price),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: saved ? 'Unsave provider' : 'Save provider',
                onPressed: () => context
                    .read<UstaadState>()
                    .toggleSavedProvider(provider.id),
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StatusTile(
            icon: Icons.event_available,
            title: provider.nextSlot,
            subtitle: '${provider.responseTimeMinutes} min response',
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              MetricChip(
                icon: Icons.timer,
                label: '${provider.jobsCompleted} jobs',
              ),
              const SizedBox(width: 8),
              MetricChip(
                icon: provider.verified ? Icons.verified : Icons.info,
                label: provider.verified ? 'Verified' : 'New',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ContactBar(phone: provider.phone, whatsapp: provider.whatsapp),
          const SizedBox(height: 10),
          ReviewsPreview(providerId: provider.id, reviews: reviews),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: state.bookingBusy
                ? null
                : () => context.read<UstaadState>().bookProvider(provider),
            icon: state.bookingBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.handshake),
            label: Text(
              state.bookingBusy
                  ? 'Confirming booking...'
                  : (isBelowOrEqual
                      ? 'Accept Offer (${formatPkr(provider.price)})'
                      : 'Accept Counter (${formatPkr(provider.price)})'),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewsPreview extends StatelessWidget {
  const ReviewsPreview({
    super.key,
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
          : Text(stars(averageRating(reviews))),
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
              leading: Avatar(url: review.customerAvatarUrl, size: 36),
              title: Text(
                  '${stars(review.rating.toDouble())}  ${review.customerName}'),
              subtitle: Text(review.comment),
            );
          }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showReviewDialog(
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
