echo "=== Lego"
LEGO_VERSION="v4.25.1"
LEGO_TMP_DIR=$(mktemp -d)
pushd "$LEGO_TMP_DIR"
curl -sL "https://github.com/go-acme/lego/releases/download/${LEGO_VERSION}/lego_${LEGO_VERSION}_linux_$(dpkg --print-architecture).tar.gz" | tar xvz
install lego /usr/local/bin/lego
popd
rm -rf "$LEGO_TMP_DIR"
