K8S_VERSION=v1.26

# Build package configuration
build: package
	cd package && kctrl package init

# Prepare cluster for development workflow
prepare: test/setup
	ytt -f test/setup/assets/namespace.yml | kapp deploy -a ns -f- -y
	ytt -f test/setup/assets/rbac.yml | kapp deploy -a rbac -f- -y
	kubectl config set-context --current --namespace=tests

# Inner development loop
dev: package
	cd package && kctrl dev -f package-resources.yml --local -y

# Clean development environment
clean:
	cd package && kctrl dev -f package-resources.yml --local -y --delete 

# Process the configuration manifests with ytt
ytt:
	ytt --file package/config

# Use ytt to generate an OpenAPI specification
schema:
	ytt -f package/config/values-schema.yml --data-values-schema-inspect -o openapi-v3 > schema-openapi.yml

# Check the ytt-annotated Kubernetes configuration and its validation
test-config:
	ytt -f package/config | kubeconform -ignore-missing-schemas -summary
