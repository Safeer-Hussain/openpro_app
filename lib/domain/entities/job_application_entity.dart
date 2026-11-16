import 'package:flutter/material.dart';

enum ApplicationStage {
  applied,
  underReview,
  technicalScreening,
  offerReceived,
  archived;

  String get label {
    switch (this) {
      case ApplicationStage.applied:
        return 'Applied';
      case ApplicationStage.underReview:
        return 'Under Review';
      case ApplicationStage.technicalScreening:
        return 'Technical Screening';
      case ApplicationStage.offerReceived:
        return 'Offer Received';
      case ApplicationStage.archived:
        return 'Archived';
    }
  }

  IconData get icon {
    switch (this) {
      case ApplicationStage.applied:
        return Icons.send_rounded;
      case ApplicationStage.underReview:
        return Icons.visibility_rounded;
      case ApplicationStage.technicalScreening:
        return Icons.terminal_rounded;
      case ApplicationStage.offerReceived:
        return Icons.verified_rounded;
      case ApplicationStage.archived:
        return Icons.archive_outlined;
    }
  }

  ApplicationStage? get nextStage {
    switch (this) {
      case ApplicationStage.applied:
        return ApplicationStage.underReview;
      case ApplicationStage.underReview:
        return ApplicationStage.technicalScreening;
      case ApplicationStage.technicalScreening:
        return ApplicationStage.offerReceived;
      case ApplicationStage.offerReceived:
        return ApplicationStage.archived;
      case ApplicationStage.archived:
        return null;
    }
  }

  ApplicationStage? get previousStage {
    switch (this) {
      case ApplicationStage.applied:
        return null;
      case ApplicationStage.underReview:
        return ApplicationStage.applied;
      case ApplicationStage.technicalScreening:
        return ApplicationStage.underReview;
      case ApplicationStage.offerReceived:
        return ApplicationStage.technicalScreening;
      case ApplicationStage.archived:
        return ApplicationStage.offerReceived;
    }
  }

  static ApplicationStage fromString(String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'applied') return ApplicationStage.applied;
    if (normalized == 'underreview' ||
        normalized == 'under_review' ||
        normalized == 'review') {
      return ApplicationStage.underReview;
    }
    if (normalized == 'technicalscreening' ||
        normalized == 'technical_screening' ||
        normalized == 'screening' ||
        normalized == 'interviewscheduled') {
      return ApplicationStage.technicalScreening;
    }
    if (normalized == 'offerreceived' ||
        normalized == 'offer_received' ||
        normalized == 'offer') {
      return ApplicationStage.offerReceived;
    }
    if (normalized == 'archived' ||
        normalized == 'rejected' ||
        normalized == 'closed') {
      return ApplicationStage.archived;
    }
    return ApplicationStage.applied;
  }
}

class JobApplicationEntity {
  final String id;
  final String jobId;
  final String userId;
  final String jobTitle;
  final String company;
  final String companyLogo;
  final String salaryRange;
  final String location;
  final ApplicationStage stage;
  final String? coverNote;
  final List<String> scheduledSlots;
  final DateTime appliedAt;
  final DateTime updatedAt;

  const JobApplicationEntity({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.jobTitle,
    required this.company,
    required this.companyLogo,
    required this.salaryRange,
    required this.location,
    required this.stage,
    this.coverNote,
    this.scheduledSlots = const [],
    required this.appliedAt,
    required this.updatedAt,
  });

  int get elapsedDays {
    final now = DateTime.now();
    final diff = now.difference(appliedAt).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get elapsedLabel {
    final days = elapsedDays;
    if (days == 0) return 'Applied today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  bool get canAdvance => stage.nextStage != null;
  bool get canRegress => stage.previousStage != null;

  JobApplicationEntity copyWith({
    String? id,
    String? jobId,
    String? userId,
    String? jobTitle,
    String? company,
    String? companyLogo,
    String? salaryRange,
    String? location,
    ApplicationStage? stage,
    String? coverNote,
    List<String>? scheduledSlots,
    DateTime? appliedAt,
    DateTime? updatedAt,
  }) {
    return JobApplicationEntity(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      companyLogo: companyLogo ?? this.companyLogo,
      salaryRange: salaryRange ?? this.salaryRange,
      location: location ?? this.location,
      stage: stage ?? this.stage,
      coverNote: coverNote ?? this.coverNote,
      scheduledSlots: scheduledSlots ?? this.scheduledSlots,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'user_id': userId,
      'job_title': jobTitle,
      'company': company,
      'company_logo': companyLogo,
      'salary_range': salaryRange,
      'location': location,
      'status': stage.name,
      'cover_note': coverNote,
      'scheduled_slots': scheduledSlots.join(';'),
      'applied_at': appliedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory JobApplicationEntity.fromMap(Map<String, dynamic> map) {
    final appliedAtStr =
        map['applied_at'] as String? ?? DateTime.now().toIso8601String();
    final updatedAtStr = map['updated_at'] as String? ?? appliedAtStr;
    final slotsRaw = map['scheduled_slots'] as String? ?? '';
    final slotsList = slotsRaw.isEmpty ? <String>[] : slotsRaw.split(';');

    return JobApplicationEntity(
      id: map['id'] as String? ?? '',
      jobId: map['job_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      jobTitle: map['job_title'] as String? ?? 'Engineering Role',
      company: map['company'] as String? ?? 'Enterprise Client',
      companyLogo:
          map['company_logo'] as String? ?? 'assets/images/cloudscale.png',
      salaryRange: map['salary_range'] as String? ?? '\$180,000 - \$230,000',
      location: map['location'] as String? ?? 'Remote',
      stage: ApplicationStage.fromString(map['status'] as String? ?? 'applied'),
      coverNote: map['cover_note'] as String?,
      scheduledSlots: slotsList,
      appliedAt: DateTime.tryParse(appliedAtStr) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAtStr) ?? DateTime.now(),
    );
  }
}
