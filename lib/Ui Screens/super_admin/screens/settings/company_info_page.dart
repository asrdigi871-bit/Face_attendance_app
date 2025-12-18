import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_data.dart';

// Page for Company Information (Settings sub-page)
class CompanyInfoPage extends StatefulWidget {
  const CompanyInfoPage({super.key});

  @override
  State<CompanyInfoPage> createState() => _CompanyInfoPageState();
}

class _CompanyInfoPageState extends State<CompanyInfoPage> {
  late TextEditingController _companyNameController;
  late TextEditingController _companyAddressController;
  late TextEditingController _companyPhoneController;
  late TextEditingController _companyWebsiteController;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _companyAddressController = TextEditingController();
    _companyPhoneController = TextEditingController();
    _companyWebsiteController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final SettingsData settingsData = Provider.of<SettingsData>(
        context,
        listen: false,
      );
      _companyNameController.text = settingsData.companyName;
      _companyAddressController.text = settingsData.companyAddress;
      _companyPhoneController.text = settingsData.companyPhone;
      _companyWebsiteController.text = settingsData.companyWebsite;
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyWebsiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Information'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<SettingsData>(
        builder: (BuildContext context, SettingsData settingsData, Widget? child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Edit Company Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.apartment),
                  ),
                  onChanged: settingsData.updateCompanyName,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _companyAddressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  onChanged: settingsData.updateCompanyAddress,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _companyPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: settingsData.updateCompanyPhone,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _companyWebsiteController,
                  decoration: InputDecoration(
                    labelText: 'Website',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.web),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: settingsData.updateCompanyWebsite,
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Company information saved!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}