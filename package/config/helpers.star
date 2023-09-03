load("@ytt:data", "data")
load("@ytt:struct", "struct")

profiles = struct.make(
  full="full",
  dev="dev",
  build="build",
  run="run"
)

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
    return "letsencrypt-staging-http01-issuer"
  elif issuer.type == "letsencrypt":
    return "letsencrypt-http01-issuer"
  elif issuer.type == "custom":
    return issuer.name
  end
end
