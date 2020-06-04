output "instances" {
  description = "Instance name => address map."
  value       = zipmap(google_compute_instance.vm.*.name, google_compute_address.static.*.address)
}