package governance

import future.keywords.in
import future.keywords.contains
import future.keywords.if

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_firewall"
    resource.change.actions[_] in ["create", "update"]
    rule := resource.change.after
    "0.0.0.0/0" in rule.source_ranges
    allowed := rule.allow[_]
    port := allowed.ports[_]
    port in ["22", "3389", "0-65535"]
    msg := sprintf(
        "Firewall rule '%s' allows %s port %s from 0.0.0.0/0 — restrict source ranges",
        [resource.address, allowed.protocol, port]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_firewall"
    resource.change.actions[_] in ["create", "update"]
    rule := resource.change.after
    "0.0.0.0/0" in rule.source_ranges
    allowed := rule.allow[_]
    not allowed.ports
    msg := sprintf(
        "Firewall rule '%s' allows ALL %s ports from 0.0.0.0/0 — restrict source ranges and ports",
        [resource.address, allowed.protocol]
    )
}
