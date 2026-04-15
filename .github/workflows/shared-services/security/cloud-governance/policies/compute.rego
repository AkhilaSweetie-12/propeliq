package governance

import future.keywords.in
import future.keywords.contains
import future.keywords.if

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    resource.change.actions[_] in ["create", "update"]
    instance := resource.change.after
    access_config := instance.network_interface[_].access_config
    count(access_config) > 0
    msg := sprintf(
        "Compute instance '%s' has a public IP (access_config) — use Cloud NAT or IAP instead",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    resource.change.actions[_] in ["create", "update"]
    instance := resource.change.after
    not instance.shielded_instance_config
    msg := sprintf(
        "Compute instance '%s' should enable shielded VM config",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_sql_database_instance"
    resource.change.actions[_] in ["create", "update"]
    db := resource.change.after
    auth_networks := db.settings[_].ip_configuration[_].authorized_networks
    network := auth_networks[_]
    network.value == "0.0.0.0/0"
    msg := sprintf(
        "Cloud SQL instance '%s' allows connections from 0.0.0.0/0 — restrict authorized networks",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_sql_database_instance"
    resource.change.actions[_] in ["create", "update"]
    db := resource.change.after
    ip_config := db.settings[_].ip_configuration[_]
    ip_config.ipv4_enabled == true
    not ip_config.private_network
    msg := sprintf(
        "Cloud SQL instance '%s' has public IP without private network — use private IP only",
        [resource.address]
    )
}
