import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class LearnMoreScreen extends StatefulWidget {
  const LearnMoreScreen({Key? key}) : super(key: key);

  @override
  _LearnMoreScreenState createState() => _LearnMoreScreenState();
}

class _LearnMoreScreenState extends State<LearnMoreScreen> {
  final PageController _pageController = PageController();
  final List<Map<String, String>> _content = [
    {
      'image': 'assets/images/senior_traveler.png',
      'description':
          'Connect with volunteers who support the needs of seniors during their journeys.',
    },
    {
      'image': 'assets/images/worried_mom.png',
      'description':
          'Ensure smooth travels for parents with small kids, making family adventures effortless.',
    },
    {
      'image': 'assets/images/lonely_traveler.png',
      'description': 'Alone? Find a buddy to help your journey more memorable.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _content.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    _content[index]['image']!,
                    fit: BoxFit.fitWidth,
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _content[index]['description']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  if (index == _content.length - 1) ...[
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Go to Login'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ],
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _content.length,
                effect: WormEffect(
                  dotColor: Colors.grey,
                  activeDotColor: const Color.fromARGB(255, 180, 221, 255),
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
