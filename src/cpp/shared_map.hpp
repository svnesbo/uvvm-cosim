#pragma once
#include <mutex>
#include <map>

// K: Key, V: Value, C: Comparator clas
template <typename K, typename V, typename C> class shared_map {
  mutable std::mutex mtx;
  mutable std::map<K, V, C> mp;

public:
  template <typename F> auto operator()(F f) const -> decltype(f(mp)) {
    return std::lock_guard<std::mutex>(mtx), f(mp);
  }
};
