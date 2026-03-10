import 'dart:convert';

class User {
  final int id;
  final String fullName;
  final String? email;
  final String phone;
  final String state;
  final String lga;
  final String gender;
  final int age;
  final String? geopoliticalZone;
  final bool isAdmin;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.fullName,
    this.email,
    required this.phone,
    required this.state,
    required this.lga,
    required this.gender,
    required this.age,
    this.geopoliticalZone,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        fullName: json['full_name'],
        email: json['email'],
        phone: json['phone'],
        state: json['state'],
        lga: json['lga'],
        gender: json['gender'],
        age: json['age'],
        geopoliticalZone: json['geopolitical_zone'],
        isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      );
}

class Party {
  final int id;
  final String name;
  final String abbreviation;
  final String colorHex;
  final String? logoUrl;
  final String? manifesto;

  const Party({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.colorHex,
    this.logoUrl,
    this.manifesto,
  });

  factory Party.fromJson(Map<String, dynamic> json) => Party(
        id: json['id'],
        name: json['name'],
        abbreviation: json['abbreviation'],
        colorHex: json['color_hex'],
        logoUrl: json['logo_url'],
        manifesto: json['manifesto'],
      );
}

class Candidate {
  final int id;
  final String fullName;
  final String? photoUrl;
  final int partyId;
  final String partyName;
  final String partyAbbr;
  final String partyColorHex;
  final String? partyLogo;
  final String electionType;
  final String? stateName;
  final String? runningMateName;
  final String? runningMatePhotoUrl;
  final String? bio;
  final int? age;
  final bool isIncumbent;

  const Candidate({
    required this.id,
    required this.fullName,
    this.photoUrl,
    required this.partyId,
    required this.partyName,
    required this.partyAbbr,
    required this.partyColorHex,
    this.partyLogo,
    required this.electionType,
    this.stateName,
    this.runningMateName,
    this.runningMatePhotoUrl,
    this.bio,
    this.age,
    this.isIncumbent = false,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
        id: json['id'],
        fullName: json['full_name'],
        photoUrl: json['photo_url'],
        partyId: json['party_id'],
        partyName: json['party_name'] ?? '',
        partyAbbr: json['party_abbr'] ?? json['abbreviation'] ?? '',
        partyColorHex: json['party_color'] ?? json['color_hex'] ?? '#008751',
        partyLogo: json['party_logo'],
        electionType: json['election_type'],
        stateName: json['state_name'],
        runningMateName: json['running_mate_name'],
        runningMatePhotoUrl: json['running_mate_photo_url'],
        bio: json['bio'],
        age: json['age'],
        isIncumbent: json['is_incumbent'] == 1 || json['is_incumbent'] == true,
      );
}

class CandidateResult extends Candidate {
  final int voteCount;
  final double percentage;

  const CandidateResult({
    required super.id,
    required super.fullName,
    super.photoUrl,
    required super.partyId,
    required super.partyName,
    required super.partyAbbr,
    required super.partyColorHex,
    super.partyLogo,
    required super.electionType,
    super.stateName,
    super.runningMateName,
    super.isIncumbent,
    required this.voteCount,
    required this.percentage,
  });

  factory CandidateResult.fromJson(Map<String, dynamic> json) {
    final base = Candidate.fromJson(json);
    return CandidateResult(
      id: base.id,
      fullName: base.fullName,
      photoUrl: base.photoUrl,
      partyId: base.partyId,
      partyName: base.partyName,
      partyAbbr: base.partyAbbr,
      partyColorHex: base.partyColorHex,
      partyLogo: base.partyLogo,
      electionType: base.electionType,
      stateName: base.stateName,
      runningMateName: base.runningMateName,
      isIncumbent: base.isIncumbent,
      voteCount: json['vote_count'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class VoteReceipt {
  final int voteId;
  final String electionType;
  final String candidateName;
  final String? candidatePhoto;
  final String partyName;
  final String partyAbbr;
  final String partyColorHex;
  final DateTime castAt;

  const VoteReceipt({
    required this.voteId,
    required this.electionType,
    required this.candidateName,
    this.candidatePhoto,
    required this.partyName,
    required this.partyAbbr,
    required this.partyColorHex,
    required this.castAt,
  });

  factory VoteReceipt.fromJson(Map<String, dynamic> json) => VoteReceipt(
        voteId: json['vote_id'],
        electionType: json['election_type'] ?? '',
        candidateName: json['candidate_name'],
        candidatePhoto: json['candidate_photo'],
        partyName: json['party_name'],
        partyAbbr: json['party_abbr'] ?? '',
        partyColorHex: json['color_hex'],
        castAt: DateTime.parse(json['cast_at']),
      );
}

class ThresholdResult {
  final int candidateId;
  final String fullName;
  final String partyAbbr;
  final String colorHex;
  final int qualifyingStatesCount;
  final List<String> qualifyingStates;
  final bool meetsThreshold;

  const ThresholdResult({
    required this.candidateId,
    required this.fullName,
    required this.partyAbbr,
    required this.colorHex,
    required this.qualifyingStatesCount,
    required this.qualifyingStates,
    required this.meetsThreshold,
  });

  factory ThresholdResult.fromJson(Map<String, dynamic> json) => ThresholdResult(
        candidateId: json['id'] ?? json['candidate_id'],
        fullName: json['full_name'],
        partyAbbr: json['party_abbr'],
        colorHex: json['color_hex'],
        qualifyingStatesCount: json['qualifying_states_count'] ?? 0,
        qualifyingStates: List<String>.from(json['qualifying_states'] ?? []),
        meetsThreshold: json['meets_threshold'] == true,
      );
}

class ElectionConfig {
  final String electionType;
  final bool isOpen;
  final DateTime? openDate;
  final DateTime? closeDate;
  final String? label;

  const ElectionConfig({
    required this.electionType,
    required this.isOpen,
    this.openDate,
    this.closeDate,
    this.label,
  });

  factory ElectionConfig.fromJson(Map<String, dynamic> json) => ElectionConfig(
        electionType: json['election_type'],
        isOpen: json['is_open'] == 1 || json['is_open'] == true,
        openDate: json['open_date'] != null ? DateTime.tryParse(json['open_date']) : null,
        closeDate: json['close_date'] != null ? DateTime.tryParse(json['close_date']) : null,
        label: json['label'],
      );
}
