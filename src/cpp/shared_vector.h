#include <chrono>
#include <iostream>
#include <mutex>
#include <thread>
#include <utility>
#include <vector>

// Based on this StackOverflow answer to the question
// "What's the proper way to associate a mutex with its data?"
// https://stackoverflow.com/a/15845911
//
// Trimmed away most of it, leaving only operator() so we can
// execute a function that works on the vector, but waiting for
// a lock so two threads won't access the vector simultaneously.
template <typename T> class shared_vector {
  mutable std::mutex m;
  mutable std::vector<T> v;

public:
  template <typename F> auto operator()(F f) const -> decltype(f(v)) {
    return std::lock_guard<std::mutex>(m), f(v);
  }
};
