/// Domain Entity representing a step in the multi-agent AI execution trace.
class WorkflowEvent {
  const WorkflowEvent({
    required this.agentName,
    required this.step,
    required this.message,
    required this.toolName,
    required this.status,
  });

  final String agentName;
  final String step;
  final String message;
  final String toolName;
  final String status;
}
