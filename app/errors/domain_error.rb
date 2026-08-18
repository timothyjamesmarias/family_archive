# Errors a service raises to describe a domain outcome. Api::BaseController
# maps them to status codes; anything else stays a logged 500.
#
# `field` names the request field at fault, when there is one, so the handler
# can emit the same `{ errors: { field: message } }` envelope the admin UI uses.
class DomainError < StandardError
  attr_reader :field

  def initialize(message, field: nil)
    super(message)
    @field = field
  end
end
