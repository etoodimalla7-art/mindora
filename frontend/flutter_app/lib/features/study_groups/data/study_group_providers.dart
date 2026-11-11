import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/study_group_models.dart';
import 'study_group_repository.dart';

final studyGroupRepositoryProvider = Provider<StudyGroupRepository>(
  (ref) => StudyGroupRepository(ref.watch(dioProvider)),
);

/// Filters for the groups list.
class GroupsFilter {
  const GroupsFilter({this.subject, this.examSystem, this.examLevel, this.search});
  final String? subject;
  final String? examSystem;
  final String? examLevel;
  final String? search;

  GroupsFilter copyWith({
    String? subject,
    String? examSystem,
    String? examLevel,
    String? search,
    bool clearSubject = false,
    bool clearExamSystem = false,
    bool clearExamLevel = false,
    bool clearSearch = false,
  }) =>
      GroupsFilter(
        subject: clearSubject ? null : (subject ?? this.subject),
        examSystem: clearExamSystem ? null : (examSystem ?? this.examSystem),
        examLevel: clearExamLevel ? null : (examLevel ?? this.examLevel),
        search: clearSearch ? null : (search ?? this.search),
      );
}

final groupsFilterProvider = StateProvider<GroupsFilter>((_) => const GroupsFilter());

final groupsListProvider = FutureProvider<List<StudyGroup>>((ref) async {
  final filter = ref.watch(groupsFilterProvider);
  return ref.watch(studyGroupRepositoryProvider).listGroups(
        subject: filter.subject,
        examSystem: filter.examSystem,
        examLevel: filter.examLevel,
        search: filter.search,
      );
});

final groupDetailProvider =
    FutureProvider.family<StudyGroup, String>((ref, id) async {
  return ref.watch(studyGroupRepositoryProvider).getGroup(id);
});

final groupMessagesProvider =
    FutureProvider.family<List<GroupMessage>, String>((ref, id) async {
  return ref.watch(studyGroupRepositoryProvider).listMessages(id);
});
