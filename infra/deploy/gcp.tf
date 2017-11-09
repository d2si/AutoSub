resource "google_storage_bucket" "main" {
    name        = "${terraform.workspace}-autosub"
    location    = "EU"
}

resource "google_storage_bucket_acl" "main" {
  bucket         = "${google_storage_bucket.main.name}"
  predefined_acl = "private"
}
