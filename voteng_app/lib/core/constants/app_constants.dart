// Nigeria states with geopolitical zones
const List<Map<String, String>> kNigeriaStates = [
  {'name': 'Abia', 'abbreviation': 'AB', 'zone': 'South-East'},
  {'name': 'Adamawa', 'abbreviation': 'AD', 'zone': 'North-East'},
  {'name': 'Akwa Ibom', 'abbreviation': 'AK', 'zone': 'South-South'},
  {'name': 'Anambra', 'abbreviation': 'AN', 'zone': 'South-East'},
  {'name': 'Bauchi', 'abbreviation': 'BA', 'zone': 'North-East'},
  {'name': 'Bayelsa', 'abbreviation': 'BY', 'zone': 'South-South'},
  {'name': 'Benue', 'abbreviation': 'BE', 'zone': 'North-Central'},
  {'name': 'Borno', 'abbreviation': 'BO', 'zone': 'North-East'},
  {'name': 'Cross River', 'abbreviation': 'CR', 'zone': 'South-South'},
  {'name': 'Delta', 'abbreviation': 'DE', 'zone': 'South-South'},
  {'name': 'Ebonyi', 'abbreviation': 'EB', 'zone': 'South-East'},
  {'name': 'Edo', 'abbreviation': 'ED', 'zone': 'South-South'},
  {'name': 'Ekiti', 'abbreviation': 'EK', 'zone': 'South-West'},
  {'name': 'Enugu', 'abbreviation': 'EN', 'zone': 'South-East'},
  {'name': 'Gombe', 'abbreviation': 'GO', 'zone': 'North-East'},
  {'name': 'Imo', 'abbreviation': 'IM', 'zone': 'South-East'},
  {'name': 'Jigawa', 'abbreviation': 'JI', 'zone': 'North-West'},
  {'name': 'Kaduna', 'abbreviation': 'KD', 'zone': 'North-West'},
  {'name': 'Kano', 'abbreviation': 'KN', 'zone': 'North-West'},
  {'name': 'Katsina', 'abbreviation': 'KT', 'zone': 'North-West'},
  {'name': 'Kebbi', 'abbreviation': 'KB', 'zone': 'North-West'},
  {'name': 'Kogi', 'abbreviation': 'KO', 'zone': 'North-Central'},
  {'name': 'Kwara', 'abbreviation': 'KW', 'zone': 'North-Central'},
  {'name': 'Lagos', 'abbreviation': 'LA', 'zone': 'South-West'},
  {'name': 'Nasarawa', 'abbreviation': 'NA', 'zone': 'North-Central'},
  {'name': 'Niger', 'abbreviation': 'NI', 'zone': 'North-Central'},
  {'name': 'Ogun', 'abbreviation': 'OG', 'zone': 'South-West'},
  {'name': 'Ondo', 'abbreviation': 'ON', 'zone': 'South-West'},
  {'name': 'Osun', 'abbreviation': 'OS', 'zone': 'South-West'},
  {'name': 'Oyo', 'abbreviation': 'OY', 'zone': 'South-West'},
  {'name': 'Plateau', 'abbreviation': 'PL', 'zone': 'North-Central'},
  {'name': 'Rivers', 'abbreviation': 'RI', 'zone': 'South-South'},
  {'name': 'Sokoto', 'abbreviation': 'SO', 'zone': 'North-West'},
  {'name': 'Taraba', 'abbreviation': 'TA', 'zone': 'North-East'},
  {'name': 'Yobe', 'abbreviation': 'YO', 'zone': 'North-East'},
  {'name': 'Zamfara', 'abbreviation': 'ZA', 'zone': 'North-West'},
  {'name': 'FCT Abuja', 'abbreviation': 'FC', 'zone': 'North-Central'},
];

const List<String> kGeopoliticalZones = [
  'North-West',
  'North-East',
  'North-Central',
  'South-West',
  'South-East',
  'South-South',
];

const List<String> kElectionTypes = [
  'presidential',
  'senate',
  'house',
  'governorship',
  'state_assembly',
];

const Map<String, String> kElectionTypeLabels = {
  'presidential': 'Presidential',
  'senate': 'Senate',
  'house': 'House of Reps',
  'governorship': 'Governorship',
  'state_assembly': 'State Assembly',
};

const Map<String, String> kElectionTypeIcons = {
  'presidential': '🏛️',
  'senate': '🏢',
  'house': '🏠',
  'governorship': '🗺️',
  'state_assembly': '🏛',
};

// Presidential election threshold rules
const int kThresholdStateCount = 24; // Must win 25% in at least 24 states + FCT
const double kThresholdPercentage = 25.0;

// API base URL — change for production
const String kApiBaseUrl = 'http://localhost:3000';
const String kWsUrl = 'ws://localhost:3000';
