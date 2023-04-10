load("@ytt:data", "data")

def is_package_enabled(name):
  return (name not in data.values.platform.excluded_packages)
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
