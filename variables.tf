variable "application_name" {
  description = "Application name"
}
variable "client_name" {
  description = "Client name based on its site domain (e.g. example-com)"
}
variable "subdomain" {
  description = "Subdomain for the API"
  default     = "some"
}
variable "domain" {
  description = "The domain name (only 1 level, without subdomain)"
  default     = "example.com"
}
variable "swagger_template" {
  description = "Body like $${data.template_file.swagger.rendered}"
  default     = ""
}
variable "description" {
  description = "API description"
}
variable "stage" {
  description = "Stage name"
  default     = "v1"
}
variable "use_custom_domain" {
  default = false
}
variable "cache_cluster_enabled" {
  default = false
}
variable "cache_cluster_size" {
  default = 0.5
}
variable "api_env" {
  type    = "map"
  default = {}
}
