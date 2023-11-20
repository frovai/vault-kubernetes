path "prd/metadata/+" {
    capabilities = ["list"]}

path "prd/data/+" {
    capabilities = ["read"]}

path "prd/metadata/+/+" {
    capabilities = ["list"]}

path "prd/data/+/+" {
    capabilities = ["read"]}

path "prd/metadata/+/+/*" {
    capabilities = ["create","delete", "list", "patch", "read", "update"]}

path "prd/data/+/+/*" {
    capabilities = ["create","delete", "list", "patch", "read", "update"]}