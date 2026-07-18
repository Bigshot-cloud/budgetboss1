import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/debug_service.dart';
import 'package:intl/intl.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _debugService = DebugService();

  @override
  Widget build(BuildContext context) {
    final logs = _debugService.logs;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              setState(() {
                _debugService.clearLogs();
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(colorScheme),
          const Divider(height: 1),
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('No logs recorded yet', style: TextStyle(color: AppColors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.all(15),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogItem(log, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: colorScheme.surfaceContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OpenAI Status', style: TextStyle(color: AppColors.grey, fontSize: 12)),
              const SizedBox(height: 5),
              Text(
                _debugService.lastAiStatus,
                style: TextStyle(
                  color: _debugService.lastAiStatus == "Response Received" && _debugService.lastResponseCode == 200
                      ? AppColors.income
                      : AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_debugService.lastResponseCode != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Last Code', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                const SizedBox(height: 5),
                Text(
                  _debugService.lastResponseCode.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLogItem(DebugLog log, ColorScheme colorScheme) {
    Color statusColor = AppColors.gold;
    if (log.status == "Success" || log.status == "Active") statusColor = AppColors.income;
    if (log.status == "Failed" || log.status == "Error" || log.status == "Exception") statusColor = AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log.feature,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                DateFormat('HH:mm:ss').format(log.timestamp),
                style: const TextStyle(color: AppColors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.status,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  log.message,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (log.details != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                log.details!,
                style: const TextStyle(color: AppColors.grey, fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
