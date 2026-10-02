import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerseRef {
  const VerseRef(this.chapter, this.verse);
  final int chapter;
  final int verse;
  @override
  bool operator ==(Object o) => o is VerseRef && o.chapter == chapter && o.verse == verse;
  @override
  int get hashCode => Object.hash(chapter, verse);
}

class ReadPos {
  const ReadPos(this.chapter, this.verse, this.page);
  final int chapter;
  final int verse;
  final int page;
  Map<String, dynamic> toJson() => {'c': chapter, 'v': verse, 'p': page};
  factory ReadPos.fromJson(Map<String, dynamic> j) =>
      ReadPos(j['c'] as int, j['v'] as int, j['p'] as int);
}

/// "Continue reading": persisted locally, survives app/phone restarts.
final lastReadProvider =
    NotifierProvider<LastReadNotifier, ReadPos?>(LastReadNotifier.new);

class LastReadNotifier extends Notifier<ReadPos?> {
  static const _key = 'last_read_v1';

  @override
  ReadPos? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s != null && state == null) {
      state = ReadPos.fromJson(jsonDecode(s) as Map<String, dynamic>);
    }
  }

  Future<void> set(ReadPos pos) async {
    state = pos;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(pos.toJson()));
  }
}

class Bookmark {
  const Bookmark(this.chapter, this.verse, this.page, this.created);
  final int chapter;
  final int verse;
  final int page;
  final DateTime created;
  Map<String, dynamic> toJson() =>
      {'c': chapter, 'v': verse, 'p': page, 't': created.toIso8601String()};
  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
      j['c'] as int, j['v'] as int, j['p'] as int, DateTime.parse(j['t'] as String));
}

final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, List<Bookmark>>(BookmarksNotifier.new);

class BookmarksNotifier extends Notifier<List<Bookmark>> {
  static const _key = 'bookmarks_v1';

  @override
  List<Bookmark> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s != null) {
      state = (jsonDecode(s) as List)
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(state.map((b) => b.toJson()).toList()));
  }

  bool has(int c, int v) => state.any((b) => b.chapter == c && b.verse == v);

  Future<void> toggle(int c, int v, int page) async {
    if (has(c, v)) {
      state = state.where((b) => !(b.chapter == c && b.verse == v)).toList();
    } else {
      state = [Bookmark(c, v, page, DateTime.now()), ...state];
    }
    await _save();
  }

  Future<void> remove(Bookmark b) async {
    state = state.where((x) => x != b).toList();
    await _save();
  }
}
