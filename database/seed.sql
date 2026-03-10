-- VoteNG 2027 — Seed Data
USE voteng2027;

-- ─────────────────────────────────────────────
-- PARTIES
-- ─────────────────────────────────────────────
INSERT INTO parties (name, abbreviation, color_hex, manifesto) VALUES
('All Progressives Congress', 'APC', '#008751', 'APC is committed to security, economy, and social infrastructure. Our Next Level agenda focuses on agriculture, power, transportation, and digital economy.'),
('Peoples Democratic Party', 'PDP', '#C8102E', 'The PDP advocates for restructuring Nigeria, strengthening institutions, fighting corruption, and stimulating inclusive economic growth.'),
('Labour Party', 'LP', '#FF6B00', 'The Labour Party champions workers'' rights, social justice, a new minimum wage framework, and grassroots-driven governance.'),
('Africa Democratic Congress', 'ADC', '#003893', 'ADC is committed to building a united Nigeria through federalism, security reform, and economic diversification.'),
('New Nigeria Peoples Party', 'NNPP', '#6A0DAD', 'NNPP stands for a new Nigeria where the people lead, driven by innovation, youth empowerment, and anti-corruption.'),
('All Progressives Grand Alliance', 'APGA', '#007A5E', 'APGA promotes Igbo cultural identity, south-east development, and a peaceful, restructured Nigerian federation.');

-- ─────────────────────────────────────────────
-- STATES (36 + FCT)
-- ─────────────────────────────────────────────
INSERT INTO states (name, abbreviation, geopolitical_zone, capital) VALUES
('Abia', 'AB', 'South-East', 'Umuahia'),
('Adamawa', 'AD', 'North-East', 'Yola'),
('Akwa Ibom', 'AK', 'South-South', 'Uyo'),
('Anambra', 'AN', 'South-East', 'Awka'),
('Bauchi', 'BA', 'North-East', 'Bauchi'),
('Bayelsa', 'BY', 'South-South', 'Yenagoa'),
('Benue', 'BE', 'North-Central', 'Makurdi'),
('Borno', 'BO', 'North-East', 'Maiduguri'),
('Cross River', 'CR', 'South-South', 'Calabar'),
('Delta', 'DE', 'South-South', 'Asaba'),
('Ebonyi', 'EB', 'South-East', 'Abakaliki'),
('Edo', 'ED', 'South-South', 'Benin City'),
('Ekiti', 'EK', 'South-West', 'Ado Ekiti'),
('Enugu', 'EN', 'South-East', 'Enugu'),
('Gombe', 'GO', 'North-East', 'Gombe'),
('Imo', 'IM', 'South-East', 'Owerri'),
('Jigawa', 'JI', 'North-West', 'Dutse'),
('Kaduna', 'KD', 'North-West', 'Kaduna'),
('Kano', 'KN', 'North-West', 'Kano'),
('Katsina', 'KT', 'North-West', 'Katsina'),
('Kebbi', 'KB', 'North-West', 'Birnin Kebbi'),
('Kogi', 'KO', 'North-Central', 'Lokoja'),
('Kwara', 'KW', 'North-Central', 'Ilorin'),
('Lagos', 'LA', 'South-West', 'Ikeja'),
('Nasarawa', 'NA', 'North-Central', 'Lafia'),
('Niger', 'NI', 'North-Central', 'Minna'),
('Ogun', 'OG', 'South-West', 'Abeokuta'),
('Ondo', 'ON', 'South-West', 'Akure'),
('Osun', 'OS', 'South-West', 'Osogbo'),
('Oyo', 'OY', 'South-West', 'Ibadan'),
('Plateau', 'PL', 'North-Central', 'Jos'),
('Rivers', 'RI', 'South-South', 'Port Harcourt'),
('Sokoto', 'SO', 'North-West', 'Sokoto'),
('Taraba', 'TA', 'North-East', 'Jalingo'),
('Yobe', 'YO', 'North-East', 'Damaturu'),
('Zamfara', 'ZA', 'North-West', 'Gusau'),
('FCT Abuja', 'FC', 'North-Central', 'Abuja');

-- ─────────────────────────────────────────────
-- ELECTION CONFIG (all closed by default)
-- ─────────────────────────────────────────────
INSERT INTO election_config (election_type, is_open, open_date, close_date, label) VALUES
('presidential',   0, '2027-02-20 08:00:00', '2027-02-20 18:00:00', 'Presidential Election 2027'),
('senate',         0, '2027-02-20 08:00:00', '2027-02-20 18:00:00', 'Senate Election 2027'),
('house',          0, '2027-02-20 08:00:00', '2027-02-20 18:00:00', 'House of Representatives 2027'),
('governorship',   0, '2027-03-06 08:00:00', '2027-03-06 18:00:00', 'Governorship Election 2027'),
('state_assembly', 0, '2027-03-06 08:00:00', '2027-03-06 18:00:00', 'State Assembly Election 2027');

-- ─────────────────────────────────────────────
-- PRESIDENTIAL CANDIDATES
-- ─────────────────────────────────────────────
INSERT INTO candidates (full_name, party_id, election_type, running_mate_name, bio, age, is_incumbent) VALUES
('Bola Ahmed Tinubu', 
  (SELECT id FROM parties WHERE abbreviation='APC'), 
  'presidential', 
  'Kashim Shettima',
  'Bola Ahmed Tinubu is the incumbent President of Nigeria, first elected in 2023. Former Governor of Lagos State (1999–2007). He ran on the APC platform and seeks a second term in 2027.',
  72, 1),
('Atiku Abubakar', 
  (SELECT id FROM parties WHERE abbreviation='ADC'), 
  'presidential', 
  'TBD',
  'Atiku Abubakar is a seasoned Nigerian politician and businessman who served as Vice President of Nigeria (1999–2007). He has run for president multiple times and is seeking the 2027 presidency on the ADC platform.',
  80, 0),
('Peter Obi', 
  (SELECT id FROM parties WHERE abbreviation='LP'), 
  'presidential', 
  'TBD',
  'Peter Obi is a former Governor of Anambra State (2006–2014) and 2023 Labour Party presidential candidate who rode a massive wave of youth support known as the ''Obidient'' movement.',
  63, 0),
('Rabiu Musa Kwankwaso', 
  (SELECT id FROM parties WHERE abbreviation='NNPP'), 
  'presidential', 
  'TBD',
  'Rabiu Kwankwaso is a former Governor of Kano State and former Minister of Defence. He runs on the NNPP platform appealing to north-west voters.',
  68, 0);

-- ─────────────────────────────────────────────
-- ADMIN USER (for platform management)
-- password: Admin@2027 (bcrypt hash)
-- ─────────────────────────────────────────────
INSERT INTO users (full_name, email, phone, state, lga, gender, age, geopolitical_zone, password_hash, is_verified, is_admin)
VALUES ('VoteNG Admin', 'admin@voteng.ng', '+2340000000000', 'FCT Abuja', 'AMAC', 'male', 35, 'North-Central',
'$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 1, 1);
-- NOTE: Update this hash via `node -e "const b=require('bcryptjs');b.hash('Admin@2027',10).then(console.log)"`
