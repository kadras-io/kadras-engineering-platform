K8S_VERSION=v1.33

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
	kubectl config set-context --current --namespace=tests
	cd package && kctrl dev -f package-resources.yml --local -y

# Install e2e with 'standalone' profile
e2e-standalone: package
	kubectl config set-context --current --namespace=tests
	cd package && ytt -f ../test/e2e/standalone -f package-resources.yml | kctrl dev -f- --local -y

# Install e2e with 'build' profile
e2e-build: package
	kubectl config set-context --current --namespace=tests
	cd package && ytt -f ../test/e2e/build -f package-resources.yml | kctrl dev -f- --local -y

# Install e2e with 'run' profile
e2e-run: package
	kubectl config set-context --current --namespace=tests
	cd package && ytt -f ../test/e2e/run -f package-resources.yml | kctrl dev -f- --local -y

# Clean development environment
clean:
	cd package && kctrl dev -f package-resources.yml --local -y --delete 

# Process the configuration manifests with ytt
ytt:
	ytt -f package/config --data-values-file test/unit/config/values.yml

# Use ytt to generate an OpenAPI specification
schema:
	ytt -f package/config/values-schema.yml --data-values-schema-inspect -o openapi-v3 > schema-openapi.yml

# Use kbld to resolve the OCI images referenced within the manifests
kbld:
	rm -f package/.imgpkg/images.yml && mkdir -p package/.imgpkg && kbld --file package/config --imgpkg-lock-output package/.imgpkg/images.yml 1>> /dev/null

# Check the ytt-annotated Kubernetes configuration and its validation
test-config:
	ytt -f package/config --data-values-file test/unit/config/values.yml | kubeconform -ignore-missing-schemas -summary

# Run package integration tests
test-integration: test/integration
	kubectl kuttl test --config test/integration/kuttl-test.yml --kind-config test/setup/kind/$(K8S_VERSION)/kind-config.yml
