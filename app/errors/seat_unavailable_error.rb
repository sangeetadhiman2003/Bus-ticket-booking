class SeatUnavailableError < StandardError
  def initialize(message = "One or more selected seats are unavailable.")
    super(message)
  end
end
