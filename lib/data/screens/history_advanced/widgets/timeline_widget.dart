import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/history_advanced/controllers/history_advanced_controller.dart';
import 'package:uconnect/data/screens/history_advanced/widgets/history_card_widget.dart';
import 'package:uconnect/data/screens/history_advanced/widgets/day_group_header.dart';

class TimelineWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HistoryAdvancedController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);

    if (controller.isLoading && controller.groupedEvents.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
        ),
      );
    }

    if (controller.groupedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum evento encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: controller.groupedEvents.length,
      itemBuilder: (context, index) {
        final dayKey = controller.groupedEvents.keys.elementAt(index);
        final events = controller.groupedEvents[dayKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DayGroupHeader(
              dayKey: dayKey,
              eventCount: events.length,
              colorProvider: colorProvider,
            ),
            SizedBox(height: 12),
            _buildTimelineForDay(
              context: context,
              events: events,
              colorProvider: colorProvider,
              controller: controller,
            ),
            SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildTimelineForDay({
    required BuildContext context,
    required List<HistoryEventItem> events,
    required ColorProvider colorProvider,
    required HistoryAdvancedController controller,
  }) {
    return Stack(
      children: [
        // Linha vertical da timeline
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: colorProvider.secondaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        // Cards dos eventos
        Column(
          children: events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == events.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador da timeline (bolha)
                  _buildTimelineIndicator(
                    context: context,
                    event: event,
                    colorProvider: colorProvider,
                    controller: controller,
                  ),
                  SizedBox(width: 16),
                  // Card do evento
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(20 * (1 - value), 0),
                            child: child,
                          ),
                        );
                      },
                      child: HistoryCardWidget(
                        event: event,
                        colorProvider: colorProvider,
                        controller: controller,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimelineIndicator({
    required BuildContext context,
    required HistoryEventItem event,
    required ColorProvider colorProvider,
    required HistoryAdvancedController controller,
  }) {
    final eventColor = controller.getEventColor(event, colorProvider);
    final eventIcon = controller.getEventIcon(event);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: eventColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: eventColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        eventIcon,
        color: eventColor,
        size: 20,
      ),
    );
  }
}

