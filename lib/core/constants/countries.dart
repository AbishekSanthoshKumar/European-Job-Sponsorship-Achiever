/// European countries relevant to the search, with their flag emoji.
/// Ordered so the primary markets appear first in every picker.
class Countries {
  const Countries._();

  static const primary = ['Germany', 'Netherlands'];

  static const all = <String>[
    'Germany',
    'Netherlands',
    'Ireland',
    'Poland',
    'Sweden',
    'Belgium',
    'Austria',
    'Switzerland',
    'Denmark',
    'Spain',
    'Portugal',
    'Estonia',
    'Finland',
    'Norway',
    'Czech Republic',
    'Luxembourg',
    'Lithuania',
    'Latvia',
    'Italy',
    'France',
    'Romania',
    'Bulgaria',
    'Slovakia',
    'Hungary',
    'Greece',
    'Croatia',
    'Slovenia',
    'Malta',
    'Cyprus',
    'Iceland',
    'United Kingdom',
  ];

  static const _flags = <String, String>{
    'Germany': '🇩🇪',
    'Netherlands': '🇳🇱',
    'Ireland': '🇮🇪',
    'Poland': '🇵🇱',
    'Sweden': '🇸🇪',
    'Belgium': '🇧🇪',
    'Austria': '🇦🇹',
    'Switzerland': '🇨🇭',
    'Denmark': '🇩🇰',
    'Spain': '🇪🇸',
    'Portugal': '🇵🇹',
    'Estonia': '🇪🇪',
    'Finland': '🇫🇮',
    'Norway': '🇳🇴',
    'Czech Republic': '🇨🇿',
    'Luxembourg': '🇱🇺',
    'Lithuania': '🇱🇹',
    'Latvia': '🇱🇻',
    'Italy': '🇮🇹',
    'France': '🇫🇷',
    'Romania': '🇷🇴',
    'Bulgaria': '🇧🇬',
    'Slovakia': '🇸🇰',
    'Hungary': '🇭🇺',
    'Greece': '🇬🇷',
    'Croatia': '🇭🇷',
    'Slovenia': '🇸🇮',
    'Malta': '🇲🇹',
    'Cyprus': '🇨🇾',
    'Iceland': '🇮🇸',
    'United Kingdom': '🇬🇧',
    'Europe (Multiple)': '🇪🇺',
    'Multiple': '🌍',
  };

  static String flag(String country) => _flags[country] ?? '🌍';

  static String withFlag(String country) =>
      country.isEmpty ? '' : '${flag(country)}  $country';

  /// Short immigration note surfaced on the country screen.
  static const visaNotes = <String, String>{
    'Germany': 'EU Blue Card for graduates with a qualifying salary. '
        'Opportunity Card (Chancenkarte) allows job-seeking in-country.',
    'Netherlands': 'Employer must be an IND-recognised sponsor. '
        'Highly Skilled Migrant permit; 30% tax ruling for expats.',
    'Ireland': 'Critical Skills Employment Permit covers most software roles; '
        'no labour-market test.',
    'Poland': 'Work permit type A plus a national D visa. '
        'EU Blue Card also available.',
    'Sweden': 'Work permit requires an advertised role and union review; '
        'a straightforward process overall.',
    'Belgium': 'Single Permit combining work and residence; regionally '
        'administered.',
    'Austria': 'Red-White-Red Card, points-based for Very Highly Qualified '
        'Workers and Skilled Workers in shortage occupations.',
    'Switzerland': 'Non-EU permits are quota-limited and employers must show '
        'no suitable EU candidate was available.',
    'Denmark': 'Pay Limit Scheme and Fast-Track Scheme for certified '
        'employers; Positive List covers IT roles.',
    'Spain': 'Highly Qualified Professional permit; the Startup Law added a '
        'digital-nomad route.',
    'Portugal': 'Tech Visa for certified companies; D3 highly qualified '
        'activity visa.',
    'Estonia': 'Startup visa and a simplified short-term employment '
        'registration; strong digital-government tooling.',
    'Finland': 'Specialist residence permit with a fast two-week track.',
    'Norway': 'Skilled worker permit; requires a completed degree and a '
        'matching role.',
    'Czech Republic': 'Employee Card; the Highly Qualified Employee Programme '
        'accelerates IT hires.',
    'Luxembourg': 'EU Blue Card; large finance and IT sector for the '
        'population size.',
    'United Kingdom': 'Skilled Worker visa requires an employer holding a '
        'sponsor licence. Check the register before applying.',
  };
}

/// Role categories used across applications and analytics.
class Roles {
  const Roles._();

  static const all = <String>[
    'Backend Engineer',
    'Full Stack Engineer',
    'Applied AI Engineer',
    'Data Engineer',
    'Software Engineer',
    'Automation Engineer',
    'Mobile Engineer',
    'Computer Vision / OCR',
    'ML Engineer',
    'DevOps Engineer',
    'Platform Engineer',
    'QA Engineer',
    'Frontend Engineer',
    'Other',
  ];
}
