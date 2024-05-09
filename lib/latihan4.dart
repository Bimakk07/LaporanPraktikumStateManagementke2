import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(// Menjalankan aplikasi dengan menggunakan ChangeNotifierProvider
      create: (context) => SelectedCountry(),
      child: MyApp(),
    ),
  );
}

// Kelas University untuk menampung data universitas
class University {
  final String name;
  final String website;

  University({required this.name, required this.website});

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
       // Mendapatkan nama dari data JSON
      name: json['name'] ?? '', 
       // Mendapatkan website dari data JSON, defaulting ke string kosong jika tidak tersedia
      website: json['web_pages'] != null && json['web_pages'].length > 0
          ? json['web_pages'][0]
          : '', 
    );
  }
}

// Kelas SelectedCountry untuk menampung negara yang dipilih dan menginformasikan pemberitahuan
class SelectedCountry with ChangeNotifier {
  String _country = 'Indonesia';
   // Getter untuk negara yang dipilih
  String get country => _country; 

  // Setter untuk negara yang dipilih, yang akan menginformasikan pemberitahuan ketika diubah
  set country(String newCountry) {
    _country = newCountry;
    notifyListeners(); 
  }
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<University>> futureUniversities; 
  @override
  // Inisialisasi state
  void initState() {
    super.initState();// Mendapatkan negara yang dipilih dari Provider
    final selectedCountry = Provider.of<SelectedCountry>(context, listen: false); // Memuat universitas untuk negara yang dipilih
    futureUniversities = fetchUniversities(selectedCountry.country);
  }

  Future<List<University>> fetchUniversities(String country) async {
    final response = await http.get(// Membuat permintaan HTTP GET ke API
        Uri.parse('http://universities.hipolabs.com/search?country=$country')); 

    // Memeriksa apakah respons berhasil
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
       // Mengubah data JSON menjadi daftar University
      return data.map((json) => University.fromJson(json)).toList(); 
    } else {
      throw Exception('Failed to load universities');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menampilkan Universitas dan situs',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Menampilkan Universitas dan situs'),
        ),
        body: Center(
          child: Column(
            children: [
              Consumer<SelectedCountry>(
                builder: (context, selectedCountry, child) {
                  return DropdownButton<String>(
                    value: selectedCountry.country,
                    onChanged: (newValue) {
                      selectedCountry.country = newValue!; 
                      setState(() {
                        futureUniversities = fetchUniversities(newValue); 
                      });
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
              ),
              Expanded(
                child: FutureBuilder<List<University>>(
                  future: futureUniversities,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(); // Menampilkan indikator loading ketika data sedang dimuat
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}'); // Menampilkan pesan error jika gagal memuat data
                    } else if (snapshot.hasData) {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(border: Border.all()),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(snapshot.data![index].name), // Menampilkan nama universitas
                                Text(snapshot.data![index].website), // Menampilkan situs web universitas
                              ],
                            ),
                          );
                        },
                      );
                    } else {
                      return const Text('No data available'); // Menampilkan pesan jika tidak ada data yang tersedia
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}