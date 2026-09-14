import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import 'repository.dart';

const _uuid = Uuid();

/// Summary of what the seeding pass imported.
class SeedResult {
  const SeedResult({
    required this.companies,
    required this.agencies,
    required this.portals,
    required this.skippedExisting,
  });

  final int companies;
  final int agencies;
  final int portals;
  final int skippedExisting;

  int get total => companies + agencies + portals;
}

/// Loads the curated target database — every company, agency, job board and
/// government portal extracted from the user's own source files — and
/// upserts it into the repository on first launch.
///
/// Seeding is idempotent: records are matched on a normalised
/// (name, country) key, so re-running never creates duplicates and never
/// overwrites edits the user has made to a seeded record.
class SeedLoader {
  const SeedLoader(this.repository);

  final DataRepository repository;

  static const assetPath = 'assets/data/seed_targets.json';

  Future<SeedResult> seed({bool force = false}) async {
    final raw = await rootBundle.loadString(assetPath);
    final data = jsonDecode(raw) as Map<String, Object?>;
    final records = (data['records'] as List).cast<Map<String, Object?>>();

    final existingCompanies = await repository.getCompanies();
    final existingAgencies = await repository.getAgencies();

    final companyKeys = {
      for (final c in existingCompanies) _key(c.name, c.country),
    };
    final agencyKeys = {
      for (final a in existingAgencies) _key(a.name, a.country),
    };

    final now = DateTime.now();
    final newCompanies = <Company>[];
    final newAgencies = <RecruitmentAgency>[];
    var companies = 0, agencies = 0, portals = 0, skipped = 0;

    for (final r in records) {
      final kind = r['kind']?.toString() ?? 'company';
      final name = r['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final country = r['country']?.toString() ?? '';
      final key = _key(name, country);

      if (kind == 'company') {
        if (!force && companyKeys.contains(key)) {
          skipped++;
          continue;
        }
        companyKeys.add(key);
        newCompanies.add(_toCompany(r, now));
        companies++;
      } else {
        if (!force && agencyKeys.contains(key)) {
          skipped++;
          continue;
        }
        agencyKeys.add(key);
        newAgencies.add(_toAgency(r, kind, now));
        if (kind == 'portal') {
          portals++;
        } else {
          agencies++;
        }
      }
    }

    if (newCompanies.isNotEmpty) {
      await repository.upsertCompanies(newCompanies);
    }
    if (newAgencies.isNotEmpty) {
      await repository.upsertAgencies(newAgencies);
    }

    return SeedResult(
      companies: companies,
      agencies: agencies,
      portals: portals,
      skippedExisting: skipped,
    );
  }

  static String _key(String name, String country) =>
      '${_normalise(name)}|${country.trim().toLowerCase()}';

  static String _normalise(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\(.*?\)'), ' ')
      .replaceAll(
        RegExp(
          r'\b(gmbh & co\. kg|gmbh|ag|se|kg|nv|bv|inc|ltd|limited|llc|plc|'
          r'group|holding|holdings|deutschland|netherlands|nederland)\b',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');

  Company _toCompany(Map<String, Object?> r, DateTime now) {
    final tags = (r['tags'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final industry = r['industry']?.toString() ?? '';
    final country = r['country']?.toString() ?? '';

    return Company(
      id: 'seed_c_${r['id'] ?? _uuid.v4()}',
      name: r['name']!.toString(),
      website: r['website']?.toString() ?? '',
      linkedinUrl: r['linkedinUrl']?.toString() ?? '',
      careerUrl: r['careerUrl']?.toString() ?? '',
      country: country,
      city: r['city']?.toString() ?? '',
      industry: industry,
      type: _companyType(industry, tags),
      knownSponsor: tags.contains('offer-received-here')
          ? TriState.yes
          : TriState.unknown,
      sponsorshipLikelihood: _sponsorLikelihood(country, tags),
      priority: _companyPriority(r, tags),
      notes: r['notes']?.toString() ?? '',
      tags: tags,
      isSeeded: true,
      sourceRefs:
          (r['sources'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  RecruitmentAgency _toAgency(
      Map<String, Object?> r, String kind, DateTime now) {
    final tags = (r['tags'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final spec = r['specialization']?.toString() ?? '';

    return RecruitmentAgency(
      id: 'seed_a_${r['id'] ?? _uuid.v4()}',
      name: r['name']!.toString(),
      website: r['website']?.toString().isNotEmpty == true
          ? r['website']!.toString()
          : (r['careerUrl']?.toString() ?? ''),
      linkedinUrl: r['linkedinUrl']?.toString() ?? '',
      country: r['country']?.toString() ?? '',
      countriesServed: [
        if ((r['country']?.toString() ?? '').isNotEmpty) r['country']!.toString(),
      ],
      specialization: _specialization(spec, tags),
      priority: _agencyPriority(r, tags),
      matchScore: _agencyMatchScore(r, tags),
      notes: r['notes']?.toString() ?? '',
      tags: tags,
      isSeeded: true,
      sourceRefs:
          (r['sources'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // -- classification helpers ----------------------------------------------

  static CompanyType _companyType(String industry, List<String> tags) {
    final i = industry.toLowerCase();
    if (i.contains('financial') ||
        i.contains('banking') ||
        i.contains('fintech') ||
        i.contains('payment') ||
        i.contains('insurance')) {
      return CompanyType.fintech;
    }
    if (i.contains('artificial intelligence') || i.contains(' ai ')) {
      return CompanyType.aiCompany;
    }
    if (i.contains('consult') || i.contains('audit')) {
      return CompanyType.consultancy;
    }
    if (i.contains('it services') || i.contains('outsourc')) {
      return CompanyType.outsourcing;
    }
    if (i.contains('software') ||
        i.contains('technology') ||
        i.contains('internet') ||
        i.contains('computer games')) {
      return CompanyType.productCompany;
    }
    if (i.contains('manufactur') ||
        i.contains('pharmaceutical') ||
        i.contains('retail') ||
        i.contains('energy') ||
        i.contains('logistics')) {
      return CompanyType.enterprise;
    }
    return CompanyType.other;
  }

  /// Countries with well-established sponsorship routes score higher by
  /// default; the user refines this per company as they research.
  static int _sponsorLikelihood(String country, List<String> tags) {
    if (tags.contains('offer-received-here')) return 10;
    return switch (country) {
      'Netherlands' => 8, // IND public sponsor register
      'Germany' => 7, // EU Blue Card
      'Ireland' => 7, // Critical Skills permit
      'Sweden' || 'Denmark' || 'Finland' || 'Norway' => 6,
      'Austria' || 'Belgium' || 'Luxembourg' => 6,
      'Poland' || 'Portugal' || 'Spain' || 'Estonia' => 5,
      'Switzerland' => 4, // non-EU quotas
      'United Kingdom' => 4, // needs a licensed sponsor
      _ => 5,
    };
  }

  static CompanyPriority _companyPriority(
      Map<String, Object?> r, List<String> tags) {
    final p = (r['priority'] as num?)?.toInt() ?? 1;
    final country = r['country']?.toString() ?? '';
    final isPrimary = country == 'Germany' || country == 'Netherlands';

    if (tags.contains('offer-received-here')) return CompanyPriority.dream;
    // curated shortlists the user hand-picked
    if (p >= 3) {
      return isPrimary ? CompanyPriority.dream : CompanyPriority.high;
    }
    if (p == 2) return CompanyPriority.high;
    return isPrimary ? CompanyPriority.medium : CompanyPriority.low;
  }

  static AgencySpecialization _specialization(
      String spec, List<String> tags) {
    if (tags.contains('government') || spec.contains('Government')) {
      return AgencySpecialization.governmentPortal;
    }
    if (tags.contains('recruiter-database')) {
      return AgencySpecialization.recruiterDatabase;
    }
    if (tags.contains('job-board') || spec.contains('Job Board')) {
      return AgencySpecialization.jobBoard;
    }
    if (spec.contains('General Recruitment') ||
        spec.contains('Global Staffing')) {
      return AgencySpecialization.generalRecruitment;
    }
    if (tags.contains('visa-sponsor-source')) {
      return AgencySpecialization.jobBoard;
    }
    return AgencySpecialization.generalTechnology;
  }

  static AgencyPriority _agencyPriority(
      Map<String, Object?> r, List<String> tags) {
    if (tags.contains('offer-received-here')) return AgencyPriority.highest;
    if (tags.contains('government')) return AgencyPriority.high;
    if (tags.contains('recruiter-database')) return AgencyPriority.high;

    final country = r['country']?.toString() ?? '';
    final p = (r['priority'] as num?)?.toInt() ?? 1;
    if (country == 'Germany' || country == 'Netherlands') {
      return p >= 2 ? AgencyPriority.highest : AgencyPriority.high;
    }
    if (p >= 2) return AgencyPriority.high;
    return AgencyPriority.medium;
  }

  static int _agencyMatchScore(Map<String, Object?> r, List<String> tags) {
    var score = 5;
    final country = r['country']?.toString() ?? '';
    if (country == 'Germany' || country == 'Netherlands') score += 3;
    if (tags.contains('offer-received-here')) score += 2;
    if (tags.contains('government')) score += 1;
    if (tags.contains('visa-sponsor-source')) score += 1;
    return score.clamp(0, 10);
  }
}
