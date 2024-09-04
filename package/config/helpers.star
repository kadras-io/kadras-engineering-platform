load("@ytt:data", "data")
load("@ytt:struct", "struct")

profiles = struct.make(
  standalone="standalone",
  build="build",
  run="run"
)

def is_package_additional(name):
  return (name in data.values.platform.additional_packages) and is_package_enabled(name)
end

def is_package_enabled(name):
  return (name not in data.values.platform.excluded_packages)
end

def is_profile_enabled(profile):
  return data.values.platform.profile == profile
end

def is_any_profile_enabled(profiles):
  return data.values.platform.profile in profiles
end

def get_issuer_name(issuer):
  if issuer.type == "private":
    return "kadras-ca-issuer"
  elif issuer.type == "letsencrypt_staging":
    return "letsencrypt-staging-issuer"
  elif issuer.type == "letsencrypt":
    return "letsencrypt-prod-issuer"
  elif issuer.type == "custom":
    return issuer.name
  end
end
