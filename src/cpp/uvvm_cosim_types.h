#pragma once
#include <string>
#include "nlohmann/json.hpp"

using json = nlohmann::json;

struct VVCInfo {
  std::string vvc_type;
  std::string vvc_channel;
  int vvc_instance_id;
};

void to_json(json& j, const VVCInfo& v)
{
  j = json {
    {"vvc_type", v.vvc_type},
    {"vvc_channel", v.vvc_channel},
    {"vvc_instance_id", v.vvc_instance_id}
  };
}

void from_json(const json& j, VVCInfo& v)
{
  j.at("vvc_type").get_to(v.vvc_type);
  j.at("vvc_channel").get_to(v.vvc_channel);
  j.at("vvc_instance_id").get_to(v.vvc_instance_id);
}
