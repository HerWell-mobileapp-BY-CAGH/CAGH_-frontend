import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/learning/domain/models/learning_module.dart';
import 'package:cagh_frontend/features/learning/data/services/learning_api_service.dart';

class _CategoryVisualMeta {
  final IconData icon;
  final Color themeColor;
  final Color bgLight;
  final Color bgDark;
  final String userBadge;
  final String midwifeBadge;
  final List<String> defaultTakeaways;

  const _CategoryVisualMeta({
    required this.icon,
    required this.themeColor,
    required this.bgLight,
    required this.bgDark,
    required this.userBadge,
    required this.midwifeBadge,
    required this.defaultTakeaways,
  });
}

class LearningRepository {
  static List<LearningModuleItem>? _cachedModules;

  @visibleForTesting
  static void setCachedModulesForTesting(List<LearningModuleItem>? modules) {
    _cachedModules = modules;
  }

  /// Fetch dynamic categories, topics, and published articles from backend admin API
  static Future<List<LearningModuleItem>> fetchModules({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedModules != null && _cachedModules!.isNotEmpty) {
      return _cachedModules!;
    }

    try {
      final categories = await LearningApiService.fetchCategories();
      final articles = await LearningApiService.fetchArticles();

      if (categories.isNotEmpty) {
        final List<LearningModuleItem> dynamicModules = [];

        for (final cat in categories) {
          // Find all articles belonging to this category
          final catArticles = articles.where((a) {
            if (a.categoryName != null &&
                a.categoryName!.trim().toLowerCase() == cat.name.trim().toLowerCase()) {
              return true;
            }
            if (a.topicId != null &&
                cat.topics.any((t) => t.id == a.topicId)) {
              return true;
            }
            return false;
          }).toList();

          // Build topic contents from articles
          final topicContents = catArticles
              .map((a) => LearningTopicContent.fromArticle(a))
              .toList();

          // Extract topics covered
          final topicsCovered = cat.topics.isNotEmpty
              ? cat.topics.map((t) => t.name).toList()
              : (catArticles.isNotEmpty
                  ? catArticles.map((a) => a.topicName ?? a.title).toList()
                  : ['Overview']);

          // Extract key takeaways from articles or category
          final keyTakeaways = <String>[];
          for (final a in catArticles) {
            if (a.keyTakeawayTip != null && a.keyTakeawayTip!.trim().isNotEmpty) {
              keyTakeaways.add(a.keyTakeawayTip!.trim());
            } else if (a.summary.isNotEmpty && keyTakeaways.length < 3) {
              keyTakeaways.add(a.summary.trim());
            }
          }
          if (keyTakeaways.isEmpty && cat.subtitleSummary.isNotEmpty) {
            keyTakeaways.add(cat.subtitleSummary);
          }

          final style = _getCategoryStyle(cat.slug, cat.name);
          final totalMins = catArticles.fold<int>(0, (acc, a) => acc + a.readingTimeMinutes);

          dynamicModules.add(
            LearningModuleItem(
              id: cat.id,
              category: cat.name,
              icon: style.icon,
              themeColor: style.themeColor,
              bgLight: style.bgLight,
              bgDark: style.bgDark,
              readTime: '${totalMins > 0 ? totalMins : 6} min read',
              articlesCount: '${catArticles.length} ${catArticles.length == 1 ? "Guide" : "Guides"}',
              userBadge: style.userBadge,
              midwifeBadge: style.midwifeBadge,
              getTitle: (_) => cat.name,
              getDesc: (_) => cat.subtitleSummary.isNotEmpty ? cat.subtitleSummary : cat.description,
              keyTakeaways: keyTakeaways.isNotEmpty ? keyTakeaways : style.defaultTakeaways,
              topicsCovered: topicsCovered,
              topicContents: topicContents,
              articles: catArticles,
              topics: cat.topics,
            ),
          );
        }

        if (dynamicModules.isNotEmpty) {
          _cachedModules = dynamicModules;
          return dynamicModules;
        }
      }
    } catch (_) {}

    return getModules();
  }

