import 'package:employee_setup/features/lost_found/data/repositories/lost_found_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lost_found_item.dart';

class LostFoundScreen extends ConsumerStatefulWidget {
  const LostFoundScreen({super.key});

  @override
  ConsumerState<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends ConsumerState<LostFoundScreen> {
  void _showRegisterDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final vaultCtrl = TextEditingController();
    String category = 'OTHER';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Register Lost & Found Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'JEWELRY', child: Text('Jewelry')),
                    DropdownMenuItem(value: 'ELECTRONICS', child: Text('Electronics')),
                    DropdownMenuItem(value: 'CLOTHING', child: Text('Clothing')),
                    DropdownMenuItem(value: 'DOCUMENTS', child: Text('Documents')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => category = val);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Found Location (e.g. Room 402) *',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: vaultCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vault / Storage Safe Location *',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    locCtrl.text.trim().isEmpty ||
                    vaultCtrl.text.trim().isEmpty) {
                  return;
                }
                final item = LostFoundItem(
                  id: '',
                  itemName: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  category: category,
                  locationFound: locCtrl.text.trim(),
                  foundDate: DateTime.now(),
                  storageLocation: vaultCtrl.text.trim(),
                );
                Navigator.pop(dialogCtx);
                try {
                  await ref.read(lostFoundRepositoryProvider).registerItem(item);
                  ref.invalidate(lostFoundItemsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item registered successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Registration failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(lostFoundItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(lostFoundItemsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterDialog,
        icon: const Icon(Icons.add),
        label: const Text('Log Found Item'),
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(lostFoundItemsProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No lost items registered',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(lostFoundItemsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final item = items[idx];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        item.category == 'JEWELRY'
                            ? Icons.watch_outlined
                            : item.category == 'ELECTRONICS'
                                ? Icons.devices_outlined
                                : Icons.luggage_outlined,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Found at: ${item.locationFound}'),
                        Text(
                          'Vault: ${item.storageLocation}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.description.isNotEmpty)
                          Text(
                            item.description,
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        item.status,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              ElevatedButton(
                onPressed: () => ref.invalidate(lostFoundItemsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
