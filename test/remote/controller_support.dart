import 'package:encuentra_u/features/objects/data/models/object_report_model.dart';
import 'package:encuentra_u/features/objects/domain/entities/object_report.dart';
import 'package:encuentra_u/features/objects/domain/entities/report_page.dart';
import 'package:encuentra_u/features/objects/domain/repositories/object_repository.dart';
import 'package:encuentra_u/features/objects/domain/usecases/register_object.dart';
import 'package:encuentra_u/features/objects/domain/usecases/get_my_reports.dart';
import 'package:encuentra_u/features/objects/domain/usecases/get_my_report.dart';
import 'package:encuentra_u/features/objects/domain/usecases/update_object_report.dart';
import 'package:encuentra_u/features/objects/domain/usecases/cancel_object_report.dart';
import 'package:encuentra_u/features/objects/presentation/controllers/object_controller.dart';
import 'package:encuentra_u/features/matching/data/models/object_match_model.dart';
import 'package:encuentra_u/features/matching/domain/entities/object_match.dart';
import 'package:encuentra_u/features/matching/domain/entities/match_page.dart';
import 'package:encuentra_u/features/matching/domain/repositories/match_repository.dart';
import 'package:encuentra_u/features/matching/domain/usecases/generate_report_matches.dart';
import 'package:encuentra_u/features/matching/domain/usecases/get_my_matches.dart';
import 'package:encuentra_u/features/matching/domain/usecases/get_my_match.dart';
import 'package:encuentra_u/features/matching/presentation/controllers/match_controller.dart';
import 'support.dart';

class ReportRepositoryStub implements ObjectRepository {
  Future<ReportPage> Function(int, int)? onList;
  Future<ObjectReport> Function(String)? onGet;
  int creates = 0, updates = 0, cancels = 0;
  bool cancelled = false;
  @override
  Future<ReportPage> getMyReports(
          {required int limit,
          required int offset,
          ReportType? reportType,
          ReportStatus? status}) async =>
      onList != null
          ? await onList!(limit, offset)
          : ReportPage(items: [
              ObjectReportModel.fromJson(
                  reportJson(status: cancelled ? 'cancelled' : 'active'))
            ], total: 1, limit: limit, offset: offset);
  @override
  Future<ObjectReport> createReport(ObjectReportDraft draft) async {
    creates++;
    return ObjectReportModel.fromJson(reportJson());
  }

  @override
  Future<ObjectReport> getMyReport(String id) async => onGet != null
      ? await onGet!(id)
      : ObjectReportModel.fromJson(
          reportJson(id: id, status: cancelled ? 'cancelled' : 'active'));
  @override
  Future<ObjectReport> updateReport(
      String id, ObjectReportUpdate update) async {
    updates++;
    return ObjectReportModel.fromJson({
      ...reportJson(id: id),
      'description': update.description ?? 'Original'
    });
  }

  @override
  Future<void> cancelReport(String id) async {
    cancels++;
    cancelled = true;
  }
}

ObjectController objectController(ReportRepositoryStub repo) =>
    ObjectController(
        getMyReports: GetMyReports(repo),
        getMyReport: GetMyReport(repo),
        registerObject: RegisterObject(repo),
        updateReport: UpdateObjectReport(repo),
        cancelReport: CancelObjectReport(repo));

class MatchRepositoryStub implements MatchRepository {
  Future<MatchPage> Function(int, int)? onList;
  Future<GeneratedMatches> Function(String)? onGenerate;
  @override
  Future<MatchPage> getMyMatches(
          {required int limit,
          required int offset,
          MatchLevel? level,
          MatchStatus? status}) async =>
      onList != null
          ? await onList!(limit, offset)
          : MatchPage(
              items: [ObjectMatchModel.fromJson(matchJson())],
              total: 1,
              limit: limit,
              offset: offset);
  @override
  Future<ObjectMatch> getMyMatch(String id) async =>
      ObjectMatchModel.fromJson(matchJson());
  @override
  Future<GeneratedMatches> generateReportMatches(String reportId) async =>
      onGenerate != null
          ? await onGenerate!(reportId)
          : GeneratedMatches(
              reportId: reportId,
              items: [ObjectMatchModel.fromJson(matchJson())]);
}

MatchController matchController(MatchRepositoryStub repo) => MatchController(
    generateReportMatches: GenerateReportMatches(repo),
    getMyMatches: GetMyMatches(repo),
    getMyMatch: GetMyMatch(repo));
