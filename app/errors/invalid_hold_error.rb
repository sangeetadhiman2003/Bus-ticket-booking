class InvalidHoldError < StandardError
  def initialize(message = "The hold is invalid or has expired.")
    super(message)
  end
end
