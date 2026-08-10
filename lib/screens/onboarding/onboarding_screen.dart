import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;


  final List<OnboardData> _pages = [
    OnboardData(
      title: 'DrugBee',
      subtitle: 'Fast Medicine Discovery',
      description: 'Find rare, neglected or unavailable medicines in minutes across India.',
      icon: Icons.search_rounded,
    ),
    OnboardData(
      title: 'Verified Vendors',
      subtitle: 'Trusted Network',
      description: 'Instant access to verified pharma vendors. No middlemen, no hidden fees.',
      icon: Icons.verified_user_rounded,
    ),
    OnboardData(
      title: 'Quick Request',
      subtitle: 'Effortless Demand',
      description: 'Submit your requirements with dosage & location. Let the vendors find you.',
      icon: Icons.speed_rounded,
    ),
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

          Positioned(
            top: -100, right: -100,
            child: CircleAvatar(radius: 160, backgroundColor: primaryColor.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: CircleAvatar(radius: 120, backgroundColor: primaryColor.withOpacity(0.09)),
          ),

          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    return _OnboardPage(
                      data: _pages[index],
                      isActive: _currentPage == index,
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 10),
                          height: 6,
                          width: _currentPage == index ? 32 : 10,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? primaryColor : primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: _currentPage == _pages.length - 1 ? 4 : 0,
                        ),
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _finishOnboarding();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastOutSlowIn,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'GET STARTED' : 'CONTINUE',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: _currentPage == _pages.length - 1 ? 0 : 1,
                      child: TextButton(
                        onPressed: _currentPage == _pages.length - 1 ? null : _finishOnboarding,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final OnboardData data; // Removed underscore
  final bool isActive;
  const _OnboardPage({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: isActive ? 200 : 180,
                width: isActive ? 200 : 180,
                decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.05)),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Icon(data.icon, size: 85, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 60),
          Text(
            data.title.toUpperCase(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3, color: primaryColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.grey.shade900),
          ),
          const SizedBox(height: 20),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, height: 1.6),
          ),
        ],
      ),
    );
  }
}


class OnboardData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;

  const OnboardData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });
}