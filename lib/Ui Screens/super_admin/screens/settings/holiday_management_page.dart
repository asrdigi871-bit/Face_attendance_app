import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/data_models.dart';
import '../../providers/settings_data.dart';

// Page for Holiday Management (Settings sub-page)
class HolidayManagementPage extends StatefulWidget {
  const HolidayManagementPage({super.key});

  @override
  State<HolidayManagementPage> createState() => _HolidayManagementPageState();
}

class _HolidayManagementPageState extends State<HolidayManagementPage> {
  Future<void> _addHolidayDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    DateTime? selectedDate;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Holiday'),
          content: StatefulBuilder(
            // Use StatefulBuilder to manage the state of the dialog content
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameController,
                      decoration:
                      const InputDecoration(labelText: 'Holiday Name'),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        selectedDate == null
                            ? 'Select Date'
                            : DateFormat('yyyy-MM-dd').format(selectedDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365 * 5),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5),
                          ),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedDate != null) {
                  Future.microtask(() {
                    Provider.of<HolidayData>(context, listen: false).addHoliday(
                      Holiday(name: nameController.text, date: selectedDate!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${nameController.text} added!')),
                    );
                    Navigator.of(dialogContext).pop();
                  });
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter name and select a date.'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Management'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<HolidayData>(
        builder: (BuildContext context, HolidayData holidayData, Widget? child) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Upcoming Holidays',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _addHolidayDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Holiday'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: holidayData.holidays.isEmpty
                    ? const Center(child: Text('No holidays added yet.'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                  ),
                  itemCount: holidayData.holidays.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Holiday holiday = holidayData.holidays[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.event,
                          color: const Color(0xFF2563EB),
                        ),
                        title: Text(
                          holiday.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'EEEE, MMM d, yyyy',
                          ).format(holiday.date),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            Future.microtask(() {
                              holidayData.removeHoliday(holiday);
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${holiday.name} removed.',
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}