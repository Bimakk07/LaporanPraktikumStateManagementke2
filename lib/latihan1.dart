import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

// Class University untuk menyimpan nama dan website universitas
class University {
  final String name;
  final String website;

  University({required this.name, required this.website});
// Factory constructor untuk membuat instance University dari JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'] ?? '', 
      website: json['web_pages'] != null && json['web_pages'].length > 0
          ? json['web_pages'][0]
          : '', 
    );
  }
}
// Cubit untuk mengelola state negara
class CountryCubit extends Cubit<String> {
  CountryCubit() : super('Indonesia'); 

// Fungsi untuk memilih negara baru
  void selectCountry(String newCountry) => emit(newCountry); 
}

// Cubit untuk mengelola state daftar universitas
class UniversityCubit extends Cubit<List<University>> {
  UniversityCubit() : super([]); 

// Fungsi untuk mengambil daftar universitas dari API
  Future<void> fetchUniversities(String country) async {
    final response = await http.get(
        Uri.parse('http://universities.hipolabs.com/search?country=$country')); 

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      emit(data.map((json) => University.fromJson(json)).toList()); 
    } else {
      throw Exception('Gagal memuat universitas'); 
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // Fungsi untuk membuat tampilan aplikasi
  @override
  Widget build(BuildContext context) {
    // Menginisialisasi cubit-cubit yang digunakan
    return MultiBlocProvider(
      providers: [
        BlocProvider<CountryCubit>(create: (context) => CountryCubit()), 
        BlocProvider<UniversityCubit>(create: (context) => UniversityCubit()), 
      ],
      child: MaterialApp(
        title: 'Menampilkan Universitas dan situs',
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Menampilkan Universitas dan situs'),
          ),
          body: const Center(
            child: Column(
              children: [
                CountryDropdown(),// Menampilkan dropdown negara
                Expanded(child: UniversityList()), // Menampilkan daftar universitas
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Class CountryDropdown untuk membuat dropdown negara
class CountryDropdown extends StatelessWidget {
  const CountryDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan cubit negara
    return BlocBuilder<CountryCubit, String>(
      builder: (context, selectedCountry) {// Mengambil state saat ini dari cubit negara
        return DropdownButton<String>(// Menginisialisasi DropdownButton
          value: selectedCountry, 
          onChanged: (newValue) {
            context.read<CountryCubit>().selectCountry(newValue!); 
            context.read<UniversityCubit>().fetchUniversities(newValue); 
          },
          items: <String>[
            'Indonesia','Malaysia','Singapura','Vietnam','Thailand','Brunei','Kamboja',
 
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      },
    );
  }
}

class UniversityList extends StatelessWidget {
  const UniversityList({super.key});
 // Fungsi untuk membuat tampilan dropdown negara
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityCubit, List<University>>(
      builder: (context, universityList) {
        if (universityList.isEmpty) {
          return const CircularProgressIndicator(); // Menampilkan indikator loading jika daftar universitas kosong
        } else {
          return ListView.builder(
            itemCount: universityList.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(border: Border.all()),
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(universityList[index].name), // Menampilkan nama universitas
                    Text(universityList[index].website), // Menampilkan situs web universitas
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}