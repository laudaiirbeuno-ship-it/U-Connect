import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/history_advanced/controllers/history_advanced_controller.dart';
import 'package:uconnect/data/screens/history_advanced/widgets/history_filter_widget.dart';
import 'package:uconnect/data/screens/history_advanced/widgets/summary_cards_widget.dart';
import 'package:uconnect/data/screens/history_advanced/widgets/timeline_widget.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';

class HistoryAdvancedScreen extends StatefulWidget {
  @override
  _HistoryAdvancedScreenState createState() => _HistoryAdvancedScreenState();
}

class _HistoryAdvancedScreenState extends State<HistoryAdvancedScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isFilterSticky = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _isFilterSticky = _scrollController.offset > 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryAdvancedController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: 'Histórico Avançado',
          icon: Icons.history,
        ),
        body: Consumer2<HistoryAdvancedController, ColorProvider>(
          builder: (context, controller, colorProvider, child) {
            return Column(
              children: [
                // Filtro fixo
                HistoryFilterWidget(isSticky: _isFilterSticky),
                // Conteúdo
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => controller.loadData(),
                    color: colorProvider.primaryColor,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resumo
                          SummaryCardsWidget(),
                          SizedBox(height: 24),
                          // Timeline
                          TimelineWidget(),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      ),
    );
  }
}

