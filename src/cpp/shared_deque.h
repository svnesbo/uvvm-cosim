#pragma once
#include <chrono>
#include <iostream>
#include <mutex>
#include <thread>
#include <utility>
#include <deque>

// Same idea as shared_vector class
template <typename T> class shared_deque {
  mutable std::mutex m;
  mutable std::deque<T> q;

public:
  template <typename F> auto operator()(F f) const -> decltype(f(q)) {
    return std::lock_guard<std::mutex>(m), f(q);
  }
};
