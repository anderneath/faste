import 'app/template_creator.dart';

class Faste {
  static final Faste instance = Faste._();

  Faste();

  factory Faste._() {
    return Faste();
  }

  final template = TemplateCreator();
}
