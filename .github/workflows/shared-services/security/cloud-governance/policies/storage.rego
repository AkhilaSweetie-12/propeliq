package governance

import future.keywords.in
import future.keywords.contains
import future.keywords.if

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket"
    resource.change.actions[_] in ["create", "update"]
    bucket := resource.change.after
    not bucket.versioning
    msg := sprintf(
        "Storage bucket '%s' does not have versioning enabled",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket"
    resource.change.actions[_] in ["create", "update"]
    bucket := resource.change.after
    bucket.versioning
    not bucket.versioning[_].enabled
    msg := sprintf(
        "Storage bucket '%s' has versioning explicitly disabled",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket"
    resource.change.actions[_] in ["create", "update"]
    bucket := resource.change.after
    not bucket.uniform_bucket_level_access
    msg := sprintf(
        "Storage bucket '%s' should enable uniform bucket-level access",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket_iam_member"
    resource.change.actions[_] in ["create", "update"]
    member := resource.change.after.member
    member in ["allUsers", "allAuthenticatedUsers"]
    msg := sprintf(
        "Bucket IAM '%s' grants public access via '%s'",
        [resource.address, member]
    )
}
