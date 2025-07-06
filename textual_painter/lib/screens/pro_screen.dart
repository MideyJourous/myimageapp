import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Pro badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Palette',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ImageGeneratorProvider>(
                    builder: (context, imageProvider, child) {
                      if (!imageProvider.isPro) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF8A2BE2),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Text(
                            '${100 - imageProvider.dailyGenerationCount} images left',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Start your own creative journey!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Features List

              _buildFeatureItem(Icons.check_circle, 'More image generations',
                  fontSize: 16, spacing: 8),
              _buildFeatureItem(Icons.check_circle, 'Access to the gallery',
                  fontSize: 16, spacing: 8),
              _buildFeatureItem(Icons.check_circle, 'Access to the pro theme',
                  fontSize: 16, spacing: 8),

              const SizedBox(height: 32),

              // Subscription Options
              _buildSubscriptionOption(
                'Weekly',
                '₩10,000/week',
                false,
                context,
              ),
              const SizedBox(height: 16),
              _buildSubscriptionOption(
                'Yearly',
                '₩140,000/year',
                true,
                context,
                savePercent: '70%',
                weeklyPrice: '₩2692.31/week',
              ),

              const SizedBox(height: 24),

              // Go Pro Button
              ElevatedButton(
                onPressed: () {
                  // 테스트 버전에서는 Pro 상태 토글
                  Provider.of<ImageGeneratorProvider>(context, listen: false)
                      .updateProStatus(true);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('테스트 모드: Pro 기능이 활성화되었습니다!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Pro',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.star, color: Colors.white),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Dismiss Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'DISMISS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Footer Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFooterLink('Already Purchased?',
                      'https://crystal-chips-2dd.notion.site/Term-of-Use-1d49a36f10db80ff8ec2e09af7f23576?pvs=4'),
                  const SizedBox(width: 24),
                  _buildFooterLink('Terms of Use',
                      'https://crystal-chips-2dd.notion.site/Term-of-Use-1d49a36f10db80ff8ec2e09af7f23576?pvs=4'),
                  const SizedBox(width: 24),
                  _buildFooterLink('Privacy Policy',
                      'https://crystal-chips-2dd.notion.site/Privacy-Policy-1d39a36f10db80dbb29cf5b2a35e0994?pvs=4'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text,
      {double fontSize = 16, double spacing = 16}) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.green[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(
    String title,
    String price,
    bool isSelected,
    BuildContext context, {
    String? savePercent,
    String? weeklyPrice,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey[800]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? const Color(0xFF8A2BE2).withOpacity(0.1) : null,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (savePercent != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SAVE $savePercent',
                        style: TextStyle(
                          color: Colors.purple[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              if (weeklyPrice != null)
                Text(
                  weeklyPrice,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey[800]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Color(0xFF8A2BE2),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, String url) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      },
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          decoration: TextDecoration.underline,
          fontSize: 12,
        ),
      ),
    );
  }
}
