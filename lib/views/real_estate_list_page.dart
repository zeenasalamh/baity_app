import 'package:baity/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../blocs/real_estate_bloc.dart';
import '../models/city.dart';
import '../repository/realestate_repo.dart';
import 'real_estate_details_page.dart';
class RealEstateListPage extends StatefulWidget {
  const RealEstateListPage({super.key});
  @override
  _RealEstateListPageState createState() => _RealEstateListPageState();
}
class _RealEstateListPageState extends State<RealEstateListPage> {
  // final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  String? _selectedCategory;
  String? _selectedOfferType;
  List<CityModel> _cities = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<RealEstateBloc>().add(LoadMoreRealEstatesEvent());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
  Future<void> _loadInitialData() async {
    try {
      final repository = Provider.of<RealEstateRepository>(context, listen: false);
      // final repository = ServiceLocator.get<RealEstateRepository>();
      final results = await Future.wait([
        repository.fetchCities(),
        repository.fetchCategories()
      ]);
      setState(() {
        _cities = results[0] as List<CityModel>;
        _categories = results[1] as List<CategoryModel>;
        _isLoading = false;
      });
      _fetchRealEstates();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    }
  }

  void _fetchRealEstates() {
    context.read<RealEstateBloc>().add(
      FetchRealEstatesEvent(
        cityId: _selectedCity,
        categoryId: _selectedCategory,
        offerType: _selectedOfferType,
        // searchQuery: _searchController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Real Estate Listings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Real Estate Listings')),
      body: Column(
        children: [
          // Search Bar
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: TextField(
          //     controller: _searchController,
          //     decoration: InputDecoration(
          //       hintText: 'Search by Owner or Title',
          //       prefixIcon: const Icon(Icons.search),
          //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          //     ),
          //     onChanged: (_) => _fetchRealEstates(),
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCity,
              hint: const Text('Select City'),
              items: _cities.map((city) {
                return DropdownMenuItem<String>(
                  value: city.id,
                  child: Text(city.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                  _fetchRealEstates();
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Select Category'),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _fetchRealEstates();
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedOfferType,
              hint: const Text('Select Offer Type'),
              items: const [
                DropdownMenuItem(value: 'SELL', child: Text('Sell')),
                DropdownMenuItem(value: 'RENT', child: Text('Rent')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedOfferType = value;
                  _fetchRealEstates();
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),

          Expanded(
            child: BlocBuilder<RealEstateBloc, RealEstateState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(child: Text('Error: ${state.error}'));
                }

                if (state.realEstates.isEmpty) {
                  return const Center(child: Text('No real estate listings found'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: state.realEstates.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.realEstates.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final estate = state.realEstates[index];
                    return ListTile(
                      title: Text(estate.title),
                      subtitle: Text('${estate.city.name} - ${estate.price} IQD'),
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(estate.ownerImageUrl),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RealEstateDetailsPage(realEstate: estate),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}