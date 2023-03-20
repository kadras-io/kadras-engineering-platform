load("@ytt:data", "data")

def is_package_enabled(name):
    return (name not in data.values.packages.excluded)
end
