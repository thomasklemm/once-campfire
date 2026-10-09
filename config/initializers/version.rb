Rails.application.config.app_version = ENV["APP_VERSION"].presence || ENV["GIT_REVISION"].presence || "0"
Rails.application.config.git_revision = ENV["GIT_REVISION"]

# Unversioned builds get a namespace per boot rather than reuse another deployment's HTML.
Rails.application.config.x.presentation_cache_version = [
  ENV["GIT_REVISION"].presence || SecureRandom.hex(16),
  Digest::SHA256.hexdigest(Rails.application.secret_key_base)
]