  static _CategoryVisualMeta _getCategoryStyle(String slug, String name) {
    final lowerSlug = slug.toLowerCase();
    final lowerName = name.toLowerCase();

    if (lowerSlug.contains('adolescent') || lowerName.contains('adolescent')) {
      return const _CategoryVisualMeta(
        icon: Icons.spa_rounded,
        themeColor: Color(0xFF2E7D32),
        bgLight: Color(0xFFE8F5E9),
        bgDark: Color(0xFF1B431E),
        userBadge: 'Essential Health',
        midwifeBadge: 'Patient Education',
        defaultTakeaways: [
          'Understanding growth spurts, hormonal changes, and menstrual hygiene.',
          'Essential iron, micronutrient, and dietary guidelines for adolescent growth.',
          'Building positive body image, life skills, and mental well-being.',
        ],
      );
    } else if (lowerSlug.contains('prevention') || lowerName.contains('prevention')) {
      return const _CategoryVisualMeta(
        icon: Icons.shield_rounded,
        themeColor: Color(0xFFE65100),
        bgLight: Color(0xFFFFF3E0),
        bgDark: Color(0xFF4A2500),
        userBadge: 'Awareness & Safety',
        midwifeBadge: 'Clinical Guideline',
        defaultTakeaways: [
          'Comprehensive STI & HIV prevention strategies and barrier protection.',
          'HPV vaccination schedules and early cervical cancer screening awareness.',
          'Identifying healthy vs unhealthy relationships and boundary setting.',
        ],
      );
    } else if (lowerSlug.contains('psychosocial') || lowerName.contains('psychosocial') || lowerName.contains('mental')) {
      return const _CategoryVisualMeta(
        icon: Icons.favorite_rounded,
        themeColor: Color(0xFFC2185B),
        bgLight: Color(0xFFFCE4EC),
        bgDark: Color(0xFF4A1027),
        userBadge: 'Mental Wellness',
        midwifeBadge: 'Crisis Response',
        defaultTakeaways: [
          'Recognizing signs of anxiety, depression, and trauma in maternal care.',
          'Gender-Based Violence (GBV) survivor support, referral pathways, and safety planning.',
          'Accessing confidential emergency hotlines, counseling, and social support services.',
        ],
      );
    } else {
      return const _CategoryVisualMeta(
        icon: Icons.medical_services_rounded,
        themeColor: Color(0xFF00796B),
        bgLight: Color(0xFFE0F2F1),
        bgDark: Color(0xFF003630),
        userBadge: 'Maternal Care',
        midwifeBadge: 'Obstetric Standard',
        defaultTakeaways: [
          'Family planning options, birth control methods, and fertility awareness.',
          'Antenatal Care (ANC) schedule, danger signs during pregnancy, and nutrition.',
          'Essential newborn care, breastfeeding support, and postnatal checkups.',
        ],
      );
    }
  }

  /// Synchronous getter returning cached or fallback modules
  static List<LearningModuleItem> getModules() {
    if (_cachedModules != null && _cachedModules!.isNotEmpty) {
      return _cachedModules!;
    }
    return _getFallbackModules();
  }

