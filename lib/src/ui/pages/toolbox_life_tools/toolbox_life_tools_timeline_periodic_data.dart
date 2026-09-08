part of '../toolbox_life_tools.dart';

class _TimelineFact {
  const _TimelineFact({
    required this.id,
    this.collection = 'general',
    required this.category,
    required this.yearsBeforePresent,
    required this.displayKey,
    required this.titleKey,
    required this.detailKey,
    required this.sourceNameKey,
    required this.sourceUrl,
    this.imageAsset,
  });

  final String id;
  final String collection;
  final String category;
  final double yearsBeforePresent;
  final String displayKey;
  final String titleKey;
  final String detailKey;
  final String sourceNameKey;
  final String sourceUrl;
  final String? imageAsset;
}

class _ElementFact {
  const _ElementFact({
    required this.atomicNumber,
    required this.symbol,
    required this.nameKey,
    required this.nameEn,
    required this.atomicMass,
    required this.groupBlock,
    required this.groupBlockKey,
    required this.standardState,
    required this.yearDiscovered,
    required this.electronConfiguration,
    required this.electronegativity,
    required this.atomicRadius,
    required this.ionizationEnergy,
    required this.electronAffinity,
    required this.oxidationStates,
    required this.meltingPoint,
    required this.boilingPoint,
    required this.density,
    required this.period,
    required this.group,
    required this.displayRow,
    required this.displayColumn,
  });

  final int atomicNumber;
  final String symbol;
  final String nameKey;
  final String nameEn;
  final String atomicMass;
  final String groupBlock;
  final String groupBlockKey;
  final String standardState;
  final String yearDiscovered;
  final String electronConfiguration;
  final String electronegativity;
  final String atomicRadius;
  final String ionizationEnergy;
  final String electronAffinity;
  final String oxidationStates;
  final String meltingPoint;
  final String boilingPoint;
  final String density;
  final int period;
  final int group;
  final int displayRow;
  final int displayColumn;
}

const List<_LifeToolSource> _timelinePeriodicSources = <_LifeToolSource>[
  _LifeToolSource(
    name: 'Wikidata',
    url: 'https://www.wikidata.org/wiki/Wikidata:Licensing',
  ),
  _LifeToolSource(
    name: 'PubChem PUG REST periodic table',
    url: 'https://pubchem.ncbi.nlm.nih.gov/rest/pug/periodictable/JSON',
  ),
  _LifeToolSource(
    name: 'IUPAC Periodic Table of Elements',
    url: 'https://iupac.org/what-we-do/periodic-table-of-elements/',
  ),
  _LifeToolSource(
    name: 'CIAAW standard atomic weights',
    url: 'https://ciaaw.org/atomic-weights.htm',
  ),
  _LifeToolSource(
    name: 'International Chronostratigraphic Chart',
    url: 'https://stratigraphy.org/chart',
  ),
  _LifeToolSource(name: 'NASA Science', url: 'https://science.nasa.gov/'),
  _LifeToolSource(
    name: 'Smithsonian Human Origins Program',
    url: 'https://humanorigins.si.edu/',
  ),
  _LifeToolSource(
    name: 'Encyclopaedia Britannica',
    url: 'https://www.britannica.com/',
  ),
  _LifeToolSource(
    name: 'The Met Open Access',
    url: 'https://www.metmuseum.org/hubs/open-access',
  ),
];
