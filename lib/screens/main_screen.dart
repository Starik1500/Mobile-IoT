import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../providers/connectivity_provider.dart';
import '../cubits/home/home_cubit.dart';
import '../cubits/home/home_state.dart';
import '../widgets/meter_list_widget.dart';
import '../widgets/add_meter_sheet.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasInternet = context.watch<ConnectivityProvider>().hasInternet;

    context.read<HomeCubit>().loadData();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Об\'єкти обліку'), backgroundColor: Colors.teal, foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              if (!context.mounted) return;
              context.read<HomeCubit>().loadData();
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (!hasInternet)
            Container(
              width: double.infinity, color: Colors.red, padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text('Офлайн режим (Дані з локальної бази)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
            ),
          Expanded(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading || state is HomeInitial) {
                  return const Center(child: CircularProgressIndicator(color: Colors.teal));
                }

                if (state is HomeError) {
                  return Center(child: Text(state.message));
                }

                if (state is HomeLoaded) {
                  final user = state.user;
                  final readings = state.readings;

                  if (user.meters.isEmpty) {
                    return buildEmptyState(context, user, () => context.read<HomeCubit>().loadData());
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0), itemCount: user.meters.length,
                    itemBuilder: (context, index) {
                      return MeterListItem(
                        meterKey: user.meters[index],
                        reading: readings[user.meters[index]] ?? 'Немає даних',
                        onDelete: () => context.read<HomeCubit>().deleteMeter(user, index),
                        onRefresh: () => context.read<HomeCubit>().loadData(),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoaded) {
              return FloatingActionButton(
                onPressed: () => showAddMeterModal(context, state.user, () => context.read<HomeCubit>().loadData()),
                backgroundColor: Colors.teal, foregroundColor: Colors.white, child: const Icon(Icons.add),
              );
            }
            return const SizedBox();
          }
      ),
    );
  }
}