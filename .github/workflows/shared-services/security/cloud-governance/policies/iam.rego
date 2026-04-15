package governance

import future.keywords.in
import future.keywords.contains
import future.keywords.if

overly_permissive_roles := {
    "roles/owner",
    "roles/editor",
    "roles/iam.securityAdmin",
    "roles/resourcemanager.projectIamAdmin",
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_project_iam_member"
    resource.change.actions[_] in ["create", "update"]
    resource.change.after.role in overly_permissive_roles
    msg := sprintf(
        "IAM binding '%s' grants overly permissive role '%s' to '%s' — use least-privilege roles",
        [resource.address, resource.change.after.role, resource.change.after.member]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_project_iam_binding"
    resource.change.actions[_] in ["create", "update"]
    resource.change.after.role in overly_permissive_roles
    msg := sprintf(
        "IAM binding '%s' grants overly permissive role '%s' — use least-privilege roles",
        [resource.address, resource.change.after.role]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in ["google_project_iam_member", "google_project_iam_binding"]
    resource.change.actions[_] in ["create", "update"]
    member := resource.change.after.member
    startswith(member, "allUsers")
    msg := sprintf(
        "IAM binding '%s' grants access to allUsers — this makes resources public",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type in ["google_project_iam_member", "google_project_iam_binding"]
    resource.change.actions[_] in ["create", "update"]
    member := resource.change.after.member
    startswith(member, "allAuthenticatedUsers")
    msg := sprintf(
        "IAM binding '%s' grants access to allAuthenticatedUsers — overly broad",
        [resource.address]
    )
}
