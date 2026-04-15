package governance

import future.keywords.in
import future.keywords.contains
import future.keywords.if

required_labels := {"environment", "team", "cost-center"}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    labels := object.get(resource.change.after, "labels", {})
    missing := required_labels - {key | labels[key]}
    count(missing) > 0
    msg := sprintf(
        "Resource '%s' (%s) missing required labels: %v",
        [resource.address, resource.type, missing]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    labels := object.get(resource.change.after, "labels", {})
    labels.environment
    not labels.environment in {"dev", "staging", "production", "review"}
    msg := sprintf(
        "Resource '%s' has invalid environment label '%s' — must be one of: dev, staging, production, review",
        [resource.address, labels.environment]
    )
}
