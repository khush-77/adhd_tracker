import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

class ResourceModel {
  final String title;
  final String imageUrl;
  final String url;
  final String? author;

  ResourceModel({
    required this.title,
    required this.imageUrl,
    required this.url,
    this.author,
  });

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      url: map['url'] ?? '',
      author: map['author'],
    );
  }
}

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({Key? key}) : super(key: key);

  @override
  _ResourcesPageState createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Resources'),

      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Popular Collections',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CollectionsGrid(searchQuery: _searchQuery),
              const SizedBox(height: 24),
              const Text(
                'Featured Resources',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              FeaturedResourcesList(searchQuery: _searchQuery),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onChanged;

  const SearchBar({
    Key? key,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          hintText: 'Search resources',
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class FeaturedResourcesList extends StatelessWidget {
  final String searchQuery;

  const FeaturedResourcesList({
    Key? key,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final resources = [
      ResourceModel(
        title: 'Understanding ADHD',
        author: 'Psychiatry',
        url: 'https://www.psychiatry.org/patients-families/adhd/what-is-adhd#:~:text=Attention%2Ddeficit%2Fhyperactivity%20disorder%20(ADHD)%20is%20one%20of,in%20the%20moment%20without%20thought).',
        imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
      ),
      ResourceModel(
        title: 'ADHD in Women and Girls',
        author: 'CHADD',
        url: 'https://chadd.org/for-adults/women-and-girls/',
        imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
      ),
      ResourceModel(
        title: 'Managing Adult ADHD',
        author: 'HelpGuide.org',
        url: 'https://www.helpguide.org/mental-health/adhd/managing-adult-adhd',
        imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
      ),
      ResourceModel(
        title: 'ADHD Treatment Guidelines',
        author: 'American Academy of Pediatrics',
        url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC10764666/',
        imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
      ),
      ResourceModel(
        title: 'Overlooked signs of ADHD',
        author: 'ADDitude',
        url: 'https://www.additudemag.com/adhd-inattentive-type-5-signs/',
        imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
      ),
      ResourceModel(
        title: 'ADHD Treatment Guidelines',
        author: 'Medical News Today',
        url: 'https://www.medicalnewstoday.com/articles/adhd-linked-to-astonishing-reduction-in-life-expectancy',
        imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
      ),
      ResourceModel(
        title: 'ADHD and Executive Function',
        author: 'ADDitude Magazine',
        url: 'https://www.additudemag.com/category/adhd-add/adhd-essentials/',
        imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
      ),
      ResourceModel(
        title: 'Types of ADHD',
        author: 'ADDitude Magazine',
        url: 'https://www.additudemag.com/3-types-of-adhd/',
        imageUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac',
      ),
    ];

    final filteredResources = resources.where((resource) {
      final titleMatch = resource.title.toLowerCase().contains(searchQuery);
      final authorMatch = resource.author?.toLowerCase().contains(searchQuery) ?? false;
      return titleMatch || authorMatch;
    }).toList();

    return filteredResources.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No resources found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredResources.length,
            itemBuilder: (context, index) {
              final resource = filteredResources[index];
              return ResourceListItem(resource: resource);
            },
          );
  }
}

class ResourceListItem extends StatelessWidget {
  final ResourceModel resource;

  const ResourceListItem({
    Key? key,
    required this.resource,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceWebViewPage(resource: resource),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (resource.author != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By: ${resource.author}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResourceWebViewPage(resource: resource),
                  ),
                );
              },
              child: const Text('Read Now'),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionsGrid extends StatelessWidget {
  final String searchQuery;

  const CollectionsGrid({
    Key? key,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final collections = [
      ResourceModel(
        title: 'ADHD and Relationships',
        imageUrl: 'https://www.helpguide.org/wp-content/uploads/2023/02/ADHD-and-Relationships.jpeg',
        url: 'https://www.helpguide.org/articles/add-adhd/adult-adhd-attention-deficit-disorder-and-relationships.htm',
      ),
      ResourceModel(
        title: 'ADHD at Work',
        imageUrl: 'https://img.lb.wbmdstatic.com/vim/live/webmd/consumer_assets/site_images/article_thumbnails/BigBead/ADHD_in_workplace_bigbead/1800x1200_adhd_in_workplace_bigbead.jpg',
        url: 'https://www.webmd.com/add-adhd/adhd-in-the-workplace',
      ),
      ResourceModel(
        title: 'ADHD and Education',
        imageUrl: 'https://www.cdc.gov/adhd/media/images/teacherhelpingstudent1200_1.png',
        url: 'https://childmind.org/article/adhd-behavior-problems/',
      ),
    ];

    final filteredCollections = collections.where((collection) {
      return collection.title.toLowerCase().contains(searchQuery);
    }).toList();

    return filteredCollections.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredCollections.length,
              itemBuilder: (context, index) {
                return CollectionCard(resource: filteredCollections[index]);
              },
            ),
          );
  }
}

class CollectionCard extends StatelessWidget {
  final ResourceModel resource;

  const CollectionCard({
    Key? key,
    required this.resource,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourceWebViewPage(resource: resource),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Image.network(
                    resource.imageUrl,
                    height: 120,
                    width: 180,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 120,
                    width: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              resource.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
class ResourceWebViewPage extends StatefulWidget {
  final ResourceModel resource;

  const ResourceWebViewPage({Key? key, required this.resource})
      : super(key: key);

  @override
  State<ResourceWebViewPage> createState() => _ResourceWebViewPageState();
}

class _ResourceWebViewPageState extends State<ResourceWebViewPage> {
  late final WebViewController _controller;
  bool isLoading = true;
  String? errorMessage;
  double loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                isLoading = true;
                errorMessage = null;
                loadingProgress = 0.0;
              });
            }
          },
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                loadingProgress = progress / 100;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = _getErrorMessage(error);
                print('WebView error: ${error.description}');
              });
            }
          },
          // Allow all navigation requests
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    try {
      await _controller.loadRequest(
        Uri.parse(widget.resource.url),
        headers: {
          'Accept': '*/*', // Accept all content types
          'Accept-Language': 'en-US,en;q=0.5',
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load the page: $e';
          isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(WebResourceError error) {
    return 'Error loading page: ${error.description}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.resource.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                  loadingProgress = 0.0;
                });
                _controller.reload();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            if (errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                            loadingProgress = 0.0;
                          });
                          _controller.reload();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else
              WebViewWidget(controller: _controller),
            if (isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          value: loadingProgress > 0 ? loadingProgress : null),
                      const SizedBox(height: 16),
                      Text(
                        'Loading... ${(loadingProgress * 100).toInt()}%',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}