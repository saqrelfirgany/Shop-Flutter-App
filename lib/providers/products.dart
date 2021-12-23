import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product>? _items = [];
  final String? authToken;
  final String? userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items!];
  }

  List<Product> get favoritesItem {
    return _items!.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product finById(String id) {
    return _items!.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url = Uri.parse(
        'https://flutter-shop-fdfd0-default-rtdb.firebaseio.com/products.json?auth=$authToken&$filterString');
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>?;
      print(extractedData);
      if (extractedData == null) {
        return;
      }
      url = Uri.parse(
          'https://flutter-shop-fdfd0-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken');
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      print('1');
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      print('2');
      _items = loadedProducts;
      print('3');
      notifyListeners();
      print('4');
    } catch (error) {
      rethrow;
    }
  }

  // Future<void> fetchAndSetProduct() async {
  //   var url = Uri.parse(
  //       'https://flutter-update.firebaseio.com/products.json?auth=$authToken&$filterString');
  //   try {
  //     final response = await http.get(url);
  //     final extractedData = json.decode(response.body) as Map<String, dynamic>?;
  //     if (extractedData == null) {
  //       return;
  //     }
  //     url = Uri.parse(
  //         'https://flutter-shop-fdfd0-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken');
  //     print('user id $userId');
  //     final favoriteResponse = await http.get(url);
  //     final favoriteData = json.decode(favoriteResponse.body);
  //     final List<Product>? loadedProducts = [];
  //     // print(json.decode(response.body));
  //     print('extractedData ');
  //     extractedData.forEach((prodId, prodData) {
  //       print('favoriteData[prodId] ${favoriteData[prodId]}');
  //       loadedProducts!.add(
  //         Product(
  //           id: prodId,
  //           title: prodData['title'],
  //           description: prodData['description'],
  //           price: prodData['price'],
  //           imageUrl: prodData['imageUrl'],
  //           isFavorite:
  //               favoriteData == null ? false : favoriteData[prodId] ?? false,
  //         ),
  //       );
  //     });
  //     _items= loadedProducts;
  //     notifyListeners();
  //   } catch (error) {
  //     throw error;
  //   }
  // }

  Future<void> addProduct(Product product) async {
    var url = Uri.parse(
        'https://flutter-shop-fdfd0-default-rtdb.firebaseio.com/products.json?auth=$authToken&orderBy="creatorId"&equalTo="$userId"');
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
            'creatorId': userId,
          },
        ),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items!.add(newProduct);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items!.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      var url = Uri.parse(
          'https://flutter-shop-fdfd0-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken');

      await http.patch(
        url,
        body: json.encode(
          {
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price,
          },
        ),
      );
      _items?[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    var url = Uri.parse(
        'https://flutter-shop-fdfd0-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken');
    final existingProductIndex = _items!.indexWhere((prod) => prod.id == id);
    Product? existingProduct = _items![existingProductIndex];
    _items!.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items!.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
