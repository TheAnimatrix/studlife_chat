

import 'package:get_it/get_it.dart';
import 'package:studlife_chat/questionBank/services/teacherAuth.dart';

final getIt = GetIt.instance;
void setup() {
  getIt.registerSingleton<TeacherAuth>(TeacherAuth());
}
