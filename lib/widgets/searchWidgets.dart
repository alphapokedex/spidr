import 'package:flutter/material.dart';

Widget searchIcon() {
  return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF9800)]),
          borderRadius: BorderRadius.circular(40)),
      padding: const EdgeInsets.all(12),
      child: Image.asset('assets/images/search.png'));
}

searchBar(
    {TextEditingController searchEditingController,
    String searchType,
    Function searchChats,
    Function searchUsers}) {
  return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    child: Row(
      children: [
        searchIcon(),
        const SizedBox(
          width: 15,
        ),
        Expanded(
            child: TextField(
          controller: searchEditingController,
          onChanged: (String val) {
            if (searchType == 'CIRCLE') {
              searchChats(val);
            } else if (searchType == 'USER') {
              searchUsers(val);
            }
          },
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: searchType == 'CIRCLE'
                ? 'Search for circle'
                : 'Search for user',
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        )),
      ],
    ),
  );
}
