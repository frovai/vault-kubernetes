path "hml/config" {
    capabilities = ["read"]}

path "hml/metadata/+" {
    capabilities = ["list"]}

path "hml/data/+" {
    capabilities = ["read"]}

path "hml/metadata/+/+" {
    capabilities = ["list"]}

path "hml/data/+/+" {
    capabilities = ["read"]}

path "hml/metadata/+/+/*" {
    capabilities = ["create","delete", "list", "patch", "read", "update"]}

path "hml/data/+/+/*" {
    capabilities = ["create","delete", "list", "patch", "read", "update"]}