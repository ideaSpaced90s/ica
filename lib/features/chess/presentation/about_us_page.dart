import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/ambient_scaffold.dart';
import 'dashboard_page.dart';
import 'mobile_navigation_shell.dart';
import 'about_us/widgets/about_us_widgets.dart';
import 'about_us/tabs/overview_tab.dart';
import 'about_us/tabs/manual_tab.dart';
import 'about_us/tabs/tech_stack_tab.dart';
import 'about_us/tabs/contact_tab.dart';

class AboutUsPage extends ConsumerStatefulWidget {
  const AboutUsPage({super.key});

  @override
  ConsumerState<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends ConsumerState<AboutUsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    Color activeAccent;
    switch (_activeTabIndex) {
      case 0:
        activeAccent = Colors.indigo;
        break;
      case 1:
        activeAccent = const Color(0xFF10B981);
        break;
      case 2:
        activeAccent = Colors.purple;
        break;
      case 3:
        activeAccent = Colors.amber.shade700;
        break;
      default:
        activeAccent = Colors.blue;
    }

    final currentNavIndex = ref.watch(mobileNavIndexProvider);
    final isCurrentTab = currentNavIndex == 8;

    return PopScope(
      canPop: !isCurrentTab,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        exitToDashboardWithSidebar(context, ref);
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: activeAccent.withValues(alpha: 0.1),
        blob2Color: const Color(0xFFFCE7F3), // Soft Pink
        blob3Color: const Color(0xFFF3E8FF), // Soft Purple
        body: SafeArea(
          child: Column(
            children: [
              // Pill Tab Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TabSelector(
                  selectedIndex: _activeTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _activeTabIndex = index;
                    });
                  },
                ),
              ),

              // Scrollable Content Area
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildTabContent(_activeTabIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return const OverviewTab(key: ValueKey('overview'));
      case 1:
        return const ManualTab(key: ValueKey('manual'));
      case 2:
        return const TechStackTab(key: ValueKey('techstack'));
      case 3:
        return ContactTab(
          key: const ValueKey('contact'),
          launchUrlCallback: _launchUrl,
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $urlString'),
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          ),
        );
      }
    }
  }
}
