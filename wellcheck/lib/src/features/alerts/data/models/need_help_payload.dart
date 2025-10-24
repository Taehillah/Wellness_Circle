import 'help_location.dart';

class NeedHelpPayload {
  const NeedHelpPayload({
    this.message,
    this.location,
    this.targets,
  });

  final String? message;
  final HelpLocation? location;
  final List<String>? targets;

  Map<String, dynamic> toJson() => {
        if (message != null && message!.isNotEmpty) 'message': message,
        if (location != null) 'location': location!.toJson(),
        if (targets != null) 'targets': targets,
      };
}