  static List<LearningModuleItem> _getFallbackModules() {
    return [
      LearningModuleItem(
        id: 'adolescent_health',
        category: 'Nutrition & Growth',
        icon: Icons.spa_rounded,
        themeColor: const Color(0xFF2E7D32),
        bgLight: const Color(0xFFE8F5E9),
        bgDark: const Color(0xFF1B431E),
        readTime: '6 min read',
        articlesCount: '12 Guides',
        userBadge: 'Essential Health',
        midwifeBadge: 'Patient Education',
        getTitle: (l10n) => l10n.adolescentGirlsHealthAndNutrition,
        getDesc: (l10n) => l10n.adolescentGirlsHealthAndNutritionDesc,
        keyTakeaways: [
          'Understanding growth spurts, hormonal changes, and menstrual hygiene.',
          'Essential iron, micronutrient, and dietary guidelines for adolescent growth.',
          'Building positive body image, life skills, and mental well-being.',
        ],
        topicsCovered: [
          'Puberty & Hormonal Development',
          'Menstrual Hygiene Management (MHM)',
          'Iron & Anemia Prevention Nutrition',
          'Healthy Body Image & Physical Fitness',
        ],
        topicContents: [
          const LearningTopicContent(
            title: 'Puberty & Hormonal Development',
            readTime: '4 min read',
            summary:
                'Puberty marks the biological transition from childhood to adolescence driven by endocrine hormones (estrogen, progesterone, LH, FSH). Understanding bodily changes reduces anxiety and promotes confidence.',
            keyPoints: [
              'Growth spurts, development of breast tissue (thelarche), and pubic hair (pubarche) typically occur between ages 9 and 14.',
              'First menstruation (menarche) generally arrives 2–2.5 years after thelarche.',
              'Hormonal shifts often induce temporary mood variations, oily skin, and increased perspiration which are completely natural.',
            ],
            detailedBody:
                'During puberty, the brain\'s hypothalamus releases gonadotropin-releasing hormone (GnRH), prompting the pituitary gland to secrete LH and FSH. These hormones stimulate the ovaries to produce estrogen, initiating rapid physical and physiological developments.\n\nIt is common for cycle length to be irregular during the first two years post-menarche as the hypothalamic-pituitary-ovarian axis matures. Adolescents should be reassured that variability in timing and growth patterns is standard among peers.',
            clinicalTip:
                'Screen adolescents for secondary amenorrhea or severe dysmenorrhea. Differentiate normal post-menarcheal anovulatory cycles from conditions like PCOS or thyroid dysfunction.',
            patientAdvice:
                'Track your cycle using a calendar or notebook. Pay attention to how your body feels, and remember every person develops at their own unique pace.',
            actionChecklist: [
              'Record the start and end dates of each menstrual period.',
              'Maintain daily gentle personal hygiene with clean water and mild soap.',
              'Consult a midwife or doctor if cycles remain absent past age 15.',
            ],
          ),
          const LearningTopicContent(
            title: 'Menstrual Hygiene Management (MHM)',
            readTime: '5 min read',
            summary:
                'Safe menstrual hygiene management is critical for preventing reproductive tract infections and ensuring dignity, school participation, and comfort.',
            keyPoints: [
              'Change sanitary pads every 4 to 6 hours or sooner if saturated to prevent bacterial overgrowth.',
              'Wash the perineal area from front to back to avoid transferring bacteria from the anus to the vagina.',
              'Wear clean, breathable cotton underwear and avoid perfumed washes or douches that alter natural vaginal pH.',
            ],
            detailedBody:
                'Vaginal flora consists of protective Lactobacillus species that maintain an acidic pH (3.8–4.5). Using scented deodorants, harsh antiseptic soaps, or douching disrupts this microenvironment, increasing the risk of bacterial vaginosis (BV) and yeast infections.\n\nDisposal of used products should be sanitary: wrap disposable pads in paper and place in waste bins. If using reusable cloth pads, wash thoroughly with soap and clean water, and dry directly in sunlight for UV disinfection.',
            clinicalTip:
                'Educate young clients on recognizing abnormal discharge (foul odor, curd-like, greenish-yellow) vs. physiologic leukorrhea.',
            patientAdvice:
                'Keep an emergency hygiene pouch in your school bag with a spare pad, clean underwear, and hand sanitizer so you never feel unprepared.',
            actionChecklist: [
              'Change pads every 4–6 hours.',
              'Wash hands with soap before and after changing menstrual products.',
              'Use clean water only to wash external genital areas.',
            ],
          ),
          const LearningTopicContent(
            title: 'Iron & Anemia Prevention Nutrition',
            readTime: '4 min read',
            summary:
                'Adolescent girls face a heightened risk of Iron Deficiency Anemia (IDA) due to rapid skeletal growth and monthly menstrual blood loss. Nutrient-dense foods prevent chronic fatigue and cognitive decline.',
            keyPoints: [
              'Iron is vital for hemoglobin synthesis, oxygen transport, and cognitive focus in school.',
              'Consume iron-rich staples such as teff, lentils, chickpeas, dark leafy greens, and lean meats.',
              'Pair iron sources with Vitamin C (oranges, tomatoes, lemons) to significantly boost non-heme iron absorption.',
            ],
            detailedBody:
                'Non-heme iron found in plant foods is sensitive to dietary inhibitors such as phytates and polyphenols (tannins in strong tea and coffee). To maximize absorption, avoid drinking tea or coffee within one hour before or after meals.\n\nWeekly Iron and Folic Acid Supplementation (WIFAS) is recommended by public health guidelines for adolescent girls in areas where anemia prevalence exceeds 20%.',
            clinicalTip:
                'Routinely evaluate hemoglobin levels during adolescent checkups. Consider preventive iron-folate supplementation in school health initiatives.',
            patientAdvice:
                'Add freshly squeezed lemon juice to lentils or vegetables to supercharge iron absorption naturally without extra medication.',
            actionChecklist: [
              'Include traditional teff injera and legumes in daily meals.',
              'Wait at least 1 hour after eating before enjoying tea or coffee.',
              'Report symptoms of severe fatigue, dizziness, or pale inner eyelids to a health worker.',
            ],
          ),
          const LearningTopicContent(
            title: 'Healthy Body Image & Physical Fitness',
            readTime: '3 min read',
            summary:
                'Nurturing body positivity, mental resilience, and consistent physical movement helps adolescents thrive emotionally during developmental transitions.',
            keyPoints: [
              'Body changes during puberty are healthy and reflect natural growth rather than flaws.',
              'Regular physical activity strengthens bones, stabilizes mood, and relieves menstrual cramping.',
              'Critical consumption of social media prevents unrealistic body comparison and disordered eating.',
            ],
            detailedBody:
                'Adolescence is a vulnerable window for body dissatisfaction. Promoting health-centered habits—such as engaging in 45–60 minutes of enjoyable physical movement daily (walking, running, sports, dancing)—fosters self-worth based on strength and vitality rather than arbitrary aesthetic standards.\n\nAdequate hydration and 8–9 hours of sleep are fundamental pillars for neurocognitive development and hormonal balance.',
            clinicalTip:
                'Screen for early signs of body dysmorphic disorder, restrictive dieting, or rapid weight fluctuations during youth consultations.',
            patientAdvice:
                'Celebrate what your body can do—running, learning, creating—rather than just how it looks. Talk to a trusted friend or midwife if you feel overwhelmed.',
            actionChecklist: [
              'Engage in 30+ minutes of enjoyable physical activity most days.',
              'Drink 6–8 glasses of water daily.',
              'Practice positive self-talk and limit exposure to toxic social media trends.',
            ],
          ),
        ],
      ),
      LearningModuleItem(
        id: 'prevention_awareness',
        category: 'Prevention & Safety',
        icon: Icons.shield_rounded,
        themeColor: const Color(0xFFE65100),
        bgLight: const Color(0xFFFFF3E0),
        bgDark: const Color(0xFF4A2500),
        readTime: '8 min read',
        articlesCount: '10 Guides',
        userBadge: 'Awareness & Safety',
        midwifeBadge: 'Clinical Guideline',
        getTitle: (l10n) => l10n.preventionAndAwareness,
        getDesc: (l10n) => l10n.preventionAndAwarenessDesc,
        keyTakeaways: [
          'Comprehensive STI & HIV prevention strategies and barrier protection.',
          'HPV vaccination schedules and early cervical cancer screening awareness.',
          'Identifying healthy vs unhealthy relationships and boundary setting.',
        ],
        topicsCovered: [
          'STI & HIV Transmission & Prevention',
          'HPV Vaccination & Pap Smear Awareness',
          'Consensual & Healthy Relationships',
          'Community Health Advocacy & Stigma Reduction',
        ],
        topicContents: [
          const LearningTopicContent(
            title: 'STI & HIV Transmission & Prevention',
            readTime: '5 min read',
            summary:
                'Sexually Transmitted Infections (STIs) and HIV are preventable and treatable. Consistent barrier protection, regular confidential testing, and awareness of PEP and PrEP save lives.',
            keyPoints: [
              'Male and female condoms provide dual protection against both unintended pregnancy and STIs/HIV.',
              'Many STIs (such as Chlamydia and early HIV) are asymptomatic; regular testing is the only definitive confirmation.',
              'Post-Exposure Prophylaxis (PEP) must be initiated within 72 hours of potential HIV exposure.',
              'Pre-Exposure Prophylaxis (PrEP) is an effective daily preventive pill for individuals at high ongoing risk.',
            ],
            detailedBody:
                'STIs can be caused by bacteria (Gonorrhea, Chlamydia, Syphilis), viruses (HIV, HPV, Herpes), or parasites (Trichomoniasis). If left untreated, bacterial STIs can cause Pelvic Inflammatory Disease (PID), chronic pelvic pain, and future tubal infertility.\n\nHIV attacks CD4 helper T-cells of the immune system. Antiretroviral therapy (ART) keeps viral loads undetectable (Undetectable = Untransmittable, U=U). Testing is safe, rapid, and strictly confidential at all CAGH-partnered health facilities.',
            clinicalTip:
                'Provide non-judgmental, youth-friendly syndromic STI screening. Immediately counsel clients on partner notification and prompt initiation of PEP within 72 hours where indicated.',
            patientAdvice:
                'Getting tested for STIs is a responsible health choice, not something to feel ashamed of. You can speak to a midwife confidentially through this app anytime.',
            actionChecklist: [
              'Always use condoms correctly and consistently.',
              'Seek confidential STI screening if you notice sores, burning urination, or abnormal discharge.',
              'If potentially exposed to HIV, report to a health center within 72 hours for PEP.',
            ],
          ),
          const LearningTopicContent(
            title: 'HPV Vaccination & Pap Smear Awareness',
            readTime: '5 min read',
            summary:
                'Human Papillomavirus (HPV) is the primary cause of cervical cancer. Vaccination during early adolescence and regular cervical screening can prevent virtually all cases.',
            keyPoints: [
              'High-risk HPV types 16 and 18 cause approximately 70% of cervical cancer cases worldwide.',
              'The HPV vaccine is safest and most effective when administered between ages 9 and 14 before sexual debut.',
              'Visual Inspection with Acetic Acid (VIA) and Pap smears detect pre-cancerous lesions decades before cancer develops.',
            ],
            detailedBody:
                'Cervical cancer develops slowly over 10 to 20 years through persistent infection with oncogenic HPV types. Because early-stage cervical changes are completely painless and symptom-free, regular screening starting in early adulthood is essential.\n\nNational vaccination programs provide the quadrivalent or bivalent HPV vaccine in primary schools and health centers. Catch-up vaccinations are available for young women up to age 26.',
            clinicalTip:
                'Encourage every eligible adolescent patient and their caregivers to complete their HPV vaccination series. Educate adult women on routine 3-year cervical screening intervals.',
            patientAdvice:
                'Vaccination is like an invisible shield against cervical cancer. Talk to your school nurse or local midwife to check if you have received your HPV vaccine.',
            actionChecklist: [
              'Check your immunization record for the HPV vaccine.',
              'Encourage female peers and family members to get vaccinated and screened.',
              'Schedule a cervical checkup once you reach recommended screening age.',
            ],
          ),
          const LearningTopicContent(
            title: 'Consensual & Healthy Relationships',
            readTime: '4 min read',
            summary:
                'Healthy relationships are built upon mutual respect, open communication, equality, and uncoerced consent. Recognizing boundary violations protects mental and physical integrity.',
            keyPoints: [
              'Consent must be freely given, reversible, informed, enthusiastic, and specific (FRIES principle).',
              'Silence, hesitation, fear, or intoxication does NOT constitute consent.',
              'Red flags include jealousy, digital surveillance, isolating you from friends/family, and emotional pressure.',
            ],
            detailedBody:
                'Relationship violence often starts subtly through emotional control, monitoring phone messages, or demanding passwords. A partner who truly respects you will honor your personal boundaries, support your educational goals, and never pressure you into physical or sexual acts.\n\nIf you ever feel unsafe, threatened, or controlled, confidential help is available. You have the absolute right to say no at any point in any interaction.',
            clinicalTip:
                'Be alert to signs of relationship coercion or reproductive coercion (e.g., partners sabotaging birth control or demanding pregnancy). Provide safe, confidential consultation.',
            patientAdvice:
                'Your boundaries are non-negotiable. If someone gets angry when you say "no", they are showing you that they value control over your well-being.',
            actionChecklist: [
              'Establish and communicate your personal boundaries clearly.',
              'Never share private passwords or intimate photos.',
              'Save emergency contact numbers and trust your instincts if a relationship feels uncomfortable.',
            ],
          ),
          const LearningTopicContent(
            title: 'Community Health Advocacy & Stigma Reduction',
            readTime: '4 min read',
            summary:
                'Youth-led health advocacy breaks down harmful stigmas surrounding sexual and reproductive health, creating supportive communities where everyone can access care.',
            keyPoints: [
              'Stigma creates fear and prevents young people from seeking life-saving healthcare.',
              'Peer education and accurate health information dispel cultural myths and shame.',
              'Every young person has the right to accurate, science-based health information and compassionate care.',
            ],
            detailedBody:
                'In many communities, discussing reproductive health, menstruation, or contraception is treated as taboo. This culture of silence leads to preventable health crises, high rates of unintended teenage pregnancy, and late STI diagnoses.\n\nBy speaking openly with factual information, supporting peers without judgment, and collaborating with local healthcare providers, youth champions transform community health outcomes.',
            clinicalTip:
                'Foster youth-friendly clinic environments: ensure visual and auditory privacy, friendly reception, and no parental disclosure requirements for confidential SRH care.',
            patientAdvice:
                'You can be a force for positive change in your school and neighborhood by sharing reliable health knowledge from this app with friends.',
            actionChecklist: [
              'Share verified health tips from the CAGH platform with friends.',
              'Refuse to participate in teasing or shaming peers regarding their health or bodies.',
              'Know where your nearest adolescent-friendly healthcare center is located.',
            ],
          ),
        ],
      ),
      LearningModuleItem(
        id: 'psychosocial_support',
        category: 'Psychosocial & Support',
        icon: Icons.favorite_rounded,
        themeColor: const Color(0xFFC2185B),
        bgLight: const Color(0xFFFCE4EC),
        bgDark: const Color(0xFF4A1027),
        readTime: '7 min read',
        articlesCount: '14 Guides',
        userBadge: 'Mental Wellness',
        midwifeBadge: 'Crisis Response',
        getTitle: (l10n) => l10n.psychosocialSupportAndProtection,
        getDesc: (l10n) => l10n.psychosocialSupportAndProtectionDesc,
        keyTakeaways: [
          'Recognizing signs of anxiety, depression, and trauma in maternal care.',
          'Gender-Based Violence (GBV) survivor support, referral pathways, and safety planning.',
          'Accessing confidential emergency hotlines, counseling, and social support services.',
        ],
        topicsCovered: [
          'Perinatal & Postpartum Mental Health',
          'GBV First Line Support & Safe Referrals',
          'Stress Management & Self-Care Practices',
          'Community Support Groups & Hotlines',
        ],
        topicContents: [
          const LearningTopicContent(
            title: 'Perinatal & Postpartum Mental Health',
            readTime: '5 min read',
            summary:
                'Mental health is as critical as physical health during pregnancy and after childbirth. Differentiating between the "baby blues" and clinical postpartum depression ensures timely treatment.',
            keyPoints: [
              'Baby blues affects up to 80% of new mothers and resolves naturally within 10 to 14 days.',
              'Postpartum Depression (PPD) lasts longer, causing intense sadness, anxiety, exhaustion, and detachment.',
              'PPD is a medical condition driven by drastic hormonal drops, sleep deprivation, and stress—not a personal failure.',
            ],
            detailedBody:
                'During pregnancy and postpartum, estrogen and progesterone plummet within 24 hours of delivery. When compounded by sleep fragmentation and social isolation, neurochemical imbalances can trigger clinical depression or anxiety.\n\nTreatment options include cognitive behavioral therapy (CBT), support groups, family counseling, and medications that are safe for breastfeeding mothers. Early intervention prevents long-term developmental impacts on mother and infant.',
            clinicalTip:
                'Administer the Edinburgh Postnatal Depression Scale (EPDS) at 6 weeks postpartum. Validate maternal emotions and destigmatize mental health care.',
            patientAdvice:
                'You are not a bad mother for feeling overwhelmed or sad. Admitting you need help is the strongest, most loving thing you can do for your baby and yourself.',
            actionChecklist: [
              'Talk to your partner or a family member about how you are feeling.',
              'Rest whenever your baby sleeps to reduce severe sleep deficits.',
              'Contact your midwife or counselor if feelings of deep sadness persist past two weeks.',
            ],
          ),
          const LearningTopicContent(
            title: 'GBV First Line Support & Safe Referrals',
            readTime: '5 min read',
            summary:
                'Gender-Based Violence (GBV) requires trauma-informed, immediate medical, psychological, and legal support. Survivors must receive non-judgmental care within safe clinical windows.',
            keyPoints: [
              'The WHO LIVES approach: Listen closely, Inquire about needs, Validate feelings, Enhance safety, Support with referrals.',
              'Emergency contraception is effective within 120 hours of sexual assault (most effective within 72h).',
              'HIV Post-Exposure Prophylaxis (PEP) must begin within 72 hours to prevent transmission.',
              'Tetanus and Hepatitis B vaccination plus prophylactic STI antibiotics are vital emergency clinical protocols.',
            ],
            detailedBody:
                'Survivors of physical or sexual violence often experience deep trauma, guilt, and fear of retaliation. Healthcare providers and support personnel must prioritize confidentiality, emotional comfort, and autonomy.\n\nDo not wash clothes or bathe before medical forensic examination if possible, but medical care should NEVER be withheld if washing has occurred. Support pathways connect survivors with safe shelters, legal aid, and specialized psychosocial counseling.',
            clinicalTip:
                'Follow the LIVES first-line support protocol. Maintain strict confidentiality and document clinical findings thoroughly for legal protection.',
            patientAdvice:
                'Violence is never your fault under any circumstances. You deserve safety, respect, and immediate medical care.',
            actionChecklist: [
              'Seek emergency medical care within 72 hours for PEP and emergency contraception.',
              'Access the confidential in-app emergency hotline (907 / 911).',
              'Confide in a trusted healthcare provider or counselor who can connect you with safe shelters.',
            ],
          ),
          const LearningTopicContent(
            title: 'Stress Management & Self-Care Practices',
            readTime: '4 min read',
            summary:
                'Practical evidence-based stress reduction techniques calm the nervous system, lower cortisol levels, and enhance emotional equilibrium.',
            keyPoints: [
              'Deep diaphragmatic breathing activates the parasympathetic "rest and digest" nervous response.',
              'Progressive muscle relaxation helps release somatic tension held in the neck, shoulders, and lower back.',
              'Setting clear emotional boundaries and saying "no" to excessive demands prevents burnout.',
            ],
            detailedBody:
                'Chronic psychological stress floods the body with cortisol and adrenaline, which can suppress immune function, elevate blood pressure, and exacerbate menstrual and pregnancy discomfort.\n\nPracticing the 4-7-8 breathing technique (inhale for 4 seconds, hold for 7, exhale slowly for 8) for just five minutes twice a day has been clinically shown to reduce heart rate variability and relieve acute anxiety.',
            clinicalTip:
                'Teach simple somatic calming exercises to expectant and young mothers during routine visits to build coping mechanisms.',
            patientAdvice:
                'Taking ten minutes for yourself is not selfish. When your cup is full, you have far more strength to give to your loved ones.',
            actionChecklist: [
              'Practice 5 minutes of slow diaphragmatic breathing daily.',
              'Take short breaks from your phone and screen time each evening.',
              'Reach out to a trusted friend when feeling overwhelmed.',
            ],
          ),
          const LearningTopicContent(
            title: 'Community Support Groups & Hotlines',
            readTime: '3 min read',
            summary:
                'No one should have to walk through difficult times alone. Connecting with peer groups and toll-free emergency lines offers immediate reassurance and ongoing hope.',
            keyPoints: [
              'Confidential, free telephone hotlines provide 24/7 crisis counseling and rapid referral dispatch.',
              'Maternal and youth peer groups provide safe spaces to share struggles without judgment.',
              'CAGH coordinates directly with regional social workers and clinical teams for wrap-around community support.',
            ],
            detailedBody:
                'Community solidarity is one of the strongest protective factors against depression and trauma. Finding people who share your experiences breaks feelings of isolation.\n\nWhether you need immediate help following an emergency, advice on caring for a newborn, or someone who will listen without judging, support lines and clinic counselors are ready to help.',
            clinicalTip:
                'Maintain an up-to-date printed and digital directory of local crisis centers, police child/women protection desks, and shelter contacts.',
            patientAdvice:
                'Save the national emergency support numbers (907 / 911) in your phone. Help is always just one call away.',
            actionChecklist: [
              'Use the in-app Emergency SOS feature for urgent assistance.',
              'Join a local mothers\' circle or adolescent peer group.',
              'Speak to your community midwife about counseling opportunities.',
            ],
          ),
        ],
      ),
      LearningModuleItem(
        id: 'reproductive_health',
        category: 'Reproductive & Care',
        icon: Icons.medical_services_rounded,
        themeColor: const Color(0xFF00796B),
        bgLight: const Color(0xFFE0F2F1),
        bgDark: const Color(0xFF003630),
        readTime: '10 min read',
        articlesCount: '16 Guides',
        userBadge: 'Maternal Care',
        midwifeBadge: 'Obstetric Standard',
        getTitle: (l10n) => l10n.reproductiveHealthAndCare,
        getDesc: (l10n) => l10n.reproductiveHealthAndCareDesc,
        keyTakeaways: [
          'Family planning options, birth control methods, and fertility awareness.',
          'Antenatal Care (ANC) schedule, danger signs during pregnancy, and nutrition.',
          'Essential newborn care, breastfeeding support, and postnatal checkups.',
        ],
        topicsCovered: [
          'Contraception Methods & Family Planning',
          'Antenatal Care (ANC) Milestone Checklist',
          'Warning Signs in Pregnancy & Labor Prep',
          'Postnatal Recovery & Infant Care',
        ],
        topicContents: [
          const LearningTopicContent(
            title: 'Contraception Methods & Family Planning',
            readTime: '6 min read',
            summary:
                'Modern family planning empowers women and couples to decide if, when, and how many children to have. Every person can find a method tailored to their medical profile.',
            keyPoints: [
              'Long-Acting Reversible Contraceptives (LARCs) like implants (3–5 years) and IUDs (5–10 years) are >99% effective.',
              'Short-acting methods include oral contraceptive pills (daily) and injectable progestin (every 3 months).',
              'Barrier methods (condoms) are the only method providing dual protection against both pregnancy and STIs.',
              'Emergency Contraception (morning-after pill) is for unintended unprotected intercourse within 72–120 hours.',
            ],
            detailedBody:
                'Contraceptive counseling uses the MEC (Medical Eligibility Criteria) framework from the WHO to match each woman with safe options. Progestin-only methods (implants, DMPA injections, mini-pills) are ideal for breastfeeding mothers and women with contraindications to estrogen.\n\nCommon harmless side effects like temporary spotting or changes in bleeding pattern should be explained during counseling to prevent premature discontinuation.',
            clinicalTip:
                'Provide balanced counseling using the BRAIDED approach (Benefits, Risks, Alternatives, Inquiries, Decisions, Explanations, Documentation). Address common cultural myths about fertility return.',
            patientAdvice:
                'Consult a midwife to discuss your lifestyle, health history, and future pregnancy goals so you can choose the best method for your body.',
            actionChecklist: [
              'Review contraceptive options with your midwife.',
              'If using daily pills, set a daily phone alarm to take them at the exact same hour.',
              'Keep emergency contraception accessible for unexpected needs.',
            ],
          ),
          const LearningTopicContent(
            title: 'Antenatal Care (ANC) Milestone Checklist',
            readTime: '6 min read',
            summary:
                'Antenatal Care (ANC) monitors maternal and fetal well-being, identifies risks early, and prepares families for a safe and joyful delivery experience.',
            keyPoints: [
              'The WHO recommends at least 8 ANC contacts during pregnancy, starting in the first trimester (<12 weeks).',
              'Key screenings: Blood group/Rh, complete blood count, syphilis, HIV, hepatitis B, urine protein/glucose, and ultrasound.',
              'Daily supplementation with Iron and Folic Acid (IFA) prevents neural tube defects and maternal anemia.',
              'Tetanus toxoid (TT) vaccination protects both mother and newborn from fatal neonatal tetanus.',
            ],
            detailedBody:
                'Each trimester carries specific clinical milestones. Trimester 1 focuses on viability, dating ultrasound, and nutritional counseling. Trimester 2 assesses fetal anatomy, maternal blood pressure (screening for pre-eclampsia), and fundal growth.\n\nTrimester 3 focuses on fetal presentation, birth preparedness, complication readiness, and newborn care education.',
            clinicalTip:
                'Always screen for elevated blood pressure (>140/90 mmHg) and proteinuria. Educate mothers to recognize reduced fetal kicks starting from week 28.',
            patientAdvice:
                'Attend every scheduled ANC appointment even if you feel healthy. Some of the most serious complications produce no noticeable symptoms in early stages.',
            actionChecklist: [
              'Book your first ANC checkup as soon as you discover you are pregnant.',
              'Take daily iron-folic acid pills with water or citrus juice.',
              'Pack your hospital birth bag by week 36.',
            ],
          ),
          const LearningTopicContent(
            title: 'Warning Signs in Pregnancy & Labor Prep',
            readTime: '5 min read',
            summary:
                'Recognizing obstetric danger signs allows rapid intervention that prevents life-threatening complications for mother and baby.',
            keyPoints: [
              'Severe persistent headache, visual disturbances, or upper abdominal pain can signal pre-eclampsia.',
              'Vaginal bleeding at any stage of pregnancy requires immediate emergency evaluation.',
              'A sudden gush or trickle of fluid (premature rupture of membranes) risks umbilical cord prolapse and infection.',
              'Noticeable decrease or cessation of fetal movements requires prompt fetal heart monitoring.',
            ],
            detailedBody:
                'Pre-eclampsia and eclampsia are leading causes of maternal mortality. If accompanied by hyperreflexia, facial edema, or epigastric pain, blood pressure must be managed with antihypertensives and magnesium sulfate immediately.\n\nLabor preparation includes establishing a Birth Preparedness and Complication Readiness (BPCR) plan: designated health facility, emergency transport savings, identified blood donor, and birth companion.',
            clinicalTip:
                'Routinely test emergency response drills for postpartum hemorrhage (PPH) and eclampsia. Ensure magnesium sulfate and oxytocin are always in stock.',
            patientAdvice:
                'Never wait or delay if you notice vaginal bleeding, severe headaches, or reduced baby movements. Head to your nearest hospital maternity unit immediately.',
            actionChecklist: [
              'Keep emergency contact numbers and transport arrangement ready.',
              'Count baby movements daily during the third trimester.',
              'Go to the hospital immediately if danger signs occur.',
            ],
          ),
          const LearningTopicContent(
            title: 'Postnatal Recovery & Infant Care',
            readTime: '5 min read',
            summary:
                'The first 6 weeks postpartum (the puerperium) are vital for maternal recovery, establishing exclusive breastfeeding, and supporting neonatal adaptation.',
            keyPoints: [
              'Exclusive breastfeeding for the first 6 months provides optimal nutrition, antibodies, and bonding.',
              'Watch for maternal puerperal sepsis signs: foul-smelling lochia, high fever, severe pelvic pain.',
              'Keep the infant\'s umbilical cord clean and dry (dry cord care) to prevent neonatal omphalitis.',
              'Kangaroo Mother Care (skin-to-skin contact) stabilizes newborn temperature, heart rate, and lactation.',
            ],
            detailedBody:
                'Postpartum visits should occur within 24 hours of birth, at day 3, between days 7–14, and at 6 weeks. These visits assess maternal uterine involution, perineal healing, mental wellness, and infant weight gain.\n\nBreast milk contains essential secretory IgA antibodies and oligosaccharides that shield the infant\'s gut from pathogens. No water, tea, or other liquids are needed before 6 months.',
            clinicalTip:
                'Assess breastfeeding latch and positioning to prevent cracked nipples and mastitis. Ensure BCG and birth polio/HepB vaccines are given before hospital discharge.',
            patientAdvice:
                'Feed your baby on demand whenever they show hunger cues (rooting, sucking hands). Drink plenty of water and allow family members to help with household chores.',
            actionChecklist: [
              'Practice exclusive breastfeeding day and night.',
              'Attend the 6-week postnatal checkup for infant immunizations and maternal counseling.',
              'Seek immediate care if you experience heavy bleeding soaking more than one pad per hour.',
            ],
          ),
        ],
      ),
    ];
  }

  static LearningModuleItem? getModuleById(String id) {
    try {
      return getModules().firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
