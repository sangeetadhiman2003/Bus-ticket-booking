class InvalidBookingError < StandardError
  def initialize(message = "The booking is invalid.")
    super(message)
  end
end
