class TomatoDiseaseInformation {
  final String name;
  final String possibleCause;
  final List<String> recommendedActions;
  final List<String> prevention;
  final List<String> references;
  final bool isHealthy;

  const TomatoDiseaseInformation({
    required this.name,
    required this.possibleCause,
    required this.recommendedActions,
    required this.prevention,
    required this.references,
    this.isHealthy = false,
  });

  static const byModelLabel = <String, TomatoDiseaseInformation>{
    'Tomato___Bacterial_spot': TomatoDiseaseInformation(
      name: 'Bacterial Spot',
      possibleCause:
          'A bacterial disease that spreads readily in wet conditions. Look for small, water-soaked leaf spots that may develop yellow halos; leaves and fruit can also be affected.',
      recommendedActions: [
        'Remove badly affected leaves and clear diseased plant debris.',
        'Avoid handling plants while foliage is wet, and water at the soil level.',
        'Ask local agricultural extension staff for advice if symptoms continue.',
      ],
      prevention: [
        'Use healthy seed or transplants and allow good spacing for airflow.',
        'Avoid overhead watering and rotate tomatoes with unrelated crops.',
      ],
      references: [
        'https://hgic.clemson.edu/factsheet/tomato-diseases-disorders/',
      ],
    ),
    'Tomato___Early_blight': TomatoDiseaseInformation(
      name: 'Early Blight',
      possibleCause:
          'A fungal disease often beginning on older leaves. Brown spots may develop concentric, target-like rings with yellowing around them.',
      recommendedActions: [
        'Remove affected lower leaves and discard them away from the garden.',
        'Mulch beneath plants and water at the soil level to limit soil splash.',
        'Seek local extension advice if symptoms spread or worsen.',
      ],
      prevention: [
        'Use tolerant varieties where available and rotate tomato-family crops.',
        'Space plants for airflow and remove volunteer tomatoes and weeds.',
      ],
      references: [
        'https://hgic.clemson.edu/factsheet/tomato-diseases-disorders/',
      ],
    ),
    'Tomato___Late_blight': TomatoDiseaseInformation(
      name: 'Late Blight',
      possibleCause:
          'A fast-spreading disease favored by cool, wet weather. Leaves may develop enlarging dark, water-soaked areas, sometimes with pale growth at lesion edges.',
      recommendedActions: [
        'Have suspicious, rapidly spreading symptoms checked promptly by local extension staff.',
        'Remove and discard severely affected plants; do not compost them.',
        'Keep foliage dry and avoid working among wet plants.',
      ],
      prevention: [
        'Provide space and airflow, and water at the soil level.',
        'Use healthy transplants and remove volunteer tomato and potato plants.',
      ],
      references: [
        'https://hgic.clemson.edu/factsheet/tomato-diseases-disorders/',
      ],
    ),
    'Tomato___Leaf_Mold': TomatoDiseaseInformation(
      name: 'Leaf Mold',
      possibleCause:
          'A fungal disease favored by humid, poorly ventilated conditions. Older leaves may show pale or yellow patches above and grayish, velvety growth below.',
      recommendedActions: [
        'Remove affected leaves and clear crop debris.',
        'Increase airflow around plants and avoid wetting leaves when watering.',
        'Ask local extension staff to check uncertain or continuing symptoms.',
      ],
      prevention: [
        'Space or stake plants to improve airflow and reduce leaf wetness.',
        'Rotate crops and remove tomato residue after harvest.',
      ],
      references: [
        'https://hgic.clemson.edu/factsheet/tomato-diseases-disorders/',
      ],
    ),
    'Tomato___Septoria_leaf_spot': TomatoDiseaseInformation(
      name: 'Septoria Leaf Spot',
      possibleCause:
          'A fungal leaf disease commonly starting on lower leaves. Small round spots can have dark margins, pale centers, and tiny dark specks.',
      recommendedActions: [
        'Remove spotted lower leaves and discard crop debris.',
        'Mulch to reduce soil splash and water at the base of plants.',
        'Consult local extension staff if defoliation progresses.',
      ],
      prevention: [
        'Rotate tomatoes with unrelated crops and avoid overhead irrigation.',
        'Keep plants spaced for airflow and clean up residue after harvest.',
      ],
      references: [
        'https://hgic.clemson.edu/factsheet/tomato-diseases-disorders/',
      ],
    ),
    'Tomato___Spider_mites Two-spotted_spider_mite': TomatoDiseaseInformation(
      name: 'Two-Spotted Spider Mites',
      possibleCause:
          'Tiny mites feed mainly on leaf undersides. Fine pale stippling or a grayish appearance may develop; a hand lens can help reveal mites.',
      recommendedActions: [
        'Inspect leaf undersides closely, including neighboring plants.',
        'Remove heavily affected leaves and seek local extension advice if mites persist.',
      ],
      prevention: [
        'Inspect transplants before bringing them into the garden.',
        'Keep plants evenly watered and growing vigorously.',
      ],
      references: ['https://hgic.clemson.edu/factsheet/tomato-insect-pests/'],
    ),
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus': TomatoDiseaseInformation(
      name: 'Tomato Yellow Leaf Curl Virus',
      possibleCause:
          'A virus spread by whiteflies. Infected plants may have upward-curled, yellowing leaves, stunted growth, and reduced flowering; these signs can have other causes.',
      recommendedActions: [
        'Ask local agricultural extension staff to confirm suspected virus symptoms.',
        'Remove and discard plants confirmed to be infected; there is no cure for an infected plant.',
        'Monitor nearby plants for whiteflies and follow local extension guidance.',
      ],
      prevention: [
        'Use healthy transplants and resistant varieties where available.',
        'Rotate with non-host crops and monitor for whiteflies.',
      ],
      references: [
        'https://content.ces.ncsu.edu/tomato-yellow-leaf-curl-virus',
      ],
    ),
    'Tomato___healthy': TomatoDiseaseInformation(
      name: 'Healthy',
      possibleCause:
          'The model’s top category did not identify a disease. This does not guarantee that the plant is disease-free.',
      recommendedActions: [],
      prevention: [],
      references: [],
      isHealthy: true,
    ),
  };

  static TomatoDiseaseInformation? forModelLabel(String label) =>
      byModelLabel[label];

  static TomatoDiseaseInformation? forName(String name) {
    for (final information in byModelLabel.values) {
      if (information.name == name) return information;
    }
    return null;
  }
}
