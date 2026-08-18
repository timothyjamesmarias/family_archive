# Idempotent in every environment. Production reads the admin account from
# ADMIN_EMAIL/ADMIN_PASSWORD/ADMIN_NAME; development and test fall back to a
# known local credential so a fresh checkout can sign in immediately.

email = ENV["ADMIN_EMAIL"]
password = ENV["ADMIN_PASSWORD"]
name = ENV.fetch("ADMIN_NAME", "Administrator")

if email.blank? || password.blank?
  raise "ADMIN_EMAIL and ADMIN_PASSWORD must be set in production" if Rails.env.production?

  email = "admin@example.com"
  password = "password"
  name = "Dev Admin"
end

user = User.find_or_initialize_by(email: email)
user.assign_attributes(name: name, admin: true)
user.password = password if user.new_record?
user.save!
