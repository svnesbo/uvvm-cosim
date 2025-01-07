#pragma once
#include <map>
#include <string>
#include "nlohmann/json.hpp"

using json = nlohmann::json;

struct VvcInstance {
  std::string vvc_type;
  std::string vvc_channel;
  int vvc_instance_id;
  std::map<std::string, int> vvc_cfg;
};

void to_json(json &j, const VvcInstance &v) {
  j = json{{"vvc_type", v.vvc_type},
           {"vvc_channel", v.vvc_channel},
           {"vvc_instance_id", v.vvc_instance_id},
           {"vvc_cfg", v.vvc_cfg}};
}

void from_json(const json &j, VvcInstance &v) {
  j.at("vvc_type").get_to(v.vvc_type);
  j.at("vvc_channel").get_to(v.vvc_channel);
  j.at("vvc_instance_id").get_to(v.vvc_instance_id);
  j.at("vvc_cfg").get_to(v.vvc_cfg);
}
