kapp deploy -a kapp-controller -y \
  -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml

kubectl create namespace kadras-system

kapp deploy -a cert-manager-issuers-package -n kadras-system -y \
  -f https://github.com/kadras-io/cert-manager-issuers/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/cert-manager-issuers/releases/latest/download/package.yml

kapp deploy -a cert-manager-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-cert-manager/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-cert-manager/releases/latest/download/package.yml

kapp deploy -a contour-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-contour/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-contour/releases/latest/download/package.yml

kapp deploy -a knative-serving-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-knative-serving/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-knative-serving/releases/latest/download/package.yml

kapp deploy -a metrics-server-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-metrics-server/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-metrics-server/releases/latest/download/package.yml

kapp deploy -a secretgen-controller-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-secretgen-controller/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-secretgen-controller/releases/latest/download/package.yml

kapp deploy -a workspace-provisioner-package -n kadras-system -y \
  -f https://github.com/kadras-io/workspace-provisioner/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/workspace-provisioner/releases/latest/download/package.yml

make prepare

ytt -f ../test/integration/serving/config -f package-resources.yml | kctrl dev -f- --local -y
