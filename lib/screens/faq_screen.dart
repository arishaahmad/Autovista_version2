import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  final List<FAQItem> faqs = [
    FAQItem(
      question: "How to Change a Tire?",
      answer: "Step-by-step guide to changing a flat tire safely:",
      steps: [
        "1. Find a safe, flat location",
        "2. Apply parking brake and wheel wedges",
        "3. Remove hubcap and loosen lug nuts",
        "4. Jack up the vehicle",
        "5. Remove flat tire and mount spare",
        "6. Tighten lug nuts in star pattern",
        "7. Lower vehicle and fully tighten nuts"
      ],
      imagePath: 'images/flat_tire.jpg',
    ),
    FAQItem(
      question: "Checking Oil Level",
      answer: "Proper way to check your engine oil:",
      steps: [
        "1. Park on level ground and warm up engine",
        "2. Turn off engine and wait 5 minutes",
        "3. Locate and remove dipstick",
        "4. Wipe clean and reinsert fully",
        "5. Remove again and check level between marks",
        "6. Add oil if needed (check manual for type)",
        "7. Reinsert dipstick securely"
      ],
      imagePath: 'assets/check_oil.png',
    ),
    // Add more FAQs here
  ];

  FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Help & FAQs"),
        backgroundColor: Colors.teal.shade700,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return _buildFAQCard(faqs[index]);
        },
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.help_rounded, color: Colors.teal),
        title: Text(
          faq.question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.answer,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...faq.steps.map((step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(step),
                )),
                if (faq.imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Image.asset(
                      faq.imagePath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;
  final List<String> steps;
  final String? imagePath;

  FAQItem({
    required this.question,
    required this.answer,
    required this.steps,
    this.imagePath,
  });
}