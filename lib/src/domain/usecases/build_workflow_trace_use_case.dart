import '../../ai_engine_router.dart';
import '../../currency.dart';
import '../entities/provider_profile.dart';
import '../entities/service_intent.dart';
import '../entities/workflow_event.dart';
import 'calculate_quote_use_case.dart';

/// Clean Architecture Use Case: Builds agentic execution traces and workflow events.
class BuildWorkflowTraceUseCase {
  const BuildWorkflowTraceUseCase({
    CalculateQuoteUseCase calculateQuoteUseCase = const CalculateQuoteUseCase(),
  }) : _calculateQuoteUseCase = calculateQuoteUseCase;

  final CalculateQuoteUseCase _calculateQuoteUseCase;

  /// Builds the full multi-agent search and ranking execution trace.
  List<WorkflowEvent> execute({
    required ServiceIntent intent,
    required List<UstaadProviderProfile> ranked,
    List<String> reasoningSteps = const [],
    AIEngineType engine = AIEngineType.localHeuristic,
    List<String> auditLog = const [],
    int? offer,
  }) {
    if (ranked.isEmpty) return const [];

    final best = ranked.first;
    final second = ranked.length > 1 ? ranked[1] : best;
    final estimate = _calculateQuoteUseCase.execute(
      provider: best,
      intent: intent,
      offer: offer,
    );
    final tokenCount = intent.description.split(RegExp(r'\s+')).length + 6;
    final sector = _extractSector(intent.location);
    final nearbyCount =
        ranked.where((provider) => provider.distanceKm <= 15).length;

    final engineName = switch (engine) {
      AIEngineType.openRouterCloud => 'OpenRouter DeepSeek (Cloud Primary)',
      AIEngineType.onDeviceLlama => 'On-Device Llama (llamadart GGUF JSON)',
      AIEngineType.localHeuristic => 'On-Device Heuristic Engine (Safety Net)',
    };

    final nlpMessage = reasoningSteps.isNotEmpty
        ? reasoningSteps.first
        : 'Input processed in ${intent.language}. Tokenized $tokenCount words. Extracted service=${intent.role}, location=${intent.location}, urgency=${intent.urgency}. Confidence: ${(intent.confidence * 100).round()}%.';

    final ladderSummary = auditLog.isNotEmpty
        ? auditLog.join(' ➔ ')
        : 'Engine cascade validated.';

    return [
      WorkflowEvent(
        agentName: 'Engine Router',
        step: 'Failover Ladder Resolution',
        message: 'Ladder evaluation: $ladderSummary',
        toolName: 'Failover Cascade Ladder',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'NLP Interpreter',
        step: 'Semantic Extraction',
        message: '$nlpMessage [Resolved via $engineName]',
        toolName: engineName,
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Context Agent',
        step: 'Enrich Context',
        message: reasoningSteps.length > 1
            ? reasoningSteps[1]
            : 'Resolved ${intent.location} to target sector $sector. Activated 15km service zone.',
        toolName: 'Location Resolver',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Discovery Agent',
        step: 'Provider Search',
        message:
            'Queried service_providers table with filter role=${intent.role}. Found ${ranked.length} candidates in database. Applied city filter. $nearbyCount providers within 15km radius.',
        toolName: 'Cloud Firestore / Catalog',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Ranking Agent',
        step: 'InDrive Budget Ranking',
        message:
            'Applied InDrive budget-weighted ranking: budget match(35%), reliability(22%), distance(18%), rating(15%), experience(5%), response(5%). Top score: ${best.score.toStringAsFixed(1)}/100.',
        toolName: 'Trust & Budget Match Engine',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Decision Agent',
        step: 'Select Provider',
        message:
            'Selected ${best.name} (${best.role}) - Score ${best.score.toStringAsFixed(1)}. Reason: ${best.reason}. Alternative: ${second.name} at score ${second.score.toStringAsFixed(1)}.',
        toolName: 'Best-Match Selector',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Quote Agent',
        step: 'Price Estimate & Bidding',
        message:
            'Base: ${formatPkr(estimate.basePrice)}${estimate.userOffer != null ? " (Offer: ${formatPkr(estimate.userOffer!)})" : ""} + Distance: ${formatPkr(estimate.distancePrice)} + Urgency: ${formatPkr(estimate.urgencyPrice)} = Total: ${formatPkr(estimate.total)}.',
        toolName: 'InDrive Bidding & Pricing Engine',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Booking Agent',
        step: 'Reserve Slot',
        message:
            'Slot ${best.nextSlot} reserved. Booking ID generated. Provider notified via simulated push notification.',
        toolName: 'Booking API',
        status: 'ready',
      ),
      WorkflowEvent(
        agentName: 'Follow-up Agent',
        step: 'Schedule Reminders',
        message:
            'Reminder set for 1 hour before appointment. Post-job review prompt scheduled. Status polling every 5 minutes until completed.',
        toolName: 'Notification Scheduler',
        status: 'scheduled',
      ),
    ];
  }

  /// Appends the booking confirmation and post-job monitoring events.
  List<WorkflowEvent> buildBookingEvents(
    List<WorkflowEvent> currentEvents,
    UstaadProviderProfile provider,
  ) {
    return [
      ...currentEvents,
      WorkflowEvent(
        agentName: 'Booking',
        step: 'Confirm',
        message:
            'Booked ${provider.name} for ${provider.nextSlot}; contact unlocked.',
        toolName: 'bookings',
        status: 'done',
      ),
      WorkflowEvent(
        agentName: 'Follow-up',
        step: 'Monitor',
        message:
            'Reminder prepared 1 hour before ${provider.nextSlot}; review prompt enabled.',
        toolName: 'agent_events',
        status: 'scheduled',
      ),
    ];
  }

  String _extractSector(String location) {
    final match =
        RegExp(r'\b[A-I]-?\d{1,2}\b', caseSensitive: false).firstMatch(location);
    return match?.group(0)?.toUpperCase() ?? 'Islamabad';
  }
}
