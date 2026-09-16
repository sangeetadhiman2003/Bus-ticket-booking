class UnauthorizedBookingError < StandardError
  def initialize(message = "You are not authorized to access this booking.")
    super(message)
  end
end
