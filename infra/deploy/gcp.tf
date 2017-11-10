resource "google_storage_bucket" "main" {
  name     = "${terraform.workspace}-autosub"
  location = "EU"
}

resource "google_storage_bucket_acl" "main" {
  bucket         = "${google_storage_bucket.main.name}"
  predefined_acl = "private"
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/storage.admin"

    members = [
      "serviceAccount:${google_service_account.admin.email}",
    ]
  }
}

resource "google_service_account" "admin" {
  account_id   = "${terraform.workspace}-autosub"
  display_name = "${terraform.workspace}-autosub"
}

resource "google_project_iam_policy" "admin" {
  project     = "${var.gcloud_project_id}"
  policy_data = "${data.google_iam_policy.admin.policy_data}"
}
