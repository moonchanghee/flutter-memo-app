import 'package:flutter/material.dart';

class CategoryDrawer extends StatelessWidget {
  const CategoryDrawer({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final void Function(String? categoryId) onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '폴더',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              title: const Text('전체'),
              selected: selectedCategoryId == null,
              onTap: () {
                onSelect(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final id = c['id'] as String;
                  return ListTile(
                    title: Text(c['name']?.toString() ?? '이름없음'),
                    selected: selectedCategoryId == id,
                    onTap: () {
                      onSelect(id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
