import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'viewer_dashboard.dart';

class ViewerLinkScreen extends StatelessWidget {
  final String viewerUid;

  const ViewerLinkScreen({super.key, required this.viewerUid});

  @override
  Widget build(BuildContext context) {
    final String viewerLink =
        "https://trackit-web.web.app/viewer/$viewerUid";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Viewer Access"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Share this link with viewer",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SelectableText(
              viewerLink,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: viewerLink),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Viewer link copied"),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text("Copy Link"),
            ),

            const SizedBox(height: 16),

            // 🔥 STEP 3 BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ViewerDashboard(studentUid: viewerUid),
                  ),
                );
              },
              child: const Text("Open Viewer Dashboard"),
            ),
          ],
        ),
      ),
    );
  }
}